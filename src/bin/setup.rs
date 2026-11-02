#[path = "../terminal.rs"]
mod terminal;
#[path = "../installer.rs"]
mod installer;

#[cfg(windows)]
use std::ffi::OsStr;
#[cfg(windows)]
use std::os::windows::ffi::OsStrExt;
#[cfg(windows)]
use std::path::PathBuf;
#[cfg(windows)]
use std::sync::atomic::{AtomicBool, Ordering};

#[cfg(windows)]
use windows_sys::Win32::Foundation::{HWND, LPARAM, LRESULT, WPARAM};
#[cfg(windows)]
use windows_sys::Win32::Graphics::Gdi::{
    CreateFontW, HBRUSH, HFONT, COLOR_WINDOW, FW_BOLD, FW_NORMAL,
};
#[cfg(windows)]
use windows_sys::Win32::System::LibraryLoader::GetModuleHandleW;
#[cfg(windows)]
use windows_sys::Win32::UI::WindowsAndMessaging::{
    CreateWindowExW, DefWindowProcW, DestroyWindow, DispatchMessageW, GetMessageW,
    GetSystemMetrics, MessageBoxW, PostQuitMessage, RegisterClassW, SendMessageW,
    SetWindowTextW, ShowWindow, TranslateMessage, BM_GETCHECK, BM_SETCHECK,
    BS_AUTOCHECKBOX, BS_DEFPUSHBUTTON, BS_PUSHBUTTON,
    CS_HREDRAW, CS_VREDRAW, IDYES, MB_ICONERROR, MB_ICONINFORMATION, MB_ICONQUESTION, MB_OK, MB_YESNO,
    MSG, SM_CXSCREEN, SM_CYSCREEN, SW_SHOW, WM_COMMAND, WM_CREATE, WM_DESTROY, WM_SETFONT, WNDCLASSW,
    WS_CHILD, WS_MINIMIZEBOX, WS_OVERLAPPED, WS_SYSMENU, WS_VISIBLE,
};

#[allow(unused_imports)]
use installer::Installer;

#[cfg(windows)]
const WS_CAPTION: u32 = 0x00C00000;
#[cfg(windows)]
const BST_CHECKED: usize = 1;

#[cfg(windows)]
const EMBEDDED_RAY: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/embedded_ray.bin"));
#[cfg(windows)]
const EMBEDDED_UNINSTALLER: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/embedded_uninstaller.bin"));

#[cfg(windows)]
const IDC_INSTALL_BTN: usize = 1001;
#[cfg(windows)]
const IDC_CANCEL_BTN: usize = 1002;
#[cfg(windows)]
const IDC_PATH_CHECKBOX: usize = 1003;
#[cfg(windows)]
const IDC_UNINSTALLER_CHECKBOX: usize = 1004;
#[cfg(windows)]
const IDC_DOWNLOADER_CHECKBOX: usize = 1005;
#[cfg(windows)]
const IDC_UNINSTALL_BTN: usize = 1007;

#[cfg(windows)]
static PATH_CHECKBOX_HWND: std::sync::atomic::AtomicIsize = std::sync::atomic::AtomicIsize::new(0);
#[cfg(windows)]
static UNINSTALLER_CHECKBOX_HWND: std::sync::atomic::AtomicIsize = std::sync::atomic::AtomicIsize::new(0);
#[cfg(windows)]
static DOWNLOADER_CHECKBOX_HWND: std::sync::atomic::AtomicIsize = std::sync::atomic::AtomicIsize::new(0);
#[cfg(windows)]
static STATUS_LABEL_HWND: std::sync::atomic::AtomicIsize = std::sync::atomic::AtomicIsize::new(0);
#[cfg(windows)]
static IS_WORKING: AtomicBool = AtomicBool::new(false);

#[cfg(windows)]
fn to_wide(s: &str) -> Vec<u16> {
    OsStr::new(s).encode_wide().chain(std::iter::once(0)).collect()
}

#[cfg(windows)]
fn create_segoe_font(size: i32, bold: bool) -> HFONT {
    unsafe {
        let font_name = to_wide("Segoe UI");
        CreateFontW(
            size,
            0,
            0,
            0,
            if bold { FW_BOLD as i32 } else { FW_NORMAL as i32 },
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            font_name.as_ptr(),
        )
    }
}

