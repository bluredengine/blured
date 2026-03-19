use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use serde::Deserialize;

/// GitHub repo for update checks (owner/repo)
const GITHUB_REPO: &str = "bluredengine/blured";

/// Asset name pattern in GitHub releases (the zip containing the full engine)
const ASSET_NAME_PATTERN: &str = "blured-engine-windows";

/// Local version file name
const VERSION_FILE: &str = "VERSION";

#[derive(Debug)]
pub struct UpdateInfo {
    pub current: String,
    pub latest: String,
    pub download_url: String,
    pub asset_name: String,
}

#[derive(Deserialize, Debug)]
struct GitHubRelease {
    tag_name: String,
    assets: Vec<GitHubAsset>,
}

#[derive(Deserialize, Debug)]
struct GitHubAsset {
    name: String,
    browser_download_url: String,
}

/// Read the current installed version from VERSION file
fn read_current_version(base_dir: &Path) -> String {
    // Check launcher dir, then parent
    for dir in &[base_dir.to_path_buf(), base_dir.join("..")] {
        let version_path = dir.join(VERSION_FILE);
        if let Ok(content) = fs::read_to_string(&version_path) {
            let v = content.trim().to_string();
            if !v.is_empty() {
                return v;
            }
        }
    }
    "0.0.0".to_string()
}

/// Check GitHub releases for a newer version
pub fn check_for_update(base_dir: &Path) -> Option<UpdateInfo> {
    let current = read_current_version(base_dir);
    let url = format!(
        "https://api.github.com/repos/{}/releases/latest",
        GITHUB_REPO
    );

    let client = reqwest::blocking::Client::builder()
        .user_agent("blured-launcher")
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .ok()?;

    let response = client.get(&url).send().ok()?;
    if !response.status().is_success() {
        return None;
    }

    let release: GitHubRelease = response.json().ok()?;
    let latest = release.tag_name.trim_start_matches('v').to_string();

    // Compare versions
    let current_ver = semver::Version::parse(&normalize_version(&current)).ok()?;
    let latest_ver = semver::Version::parse(&normalize_version(&latest)).ok()?;

    if latest_ver <= current_ver {
        return None;
    }

    // Find the Windows asset
    let asset = release.assets.iter().find(|a| {
        a.name.to_lowercase().contains(ASSET_NAME_PATTERN)
            && a.name.to_lowercase().ends_with(".zip")
    })?;

    Some(UpdateInfo {
        current,
        latest,
        download_url: asset.browser_download_url.clone(),
        asset_name: asset.name.clone(),
    })
}

/// Download and apply an update
pub fn apply_update(base_dir: &Path, info: &UpdateInfo) -> Result<(), Box<dyn std::error::Error>> {
    let temp_dir = base_dir.join(".update-temp");
    let zip_path = temp_dir.join(&info.asset_name);

    // Clean up any previous failed update
    if temp_dir.exists() {
        fs::remove_dir_all(&temp_dir)?;
    }
    fs::create_dir_all(&temp_dir)?;

    // Download the release zip
    println!("[Update] Downloading {}...", info.asset_name);
    download_file(&info.download_url, &zip_path)?;

    // Extract the zip
    println!("[Update] Extracting...");
    extract_zip(&zip_path, &temp_dir)?;

    // Find the extracted content directory (may be nested)
    let extract_root = find_extract_root(&temp_dir)?;

    // Apply the update: copy files over existing installation
    println!("[Update] Applying update...");
    let install_dir = find_install_root(base_dir);
    copy_dir_recursive(&extract_root, &install_dir)?;

    // Write new version
    let version_path = install_dir.join(VERSION_FILE);
    fs::write(&version_path, &info.latest)?;

    // Cleanup temp
    println!("[Update] Cleaning up...");
    let _ = fs::remove_dir_all(&temp_dir);

    println!("[Update] Updated to version {}", info.latest);
    Ok(())
}

