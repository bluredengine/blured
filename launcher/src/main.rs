#![windows_subsystem = "windows"]

use std::collections::HashMap;
use std::env;
use std::fs;
use std::io::{self, BufRead};
use std::path::{Path, PathBuf};
use std::process::{self, Child, Command, Stdio};
use std::time::Duration;
use std::thread;
#[cfg(windows)]
use std::os::windows::process::CommandExt;

mod updater;

fn main() {
    let launcher_dir = get_launcher_dir();
    let args: Vec<String> = env::args().collect();

    // Handle CLI flags (no GUI needed)
    if args.iter().any(|a| a == "--update-check") {
        match updater::check_for_update(&launcher_dir) {
            Some(info) => {
                println!("Update available: {} -> {}", info.current, info.latest);
                process::exit(0);
            }
            None => {
                println!("No update available.");
                process::exit(1);
            }
        }
    }

    if args.iter().any(|a| a == "--update") {
        match updater::check_for_update(&launcher_dir) {
            Some(info) => {
                println!("Updating RedBlue Engine {} -> {}...", info.current, info.latest);
                match updater::apply_update(&launcher_dir, &info) {
                    Ok(()) => {
                        println!("Update complete! Restart the launcher to use the new version.");
                        process::exit(0);
                    }
                    Err(e) => {
                        eprintln!("Update failed: {}", e);
                        process::exit(1);
                    }
                }
            }
            None => {
                println!("Already up to date.");
                process::exit(0);
            }
        }
    }

    // Load env files and launch directly
    let env_vars = load_env_files(&launcher_dir);
    let pass_args = args[1..].to_vec();
    launch_engine(launcher_dir, env_vars, pass_args);
}

/// Launch the engine (AI server + Godot editor)
fn launch_engine(launcher_dir: PathBuf, env_vars: HashMap<String, String>, args: Vec<String>) {
    // Set env vars
    for (key, value) in &env_vars {
        env::set_var(key, value);
    }

    let ai_port = env_vars
        .get("MAKABAKA_AI_PORT")
        .and_then(|v| v.parse::<u16>().ok())
        .unwrap_or(4096);

    let project_path = env_vars.get("MAKABAKA_PROJECT_PATH").cloned();

    // Check for updates in background
    let launcher_dir_clone = launcher_dir.clone();
    let _update_handle = thread::spawn(move || {
        updater::check_for_update(&launcher_dir_clone)
    });

    // Start OpenCode AI server
    let opencode_exe = find_executable(&launcher_dir, "opencode");
    let mut ai_server: Option<Child> = None;

    // Log file for OpenCode output (for debugging startup issues)
    let log_path = launcher_dir.join("opencode.log");
    let log_file = fs::File::create(&log_path).ok();

    if let Some(exe) = &opencode_exe {
        if !is_port_open(ai_port) {
            let mut cmd = Command::new(exe);
            cmd.arg("serve")
                .arg("--port")
                .arg(ai_port.to_string())
                .envs(&env_vars);

            // Redirect output to log file for debugging
            if let Some(ref f) = log_file {
                cmd.stdout(f.try_clone().unwrap_or_else(|_| fs::File::open("NUL").unwrap()));
                cmd.stderr(f.try_clone().unwrap_or_else(|_| fs::File::open("NUL").unwrap()));
            }

            #[cfg(windows)]
            cmd.creation_flags(0x08000000); // CREATE_NO_WINDOW
            match cmd.spawn()
            {
                Ok(child) => {
                    ai_server = Some(child);
                    wait_for_server(ai_port, Duration::from_secs(30));
                }
                Err(_) => {}
            }
        }
    }

    // Launch Godot editor
    let godot_exe = find_executable(&launcher_dir, "redblue")
        .or_else(|| find_executable(&launcher_dir, "makabaka"));

    if let Some(exe) = &godot_exe {
        let mut cmd = Command::new(exe);
        cmd.envs(&env_vars);

        let open_project_manager = args.iter().any(|a| a == "-new" || a == "--project-manager");

        if open_project_manager {
            cmd.arg("--project-manager");
        } else if let Some(ref project) = project_path {
            cmd.arg("--path").arg(project).arg("--editor");
        } else {
            cmd.arg("--project-manager");
        }

        let _ = cmd.status();
    }

    // Let the AI server continue running independently.
    // It will be reused if the editor is relaunched, and cleaned up on next launch
    // if the port is already occupied.
    drop(ai_server);
}

/// Get the directory where the launcher exe lives
fn get_launcher_dir() -> PathBuf {
    env::current_exe()
        .expect("Failed to get launcher path")
        .parent()
        .expect("Failed to get launcher directory")
        .to_path_buf()
}

/// Load .env file, returning key-value pairs.
fn load_env_files(base_dir: &Path) -> HashMap<String, String> {
    let mut vars = HashMap::new();
    let search_dirs: Vec<PathBuf> = vec![
        base_dir.to_path_buf(),
        base_dir.join("..").to_path_buf(),
    ];

    for dir in &search_dirs {
        for filename in &[".env"] {
            let filepath = dir.join(filename);
            if let Ok(file) = fs::File::open(&filepath) {
                let reader = io::BufReader::new(file);
                for line in reader.lines().map_while(Result::ok) {
                    let trimmed = line.trim();
                    if trimmed.is_empty() || trimmed.starts_with('#') {
                        continue;
                    }
                    if let Some(eq_pos) = trimmed.find('=') {
                        let key = trimmed[..eq_pos].trim().to_string();
                        let value = trimmed[eq_pos + 1..].trim().to_string();
                        if !key.is_empty() {
                            vars.entry(key).or_insert(value);
                        }
                    }
                }
            }
        }
    }

    vars
}

/// Find an executable in bin/ subdirectory or same directory
fn find_executable(base_dir: &Path, name: &str) -> Option<PathBuf> {
    let exe_name = format!("{}.exe", name);
    let candidates = [
        base_dir.join("bin").join(&exe_name),
        base_dir.join(&exe_name),
        base_dir.join("..").join("bin").join(&exe_name),
    ];

    for path in &candidates {
        if path.exists() {
            return Some(path.to_path_buf());
        }
    }

    // Fallback: try Godot's default name
    if name == "makabaka" || name == "redblue" {
        let godot_name = "godot.windows.editor.x86_64.exe";
        let fallbacks = [
            base_dir.join("bin").join(godot_name),
            base_dir.join(godot_name),
            base_dir.join("..").join("bin").join(godot_name),
        ];
        for path in &fallbacks {
            if path.exists() {
                return Some(path.to_path_buf());
            }
        }
    }

    None
}

/// Check if a TCP port is open
fn is_port_open(port: u16) -> bool {
    std::net::TcpStream::connect_timeout(
        &format!("127.0.0.1:{}", port).parse().unwrap(),
        Duration::from_millis(500),
    )
    .is_ok()
}

/// Wait for the AI server to become available
fn wait_for_server(port: u16, timeout: Duration) {
    let start = std::time::Instant::now();
    while start.elapsed() < timeout {
        if is_port_open(port) {
            return;
        }
        thread::sleep(Duration::from_millis(500));
    }
}