/// Synchronously downloads bytes from a given URL using tokio + reqwest.
#[cfg(windows)]
fn download_bytes_sync(url: &str) -> Result<Vec<u8>, String> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .map_err(|e| format!("Failed to create async runtime: {}", e))?;

    rt.block_on(async {
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(30))
            .build()
            .map_err(|e| format!("HTTP client initialization failed: {}", e))?;

        let res = client.get(url).send().await
            .map_err(|e| format!("Download request failed: {}", e))?;

        if !res.status().is_success() {
            return Err(format!("Download returned HTTP status {}", res.status()));
        }

        let bytes = res.bytes().await
            .map_err(|e| format!("Failed reading response bytes: {}", e))?;

        Ok(bytes.to_vec())
    })
}

#[cfg(windows)]
fn set_status_text(hwnd: HWND, text: &str) {
    unsafe {
        let w = to_wide(text);
        SetWindowTextW(hwnd, w.as_ptr());
    }
}

/// Core installation logic supporting embedded binaries and the GUI downloader method.
#[cfg(windows)]
fn perform_setup_install(
    should_add_to_path: bool,
    install_uninstaller: bool,
    force_download: bool,
    status_hwnd: Option<HWND>,
) -> Result<PathBuf, String> {
    let install_dir = Installer::default_install_dir();
    let dest_exe = install_dir.join("ray.exe");
    let dest_uninstaller = install_dir.join("ray-uninstaller.exe");

    std::fs::create_dir_all(&install_dir)
        .map_err(|e| format!("Failed to create folder {}: {}", install_dir.display(), e))?;

    // 1. Install ray.exe
    let mut ray_installed = false;

    if force_download {
        if let Some(h) = status_hwnd {
            set_status_text(h, "Downloading ray.exe from GitHub (Downloader Method)...");
        }
        let url = "https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/ray.exe";
        if let Ok(bytes) = download_bytes_sync(url) {
            if bytes.len() > 100_000 && std::fs::write(&dest_exe, &bytes).is_ok() {
                ray_installed = true;
            }
        }
    }

    if !ray_installed && !EMBEDDED_RAY.is_empty() {
        if let Some(h) = status_hwnd {
            set_status_text(h, "Extracting embedded ray.exe (Offline Instant)...");
        }
        std::fs::write(&dest_exe, EMBEDDED_RAY)
            .map_err(|e| format!("Failed to write ray.exe: {}", e))?;
        ray_installed = true;
    }

    if !ray_installed {
        if let Some(h) = status_hwnd {
            set_status_text(h, "Downloading ray.exe from GitHub repository...");
        }
        let url = "https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/ray.exe";
        match download_bytes_sync(url) {
            Ok(bytes) => {
                std::fs::write(&dest_exe, &bytes)
                    .map_err(|e| format!("Failed to write downloaded ray.exe: {}", e))?;
            }
            Err(dl_err) => {
                // Secondary check: is there a local ray.exe next to ray-setup.exe?
                if let Ok(src) = Installer::locate_binary(None) {
                    if src.canonicalize().ok() != dest_exe.canonicalize().ok() {
                        std::fs::copy(&src, &dest_exe)
                            .map_err(|e| format!("Failed to copy ray.exe: {}", e))?;
                        ray_installed = true;
                    }
                }
                if !ray_installed {
                    return Err(format!("Could not acquire ray.exe (Download error: {})", dl_err));
                }
            }
        }
    }

    // Also place upm.exe alias in bin directory for backward compatibility
    let _ = std::fs::copy(&dest_exe, install_dir.join("upm.exe"));

    // 2. Install ray-uninstaller.exe if requested
    if install_uninstaller {
        if let Some(h) = status_hwnd {
            set_status_text(h, "Installing ray-uninstaller.exe...");
        }

        let mut uninst_installed = false;
        if force_download {
            let u_url = "https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/ray-uninstaller.exe";
            if let Ok(bytes) = download_bytes_sync(u_url) {
                if bytes.len() > 50_000 && std::fs::write(&dest_uninstaller, &bytes).is_ok() {
                    uninst_installed = true;
                }
            }
        }

        if !uninst_installed && !EMBEDDED_UNINSTALLER.is_empty() {
            let _ = std::fs::write(&dest_uninstaller, EMBEDDED_UNINSTALLER);
            uninst_installed = true;
        }

        if !uninst_installed {
            let u_url = "https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/ray-uninstaller.exe";
            if let Ok(bytes) = download_bytes_sync(u_url) {
                let _ = std::fs::write(&dest_uninstaller, &bytes);
            }
        }

        // Copy current setup.exe into install dir so user has offline setup/uninstaller
        if let Ok(curr) = std::env::current_exe() {
            let dest_setup_copy = install_dir.join("ray-setup.exe");
            if curr.canonicalize().ok() != dest_setup_copy.canonicalize().ok() {
                let _ = std::fs::copy(&curr, dest_setup_copy);
            }
        }

        // Register in Windows Installed Apps (Settings / Control Panel)
        if let Some(h) = status_hwnd {
            set_status_text(h, "Registering in Windows Settings (Installed Apps)...");
        }
        let _ = Installer::register_windows_uninstall(&install_dir, &dest_exe);
    }

    // 3. Configure PATH
    if should_add_to_path {
        if let Some(h) = status_hwnd {
            set_status_text(h, "Configuring User PATH environment variable...");
        }
        let _ = Installer::add_dir_to_path(&install_dir);
    }

    if let Some(h) = status_hwnd {
        set_status_text(h, "✓ Installation Completed Successfully!");
    }

    Ok(dest_exe)
}

