#[path = "../terminal.rs"]
mod terminal;
#[path = "../installer.rs"]
mod installer;

use clap::Parser;
use std::io::{self, IsTerminal, Write};
use std::path::PathBuf;

#[cfg(windows)]
use std::ffi::OsStr;
#[cfg(windows)]
use std::os::windows::ffi::OsStrExt;
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
    CS_HREDRAW, CS_VREDRAW, MB_ICONERROR, MB_ICONINFORMATION, MB_OK,
    MSG, SM_CXSCREEN, SM_CYSCREEN, SW_SHOW, WM_COMMAND, WM_CREATE, WM_DESTROY, WM_SETFONT, WNDCLASSW,
    WS_CHILD, WS_MINIMIZEBOX, WS_OVERLAPPED, WS_SYSMENU, WS_VISIBLE,
};

use installer::Installer;
use terminal::{init_console_vt, print_banner, BADGE_RAY};

#[derive(Parser)]
#[command(
    name = "ray-uninstaller",
    about = "Uninstaller for RAY (Universal Package Manager) on Windows",
    version = "0.1.0"
)]
struct UninstallerCli {
    /// Directory where RAY is installed (default: %LOCALAPPDATA%\ray\bin)
    #[arg(short, long)]
    dir: Option<PathBuf>,

    /// Remove RAY from the User PATH environment variable
    #[arg(long, conflicts_with = "no_remove_from_path")]
    remove_from_path: bool,

    /// Do NOT remove RAY from the User PATH
    #[arg(long, conflicts_with = "remove_from_path")]
    no_remove_from_path: bool,

    /// Delete RAY package cache store (%LOCALAPPDATA%\ray\store)
    #[arg(long)]
    clean_cache: bool,

    /// Non-interactive uninstallation with default options
    #[arg(short = 'y', long = "yes")]
    assume_yes: bool,

    /// Open graphical uninstaller window
    #[arg(long)]
    gui: bool,
}

#[cfg(windows)]
const WS_CAPTION: u32 = 0x00C00000;
#[cfg(windows)]
const BST_CHECKED: usize = 1;

#[cfg(windows)]
const IDC_UNINSTALL_BTN: usize = 2001;
#[cfg(windows)]
const IDC_CANCEL_BTN: usize = 2002;
#[cfg(windows)]
const IDC_REMOVE_PATH_CHECKBOX: usize = 2003;
#[cfg(windows)]
const IDC_CLEAN_CACHE_CHECKBOX: usize = 2004;

#[cfg(windows)]
static REMOVE_PATH_HWND: std::sync::atomic::AtomicIsize = std::sync::atomic::AtomicIsize::new(0);
#[cfg(windows)]
static CLEAN_CACHE_HWND: std::sync::atomic::AtomicIsize = std::sync::atomic::AtomicIsize::new(0);
#[cfg(windows)]
static STATUS_HWND: std::sync::atomic::AtomicIsize = std::sync::atomic::AtomicIsize::new(0);
#[cfg(windows)]
static IS_UNINSTALLING: AtomicBool = AtomicBool::new(false);

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