/// Download a file with progress indication
fn download_file(url: &str, dest: &Path) -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::blocking::Client::builder()
        .user_agent("blured-launcher")
        .timeout(std::time::Duration::from_secs(600))
        .build()?;

    let mut response = client.get(url).send()?;
    if !response.status().is_success() {
        return Err(format!("Download failed: HTTP {}", response.status()).into());
    }

    let total_size = response.content_length().unwrap_or(0);
    let mut file = fs::File::create(dest)?;
    let mut downloaded: u64 = 0;
    let mut buffer = [0u8; 8192];

    loop {
        let bytes_read = io::Read::read(&mut response, &mut buffer)?;
        if bytes_read == 0 {
            break;
        }
        file.write_all(&buffer[..bytes_read])?;
        downloaded += bytes_read as u64;

        if total_size > 0 {
            let pct = (downloaded as f64 / total_size as f64 * 100.0) as u32;
            print!("\r[Update] Downloaded {}/{} MB ({}%)",
                downloaded / 1_048_576,
                total_size / 1_048_576,
                pct
            );
            let _ = io::stdout().flush();
        }
    }
    println!();

    Ok(())
}

/// Extract a zip file to a directory
fn extract_zip(zip_path: &Path, dest: &Path) -> Result<(), Box<dyn std::error::Error>> {
    let file = fs::File::open(zip_path)?;
    let mut archive = zip::ZipArchive::new(file)?;

    for i in 0..archive.len() {
        let mut entry = archive.by_index(i)?;
        let name = entry.name().to_string();

        let outpath = dest.join(&name);

        if entry.is_dir() {
            fs::create_dir_all(&outpath)?;
        } else {
            if let Some(parent) = outpath.parent() {
                fs::create_dir_all(parent)?;
            }
            let mut outfile = fs::File::create(&outpath)?;
            io::copy(&mut entry, &mut outfile)?;
        }
    }

    Ok(())
}

/// Find the root directory inside the extracted zip
/// (handles cases like zip containing a single top-level folder)
fn find_extract_root(temp_dir: &Path) -> Result<PathBuf, Box<dyn std::error::Error>> {
    let entries: Vec<_> = fs::read_dir(temp_dir)?
        .filter_map(Result::ok)
        .filter(|e| {
            // Skip the zip file itself and hidden files
            let name = e.file_name().to_string_lossy().to_string();
            !name.ends_with(".zip") && !name.starts_with('.')
        })
        .collect();

    // If there's exactly one directory, use it as root
    if entries.len() == 1 && entries[0].file_type().map(|t| t.is_dir()).unwrap_or(false) {
        return Ok(entries[0].path());
    }

    // Otherwise, the temp dir itself is the root
    Ok(temp_dir.to_path_buf())
}

/// Find the installation root (parent of bin/ directory)
fn find_install_root(base_dir: &Path) -> PathBuf {
    // If base_dir contains bin/, it's the install root
    if base_dir.join("bin").exists() {
        return base_dir.to_path_buf();
    }
    // If base_dir IS bin/, go up one level
    if base_dir.file_name().map(|n| n == "bin").unwrap_or(false) {
        if let Some(parent) = base_dir.parent() {
            return parent.to_path_buf();
        }
    }
    // Default: parent of launcher dir
    base_dir.parent().unwrap_or(base_dir).to_path_buf()
}

/// Recursively copy directory contents, overwriting existing files.
/// Skips .env to preserve user configuration.
fn copy_dir_recursive(src: &Path, dst: &Path) -> Result<(), Box<dyn std::error::Error>> {
    if !dst.exists() {
        fs::create_dir_all(dst)?;
    }

    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let src_path = entry.path();
        let file_name = entry.file_name().to_string_lossy().to_string();

        // Preserve user configuration files
        if file_name == ".env" {
            continue;
        }

        let dst_path = dst.join(&file_name);

        if src_path.is_dir() {
            copy_dir_recursive(&src_path, &dst_path)?;
        } else {
            // For executables that might be in use, try rename-then-copy
            if dst_path.exists() && file_name.ends_with(".exe") {
                let backup = dst_path.with_extension("exe.old");
                let _ = fs::remove_file(&backup);
                if fs::rename(&dst_path, &backup).is_err() {
                    // File might be in use, skip it
                    eprintln!("[Update] Skipping {} (in use)", file_name);
                    continue;
                }
            }
            fs::copy(&src_path, &dst_path)?;
        }
    }

    Ok(())
}

/// Normalize version string to valid semver (e.g., "1.0" -> "1.0.0")
fn normalize_version(v: &str) -> String {
    let parts: Vec<&str> = v.split('.').collect();
    match parts.len() {
        1 => format!("{}.0.0", parts[0]),
        2 => format!("{}.{}.0", parts[0], parts[1]),
        _ => v.to_string(),
    }
}