#[cfg(windows)]
unsafe extern "system" fn window_proc(
    hwnd: HWND,
    msg: u32,
    wparam: WPARAM,
    lparam: LPARAM,
) -> LRESULT {
    match msg {
        WM_CREATE => {
            let hinstance = GetModuleHandleW(std::ptr::null());
            let font_title = create_segoe_font(22, true);
            let font_author = create_segoe_font(15, true);
            let font_normal = create_segoe_font(14, false);
            let font_small = create_segoe_font(13, false);

            let make_label = |text: &str, x: i32, y: i32, w: i32, h: i32, font: HFONT| -> HWND {
                let static_class = to_wide("STATIC");
                let label_text = to_wide(text);
                let h_lbl = CreateWindowExW(
                    0,
                    static_class.as_ptr(),
                    label_text.as_ptr(),
                    WS_CHILD | WS_VISIBLE,
                    x,
                    y,
                    w,
                    h,
                    hwnd,
                    std::ptr::null_mut(),
                    hinstance,
                    std::ptr::null(),
                );
                SendMessageW(h_lbl, WM_SETFONT, font as WPARAM, 1);
                h_lbl
            };

            // Title Header
            make_label("Install RAY 0.1.0 (64-bit)", 30, 18, 500, 30, font_title);

            // Author credit & subhead
            make_label("Universal Package Manager  •  Engineered & Built by Sarvesh.S", 30, 50, 500, 22, font_author);
            make_label("Ultra-high-performance cross-ecosystem package installer for Windows", 30, 74, 500, 20, font_small);

            // Feature Highlights
            make_label("✓ Zero-Copy Linker (Win32 Hardlinks & ReFS Dev Drive Block Cloning)", 40, 108, 480, 20, font_normal);
            make_label("✓ SIMD In-Memory Decompression (libdeflater hardware acceleration)", 40, 130, 480, 20, font_normal);
            make_label("✓ Content-Addressable Storage (CAS) with BLAKE3 cryptographic integrity", 40, 152, 480, 20, font_normal);
            make_label("✓ Native support: Python (PyPI), JavaScript (npm), Standalone Binaries", 40, 174, 480, 20, font_normal);

            // Install Directory Notice
            let default_dir = Installer::default_install_dir();
            let dir_notice = format!("Destination: {}", default_dir.display());
            make_label(&dir_notice, 40, 206, 480, 20, font_small);

            let button_class = to_wide("BUTTON");

            // Option 1: Add to PATH Checkbox (Checked by default)
            let chk_path_text = to_wide("Add RAY to User PATH (recommended for Command Prompt & PowerShell)");
            let h_chk_path = CreateWindowExW(
                0,
                button_class.as_ptr(),
                chk_path_text.as_ptr(),
                WS_CHILD | WS_VISIBLE | (BS_AUTOCHECKBOX as u32),
                38,
                236,
                480,
                24,
                hwnd,
                IDC_PATH_CHECKBOX as *mut _,
                hinstance,
                std::ptr::null(),
            );
            SendMessageW(h_chk_path, WM_SETFONT, font_normal as WPARAM, 1);
            SendMessageW(h_chk_path, BM_SETCHECK, BST_CHECKED as WPARAM, 0);
            PATH_CHECKBOX_HWND.store(h_chk_path as isize, Ordering::SeqCst);

            // Option 2: Install Uninstaller & Register in Settings (Checked by default)
            let chk_uninst_text = to_wide("Install RAY Uninstaller & Register in Windows Settings (Apps)");
            let h_chk_uninst = CreateWindowExW(
                0,
                button_class.as_ptr(),
                chk_uninst_text.as_ptr(),
                WS_CHILD | WS_VISIBLE | (BS_AUTOCHECKBOX as u32),
                38,
                264,
                480,
                24,
                hwnd,
                IDC_UNINSTALLER_CHECKBOX as *mut _,
                hinstance,
                std::ptr::null(),
            );
            SendMessageW(h_chk_uninst, WM_SETFONT, font_normal as WPARAM, 1);
            SendMessageW(h_chk_uninst, BM_SETCHECK, BST_CHECKED as WPARAM, 0);
            UNINSTALLER_CHECKBOX_HWND.store(h_chk_uninst as isize, Ordering::SeqCst);

            // Option 3: GUI Downloader Method Checkbox
            let chk_dl_text = to_wide("GUI Downloader Method (Always fetch latest binaries online from GitHub)");
            let h_chk_dl = CreateWindowExW(
                0,
                button_class.as_ptr(),
                chk_dl_text.as_ptr(),
                WS_CHILD | WS_VISIBLE | (BS_AUTOCHECKBOX as u32),
                38,
                292,
                480,
                24,
                hwnd,
                IDC_DOWNLOADER_CHECKBOX as *mut _,
                hinstance,
                std::ptr::null(),
            );
            SendMessageW(h_chk_dl, WM_SETFONT, font_normal as WPARAM, 1);
            let dl_default = if EMBEDDED_RAY.is_empty() { BST_CHECKED } else { 0 };
            SendMessageW(h_chk_dl, BM_SETCHECK, dl_default as WPARAM, 0);
            DOWNLOADER_CHECKBOX_HWND.store(h_chk_dl as isize, Ordering::SeqCst);

            // Status label
            let h_status = make_label("Ready to install. Click 'Install Now' to begin.", 40, 326, 480, 20, font_author);
            STATUS_LABEL_HWND.store(h_status as isize, Ordering::SeqCst);

            // Install Now Button (Default button)
            let btn_text = to_wide("Install Now");
            let h_install = CreateWindowExW(
                0,
                button_class.as_ptr(),
                btn_text.as_ptr(),
                WS_CHILD | WS_VISIBLE | (BS_DEFPUSHBUTTON as u32),
                160,
                362,
                125,
                36,
                hwnd,
                IDC_INSTALL_BTN as *mut _,
                hinstance,
                std::ptr::null(),
            );
            SendMessageW(h_install, WM_SETFONT, font_author as WPARAM, 1);

            // Uninstall Button (Dedicated GUI Uninstaller option!)
            let uninst_btn_text = to_wide("Uninstall RAY");
            let h_uninstall = CreateWindowExW(
                0,
                button_class.as_ptr(),
                uninst_btn_text.as_ptr(),
                WS_CHILD | WS_VISIBLE | (BS_PUSHBUTTON as u32),
                295,
                362,
                125,
                36,
                hwnd,
                IDC_UNINSTALL_BTN as *mut _,
                hinstance,
                std::ptr::null(),
            );
            SendMessageW(h_uninstall, WM_SETFONT, font_normal as WPARAM, 1);

            // Cancel Button
            let cancel_text = to_wide("Cancel");
            let h_cancel = CreateWindowExW(
                0,
                button_class.as_ptr(),
                cancel_text.as_ptr(),
                WS_CHILD | WS_VISIBLE | (BS_PUSHBUTTON as u32),
                430,
                362,
                95,
                36,
                hwnd,
                IDC_CANCEL_BTN as *mut _,
                hinstance,
                std::ptr::null(),
            );
            SendMessageW(h_cancel, WM_SETFONT, font_normal as WPARAM, 1);

            0
        }
        WM_COMMAND => {
            let ctrl_id = (wparam & 0xFFFF) as usize;
            if ctrl_id == IDC_INSTALL_BTN {
                if !IS_WORKING.swap(true, Ordering::SeqCst) {
                    perform_gui_install_action(hwnd);
                }
            } else if ctrl_id == IDC_UNINSTALL_BTN {
                if !IS_WORKING.swap(true, Ordering::SeqCst) {
                    perform_gui_uninstall_action(hwnd);
                }
            } else if ctrl_id == IDC_CANCEL_BTN {
                DestroyWindow(hwnd);
            }
            0
        }
        WM_DESTROY => {
            PostQuitMessage(0);
            0
        }
        _ => DefWindowProcW(hwnd, msg, wparam, lparam),
    }
}

