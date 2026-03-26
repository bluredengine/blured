fn main() {
    if std::env::var("CARGO_CFG_TARGET_OS").unwrap_or_default() == "windows" {
        let mut res = winresource::WindowsResource::new();
        res.set_icon("resources/icon.ico");
        res.set("ProductName", "Blured Engine");
        res.set("FileDescription", "Blured Engine Launcher");
        res.compile().expect("Failed to compile Windows resources");
    }
}
