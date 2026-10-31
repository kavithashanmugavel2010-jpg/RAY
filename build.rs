use std::env;
use std::fs;
use std::path::Path;

fn main() {
    println!("cargo:rerun-if-changed=target/release/ray.exe");
    println!("cargo:rerun-if-changed=target/release/ray-uninstaller.exe");

    let out_dir = env::var("OUT_DIR").unwrap();
    let dest_ray = Path::new(&out_dir).join("embedded_ray.bin");
    let dest_upm = Path::new(&out_dir).join("embedded_upm.bin");
    let dest_uninstaller = Path::new(&out_dir).join("embedded_uninstaller.bin");

    // Embed ray if it exists
    let candidates_ray = [
        "target/release/ray.exe",
        "ray.exe",
        "target/release/ray",
        "ray",
        "target/release/upm.exe",
        "upm.exe",
        "target/release/upm",
        "upm",
    ];
    let mut found_ray = false;
    for cand in &candidates_ray {
        if let Ok(bytes) = fs::read(cand) {
            fs::write(&dest_ray, &bytes).unwrap();
            fs::write(&dest_upm, &bytes).unwrap();
            found_ray = true;
            break;
        }
    }
    if !found_ray {
        fs::write(&dest_ray, b"").unwrap();
        fs::write(&dest_upm, b"").unwrap();
    }

    // Embed ray-uninstaller if it exists
    let candidates_uninst = [
        "target/release/ray-uninstaller.exe",
        "ray-uninstaller.exe",
        "target/release/ray-uninstaller",
        "ray-uninstaller",
        "target/release/upm-uninstaller.exe",
        "upm-uninstaller.exe",
        "target/release/upm-uninstaller",
        "upm-uninstaller",
    ];
    let mut found_uninst = false;
    for cand in &candidates_uninst {
        if let Ok(bytes) = fs::read(cand) {
            fs::write(&dest_uninstaller, bytes).unwrap();
            found_uninst = true;
            break;
        }
    }
    if !found_uninst {
        fs::write(&dest_uninstaller, b"").unwrap();
    }
}