#[cfg(windows)]
fn perform_gui_install_action(hwnd: HWND) {
    let chk_path_hwnd = PATH_CHECKBOX_HWND.load(Ordering::SeqCst) as HWND;
    let chk_uninst_hwnd = UNINSTALLER_CHECKBOX_HWND.load(Ordering::SeqCst) as HWND;
    let chk_dl_hwnd = DOWNLOADER_CHECKBOX_HWND.load(Ordering::SeqCst) as HWND;
    let status_hwnd = STATUS_LABEL_HWND.load(Ordering::SeqCst) as HWND;

    let should_add_to_path = unsafe {
        SendMessageW(chk_path_hwnd, BM_GETCHECK, 0, 0) == BST_CHECKED as LRESULT
    };
    let install_uninstaller = unsafe {
        SendMessageW(chk_uninst_hwnd, BM_GETCHECK, 0, 0) == BST_CHECKED as LRESULT
    };
    let force_download = unsafe {
        SendMessageW(chk_dl_hwnd, BM_GETCHECK, 0, 0) == BST_CHECKED as LRESULT
    };

    match perform_setup_install(should_add_to_path, install_uninstaller, force_download, Some(status_hwnd)) {
        Ok(_) => {
            unsafe {
                let title = to_wide("RAY Setup - Complete");
                let message = to_wide(
                    "Thanks for choosing RAY!\n\
                     Engineered & Built by Sarvesh.S\n\n\
                     Installation completed successfully.\n\
                     Opening PowerShell for you now to get started with 'ray version'!"
                );
                MessageBoxW(hwnd, message.as_ptr(), title.as_ptr(), MB_OK | MB_ICONINFORMATION);

                // Open new interactive terminal
                let _ = std::process::Command::new("powershell.exe")
                    .arg("-NoExit")
                    .arg("-Command")
                    .arg("ray version")
                    .spawn();

                DestroyWindow(hwnd);
            }
        }
        Err(err) => {
            unsafe {
                set_status_text(status_hwnd, "Installation failed.");
                let title = to_wide("RAY Setup - Error");
                let msg = to_wide(&format!("Installation failed:\n\n{}\n\nPlease check your internet connection or run install.bat.", err));
                MessageBoxW(hwnd, msg.as_ptr(), title.as_ptr(), MB_OK | MB_ICONERROR);
            }
            IS_WORKING.store(false, Ordering::SeqCst);
        }
    }
}