#[cfg(windows)]
unsafe extern "system" fn uninstaller_wnd_proc(
    hwnd: HWND,
    msg: u32,
    wparam: WPARAM,
    lparam: LPARAM,
) -> LRESULT {
    match msg {
        WM_CREATE => {
            let hinstance = GetModuleHandleW(std::ptr::null());
            let font_title = create_segoe_font(20, true);
            let font_author = create_segoe_font(14, true);
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

            // Title
            make_label("Uninstall RAY (Universal Package Manager)", 30, 20, 480, 28, font_title);
            make_label("Engineered & Built by Sarvesh.S", 30, 50, 480, 20, font_author);
            make_label("Are you sure you want to completely remove RAY from your computer?", 30, 80, 480, 22, font_normal);

            let install_dir = Installer::default_install_dir();
            let dir_notice = format!("Target Location: {}", install_dir.display());
            make_label(&dir_notice, 30, 110, 480, 20, font_small);

            let button_class = to_wide("BUTTON");

            // Option 1: Remove from PATH
            let chk_path_text = to_wide("Remove RAY from User PATH environment variable (Recommended)");
            let h_chk_path = CreateWindowExW(
                0,
                button_class.as_ptr(),
                chk_path_text.as_ptr(),
                WS_CHILD | WS_VISIBLE | (BS_AUTOCHECKBOX as u32),
                35,
                145,
                480,
                24,
                hwnd,
                IDC_REMOVE_PATH_CHECKBOX as *mut _,
                hinstance,
                std::ptr::null(),
            );
            SendMessageW(h_chk_path, WM_SETFONT, font_normal as WPARAM, 1);
            SendMessageW(h_chk_path, BM_SETCHECK, BST_CHECKED as WPARAM, 0);
            REMOVE_PATH_HWND.store(h_chk_path as isize, Ordering::SeqCst);

            // Option 2: Clean package cache store
            let chk_cache_text = to_wide("Delete package store cache (%LOCALAPPDATA%\\ray\\store)");
            let h_chk_cache = CreateWindowExW(
                0,
                button_class.as_ptr(),
                chk_cache_text.as_ptr(),
                WS_CHILD | WS_VISIBLE | (BS_AUTOCHECKBOX as u32),
                35,
                175,
                480,
                24,
                hwnd,
                IDC_CLEAN_CACHE_CHECKBOX as *mut _,
                hinstance,
                std::ptr::null(),
            );
            SendMessageW(h_chk_cache, WM_SETFONT, font_normal as WPARAM, 1);
            CLEAN_CACHE_HWND.store(h_chk_cache as isize, Ordering::SeqCst);

            // Status label
            let h_status = make_label("Click 'Uninstall Now' to begin removal.", 35, 215, 480, 20, font_author);
            STATUS_HWND.store(h_status as isize, Ordering::SeqCst);

            // Uninstall Button
            let uninst_btn_text = to_wide("Uninstall Now");
            let h_uninst = CreateWindowExW(
                0,
                button_class.as_ptr(),
                uninst_btn_text.as_ptr(),
                WS_CHILD | WS_VISIBLE | (BS_DEFPUSHBUTTON as u32),
                250,
                255,
                135,
                36,
                hwnd,
                IDC_UNINSTALL_BTN as *mut _,
                hinstance,
                std::ptr::null(),
            );
            SendMessageW(h_uninst, WM_SETFONT, font_author as WPARAM, 1);

            // Cancel Button
            let cancel_text = to_wide("Cancel");
            let h_cancel = CreateWindowExW(
                0,
                button_class.as_ptr(),
                cancel_text.as_ptr(),
                WS_CHILD | WS_VISIBLE | (BS_PUSHBUTTON as u32),
                395,
                255,
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
            if ctrl_id == IDC_UNINSTALL_BTN {
                if !IS_UNINSTALLING.swap(true, Ordering::SeqCst) {
                    let chk_path_hwnd = REMOVE_PATH_HWND.load(Ordering::SeqCst) as HWND;
                    let chk_cache_hwnd = CLEAN_CACHE_HWND.load(Ordering::SeqCst) as HWND;
                    let status_hwnd = STATUS_HWND.load(Ordering::SeqCst) as HWND;

                    let remove_from_path = SendMessageW(chk_path_hwnd, BM_GETCHECK, 0, 0) == BST_CHECKED as LRESULT;
                    let clean_cache = SendMessageW(chk_cache_hwnd, BM_GETCHECK, 0, 0) == BST_CHECKED as LRESULT;

                    let installing_text = to_wide("Uninstalling RAY and removing files...");
                    SetWindowTextW(status_hwnd, installing_text.as_ptr());

                    match Installer::uninstall(None, remove_from_path, clean_cache) {
                        Ok(_) => {
                            let title = to_wide("RAY Uninstaller - Complete");
                            let msg = to_wide("RAY has been successfully uninstalled from your computer.\nEngineered & Built by Sarvesh.S");
                            MessageBoxW(hwnd, msg.as_ptr(), title.as_ptr(), MB_OK | MB_ICONINFORMATION);
                            DestroyWindow(hwnd);
                        }
                        Err(err) => {
                            let title = to_wide("RAY Uninstaller - Error");
                            let msg = to_wide(&format!("Uninstallation failed:\n{}", err));
                            MessageBoxW(hwnd, msg.as_ptr(), title.as_ptr(), MB_OK | MB_ICONERROR);
                            IS_UNINSTALLING.store(false, Ordering::SeqCst);
                        }
                    }
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
fn run_gui_uninstaller() {
    unsafe {
        let hinstance = GetModuleHandleW(std::ptr::null());
        let class_name = to_wide("RAYUninstallerWindowClass");

        let wnd_class = WNDCLASSW {
            style: CS_HREDRAW | CS_VREDRAW,
            lpfnWndProc: Some(uninstaller_wnd_proc),
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

        let window_title = to_wide("RAY Uninstaller — Universal Package Manager");
        let width = 530;
        let height = 350;

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

fn main() {
    let args: Vec<String> = std::env::args().collect();

    // Check if launched without CLI arguments on Windows -> open GUI Uninstaller!
    #[cfg(windows)]
    if args.len() == 1 || args.iter().any(|a| a == "--gui") {
        run_gui_uninstaller();
        return;
    }

    init_console_vt();
    print_banner();

    println!("\x1b[1;37mWelcome to the RAY (Universal Package Manager) Uninstaller!\x1b[0m\n");

    let cli = UninstallerCli::parse();

    let target_dir = cli.dir.unwrap_or_else(Installer::default_install_dir);

    if !cli.assume_yes {
        println!(
            "{} Target installation directory: \x1b[1;36m{}\x1b[0m",
            BADGE_RAY,
            target_dir.display()
        );
        let confirmed = Installer::prompt_yes_no("Are you sure you want to completely uninstall RAY?", true);
        if !confirmed {
            println!("{} Uninstallation cancelled.", BADGE_RAY);
            pause_if_terminal();
            return;
        }
    }

    // Determine remove_from_path
    let should_remove_path = if cli.remove_from_path {
        true
    } else if cli.no_remove_from_path {
        false
    } else if cli.assume_yes {
        true
    } else {
        println!();
        println!("{} \x1b[1mOptions:\x1b[0m", BADGE_RAY);
        Installer::prompt_yes_no("Remove RAY from your User PATH environment variable? (Recommended)", true)
    };

    // Determine clean_cache
    let should_clean_cache = if cli.clean_cache {
        true
    } else if cli.assume_yes {
        false
    } else {
        Installer::prompt_yes_no("Delete RAY package store cache (%LOCALAPPDATA%\\ray\\store)?", false)
    };

    println!("\n{} Uninstalling RAY...", BADGE_RAY);

    match Installer::uninstall(Some(target_dir), should_remove_path, should_clean_cache) {
        Ok(_) => {
            println!("\n\x1b[1;32m══════════════════════════════════════════════════════════════════\x1b[0m");
            println!("\x1b[1;32m✓ RAY has been completely removed from your system.\x1b[0m");
            println!("\x1b[1;32m══════════════════════════════════════════════════════════════════\x1b[0m\n");
        }
        Err(e) => {
            eprintln!("{} \x1b[1;31mUninstallation encountered an issue:\x1b[0m {}", BADGE_RAY, e);
        }
    }

    pause_if_terminal();
}

fn pause_if_terminal() {
    if io::stdin().is_terminal() {
        print!("Press Enter to exit...");
        let _ = io::stdout().flush();
        let mut discard = String::new();
        let _ = io::stdin().read_line(&mut discard);
    }
}