#[cfg(windows)]
fn perform_gui_uninstall_action(hwnd: HWND) {
    let status_hwnd = STATUS_LABEL_HWND.load(Ordering::SeqCst) as HWND;

    unsafe {
        let title = to_wide("RAY Setup - Confirm Uninstallation");
        let question = to_wide(
            "Are you sure you want to completely uninstall RAY?\n\n\
             This will remove ray.exe, unregister from PATH, and delete the installation directory."
        );
        let response = MessageBoxW(hwnd, question.as_ptr(), title.as_ptr(), MB_YESNO | MB_ICONQUESTION);

        if response != IDYES {
            IS_WORKING.store(false, Ordering::SeqCst);
            return;
        }

        set_status_text(status_hwnd, "Uninstalling RAY and removing from PATH...");
    }

    match Installer::uninstall(None, true, true) {
        Ok(_) => {
            unsafe {
                set_status_text(status_hwnd, "RAY has been successfully uninstalled.");
                let title = to_wide("RAY Setup - Uninstalled");
                let message = to_wide(
                    "RAY has been completely removed from your system.\n\
                     Engineered & Built by Sarvesh.S"
                );
                MessageBoxW(hwnd, message.as_ptr(), title.as_ptr(), MB_OK | MB_ICONINFORMATION);
                DestroyWindow(hwnd);
            }
        }
        Err(err) => {
            unsafe {
                set_status_text(status_hwnd, "Uninstallation encountered an issue.");
                let title = to_wide("RAY Setup - Error");
                let msg = to_wide(&format!("Uninstallation error:\n{}", err));
                MessageBoxW(hwnd, msg.as_ptr(), title.as_ptr(), MB_OK | MB_ICONERROR);
            }
            IS_WORKING.store(false, Ordering::SeqCst);
        }
    }
}

#[cfg(windows)]
fn run_gui_setup() {
    unsafe {
        let hinstance = GetModuleHandleW(std::ptr::null());
        let class_name = to_wide("RAYSetupWindowClass");

        let wnd_class = WNDCLASSW {
            style: CS_HREDRAW | CS_VREDRAW,
            lpfnWndProc: Some(window_proc),
            cbClsExtra: 0,
            cbWndExtra: 0,
            hInstance: hinstance,
            hIcon: 0 as _,
            hCursor: 0 as _,
            hbrBackground: (COLOR_WINDOW + 1) as HBRUSH,
            lpszMenuName: std::ptr::null(),
            lpszClassName: class_name.as_ptr(),
        };

        RegisterClassW(&wnd_class);

        let window_title = to_wide("RAY Setup — Universal Package Manager");
        let width = 570;
        let height = 460;

        let screen_w = GetSystemMetrics(SM_CXSCREEN);
        let screen_h = GetSystemMetrics(SM_CYSCREEN);
        let x = (screen_w - width) / 2;
        let y = (screen_h - height) / 2;

        let hwnd = CreateWindowExW(
            0,
            class_name.as_ptr(),
            window_title.as_ptr(),
            WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX | WS_VISIBLE,
            x,
            y,
            width,
            height,
            std::ptr::null_mut(),
            std::ptr::null_mut(),
            hinstance,
            std::ptr::null(),
        );

        ShowWindow(hwnd, SW_SHOW);

        let mut msg: MSG = std::mem::zeroed();
        while GetMessageW(&mut msg, std::ptr::null_mut(), 0, 0) > 0 {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
}

#[cfg(windows)]
fn main() {
    let args: Vec<String> = std::env::args().collect();

    // Check for silent uninstallation flag
    if args.iter().any(|a| a == "--uninstall" || a == "-u") {
        match Installer::uninstall(None, true, true) {
            Ok(_) => {
                println!("RAY has been uninstalled successfully. Built by Sarvesh.S");
                std::process::exit(0);
            }
            Err(e) => {
                eprintln!("Uninstallation failed: {}", e);
                std::process::exit(1);
            }
        }
    }

    // If silent or CLI flags passed, perform non-interactive install
    if args.iter().any(|a| a == "-y" || a == "--yes" || a == "--silent" || a == "/S") {
        let should_add_to_path = !args.iter().any(|a| a == "--no-add-to-path");
        let force_download = args.iter().any(|a| a == "--download");
        match perform_setup_install(should_add_to_path, true, force_download, None) {
            Ok(dest) => {
                println!("RAY has been installed successfully to: {}", dest.display());
                println!("Thanks for choosing RAY! Built by Sarvesh.S");
                let _ = std::process::Command::new("powershell.exe")
                    .arg("-NoExit")
                    .arg("-Command")
                    .arg("ray version")
                    .spawn();
            }
            Err(e) => {
                eprintln!("Installation failed: {}", e);
                std::process::exit(1);
            }
        }
    } else {
        // Standard double-click mode: show the GUI installation & uninstallation wizard!
        run_gui_setup();
    }
}

#[cfg(not(windows))]
fn main() {
    println!("RAY Setup (GUI Installer) is tailored for Microsoft Windows.");
    println!("For Apple Silicon (M1/M2/M3/M4 macOS) and Linux (ARM64 / x86_64), install using:");
    println!("  curl -fsSL https://raw.githubusercontent.com/kavithashanmugavel2010-jpg/upm/main/install.sh | bash");
}
