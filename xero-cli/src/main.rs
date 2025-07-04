mod cli;
mod command;
mod script;
mod prompt;

use clap::Parser;
use colored::Colorize;
use piglog::prelude::*;
use fspp::*;
use signal_hook::{consts::SIGINT, flag};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::path::Path;

use script::*;
use prompt::*;
use command::run_command_silent;

enum Script {
    SystemSetup,
    Drivers,
    Distrobox,
    RecommendedPackages,
    Customization,
    Service,
    Gaming,
}

impl Script {
    pub fn script_name(&self) -> String {
        return match *self {
            Self::SystemSetup => "tool_init",
            Self::Drivers => "drivers",
            Self::Distrobox => "dbox",
            Self::Customization => "customization",
            Self::Gaming => "gaming",
            Self::RecommendedPackages => "pkgs",
            Self::Service => "service",
        }.to_string();
    }
}

fn main() -> std::process::ExitCode {
    // 🛠️ Register termination flag properly
    let term = Arc::new(AtomicBool::new(false));
    flag::register(SIGINT, Arc::clone(&term)).expect("Unable to register signal handler");

    // Parse CLI arguments.
    let args = cli::Cli::parse();

    if args.minimal && args.verbose {
        piglog::fatal!("Are you trying to create an explosion or something? (Don't use --verbose and --minimal together!)");

        return std::process::ExitCode::FAILURE;
    }

    // Check for termination signal
    if term.load(Ordering::Relaxed) {
        return std::process::ExitCode::SUCCESS;
    }

    std::env::set_var("CLEAR_TERMINAL", match args.do_not_clear { true => "0", false => "1" });

    if let Some(command) = args.command {
        match command {
            cli::Commands::Api { command } => {
                match command {
                    cli::APICommand::Prompt { text } => {
                        eprintln!("{}", prompt(&text));
                    },
                    cli::APICommand::BoolPrompt { text, fallback } => {
                        match bool_question(&text, fallback) {
                            true => (),
                            false => return std::process::ExitCode::FAILURE,
                        };
                    },
                    cli::APICommand::Echo { msg, mode } => {
                        piglog::log_core_print(msg, mode);
                    },
                    cli::APICommand::GenericEcho { msg } => {
                        piglog::log_generic_print(msg);
                    },
                };

                return std::process::ExitCode::SUCCESS;
            },
        };
    }

    let scripts_path = args.scripts_path.unwrap_or("/usr/share/xero-scripts".to_string());
    let scripts = Path::new(&scripts_path);

    if scripts.exists() == false {
        piglog::fatal!("The directory ({}) containing all the scripts does not exist!", scripts.to_string_lossy().bright_red().bold());

        return std::process::ExitCode::FAILURE;
    }

    // Export environment variable.
    std::env::set_var("SCRIPTS_PATH", scripts.to_string_lossy().to_string());

    let os_release = match file::read(&fspp::Path::new("/etc/os-release")) {
        Ok(o) => o,
        Err(e) => {
            eprintln!("Failed to read os-release file: {}", e);

            return std::process::ExitCode::FAILURE;
        },
    };

    let mut valid_distro = false;
    let mut found = String::new();

    for line in os_release.trim().lines() {
        let check = line.trim().replace(" ", "").replace("\"", "");

        if check.starts_with("ID=") {
            found = check.replace("ID=", "").trim().to_string();

            if found == "arch" || found == "XeroLinux" {
                valid_distro = true;
            }
        }
    }

    if valid_distro == false {
        if run_script("invalid_distro") == false {
            piglog::fatal!("Not a valid distro! Please run on either vanilla Arch, or XeroLinux! (Found: {found})");
        }

        return std::process::ExitCode::FAILURE;
    }

    // Options.
    let options = vec![
        ("System Setup.", Script::SystemSetup),
        ("System Drivers.", Script::Drivers),
        ("Distrobox & Docker.", Script::Distrobox),
        ("System Customization.", Script::Customization),
        ("Game Launchers/Tweaks.", Script::Gaming),
        ("Recommended System Packages.", Script::RecommendedPackages),
        ("System Troubleshooting & More.", Script::Service),
    ];

    // ASCII logo.
    let logo1 = vec![
        "██╗  ██╗███████╗██████╗  █████╗ ",
        "╚██╗██╔╝██╔════╝██╔══██╗██╔══██╗",
        " ╚███╔╝ █████╗  ██████╔╝██║  ██║",
        " ██╔██╗ ██╔══╝  ██╔══██╗██║  ██║",
        "██╔╝╚██╗███████╗██║  ██║╚█████╔╝",
        "╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚════╝ ",
    ];

    let logo2 = vec![
        "██╗     ██╗███╗  ██╗██╗   ██╗██╗  ██╗",
        "██║     ██║████╗ ██║██║   ██║╚██╗██╔╝",
        "██║     ██║██╔██╗██║██║   ██║ ╚███╔╝ ",
        "██║     ██║██║╚████║██║   ██║ ██╔██╗ ",
        "███████╗██║██║ ╚███║╚██████╔╝██╔╝╚██╗",
        "╚══════╝╚═╝╚═╝  ╚══╝ ╚═════╝ ╚═╝  ╚═╝",
    ];

    let username = match std::env::var("USER") {
        Ok(o) => o,
        Err(_) => "<< FAILED TO GET USERNAME >>".to_string(),
    };

    // Main program loop.
    loop {
        // Clear the screen first
        clear_terminal();

        // Print the logo
        for i in 0..logo1.len() {
            print!("{}", logo1[i].magenta());
            println!("{}", logo2[i].blue());
        }

        println!("");  // Restore spacing after logo

        // Make sure there is an AUR helper on the system and show version
        let version_str = get_package_version().unwrap_or_default();
        let distro_name = get_distro_name();
        match detect_aur_helper() {
            Some(helper) => {
                piglog::info!("AUR helper : {} / Distro : {}", helper.bright_green().bold(), distro_name.magenta().bold());
                println!("         App/TUI Build Version : {}", version_str.split_whitespace().last().unwrap_or("").bright_yellow());
                println!("[Creds]: ");
                println!("         {} - Maintenance.", "tonekneeo".green().bold());
                println!("         {}     - Testing.", "SMOKΞ".blue().bold());
                println!("");
            },
            None => return std::process::ExitCode::FAILURE,
        };

        println!("Welcome, {username}! What would you like to do today?\n");

        for (i, j) in options.iter().enumerate() {
            let prefix = &(i + 1).to_string();
            piglog::generic!("{} {} {}", prefix.bright_cyan().bold(), ":".bright_black().bold(), j.0.bright_green().bold());
            if i == options.len() - 2 {  // Add empty line before last option
                println!("");  // Single newline before exit option
            }
        }
        println!("");  // Single newline before prompt

        // Modified selection handling
        let mut selected: Option<usize> = None;
        while selected == None {
            let answer = prompt("Please select option (x to exit).");
            let answer = answer.trim();

            if answer.eq_ignore_ascii_case("x") {
                // Exit immediately when x is pressed
                std::process::exit(0);
            }

            match answer.parse::<usize>() {
                Ok(o) => selected = Some(o),
                Err(_) => piglog::error!("Couldn't parse into a number, please try again!"),
            };

            if let Some(sel) = selected {
                if sel == 0 {
                    piglog::error!("Number must be above 0!");
                    selected = None;
                }
                else if sel > options.len() {
                    piglog::error!("Number must not exceed the amount of options!");
                    selected = None;
                }
            }
        }

        let selected: usize = selected.unwrap() - 1;
        let option = options.get(selected).unwrap();

        user_run_script(&option.1.script_name());
        // Exit the program after running a script - the script will handle returning to main menu
        std::process::exit(0);
    }
}

fn clear_terminal() -> bool {
    let clear: bool = match std::env::var("CLEAR_TERMINAL") {
        Ok(o) => match o.as_str() {
            "0" => false,
            _ => true,
        },
        Err(_) => true,
    };

    if clear {
        return run_command_silent("clear");
    }

    else {
        return true;
    }
}

fn get_package_version() -> Option<String> {
    if let Ok(output) = std::process::Command::new("pacman")
        .args(["-Q", "xlapit-cli"])
        .output() {
            if output.status.success() {
                if let Ok(version) = String::from_utf8(output.stdout) {
                    return Some(version.trim().to_string());
                }
            }
        }
        None
}

fn get_distro_name() -> String {
    let os_release = match file::read(&fspp::Path::new("/etc/os-release")) {
        Ok(o) => o,
        Err(_) => return "Unknown".to_string(),
    };

    for line in os_release.trim().lines() {
        let check = line.trim().replace(" ", "").replace("\"", "");
        
        if check.starts_with("PRETTY_NAME=") {
            let pretty_name = check.replace("PRETTY_NAME=", "").trim().to_string();
            return pretty_name;
        }
    }

    // Fallback to ID if PRETTY_NAME is not found
    for line in os_release.trim().lines() {
        let check = line.trim().replace(" ", "").replace("\"", "");
        
        if check.starts_with("ID=") {
            let id = check.replace("ID=", "").trim().to_string();
            return id.to_uppercase();
        }
    }

    "Unknown".to_string()
}

fn select_aur_helper(aur_helper: &str) {
    let aur_helper_with_flags = format!("{} --mflags --skipinteg", aur_helper);
    std::env::set_var("AUR_HELPER", aur_helper_with_flags);
}

fn detect_aur_helper() -> Option<String> {
    let args = cli::Cli::parse();

    if let Some(aur_helper) = args.aur_helper {
        if binary_exists(&aur_helper) {
            select_aur_helper(&aur_helper);
            return Some(aur_helper);
        }
        else {
            return None;
        }
    }

    let aur_helpers = vec![
        "yay",
        "paru",
    ];

    let mut aur_helper_detected: Option<&str> = None;
    for i in aur_helpers.iter() {
        if binary_exists(i) {
            aur_helper_detected = Some(i);
            break;
        }
    }

    if aur_helper_detected == None {
        piglog::fatal!("Failed to detect an AUR helper! (From pre-made list):");
        for i in aur_helpers.iter() {
            piglog::generic!("{i}");
        }
        piglog::note!("If your AUR helper of choice is not listed here, you can manually specify it with the '--aur-helper <insert binary name>' flag!");
        piglog::note!("Example: xero-cli --aur-helper paru");
        piglog::note!("This flag also forces the use of the AUR helper, so you can skip the detection phase completely!");
        return None;
    }

    if let Some(aur_helper) = aur_helper_detected {
        select_aur_helper(aur_helper);
        return Some(aur_helper.to_string());
    }

    return None;
}

fn binary_exists(binary: &str) -> bool {
    let args = cli::Cli::parse();

    if let Ok(o) = std::env::var("PATH") {
        let paths: Vec<&Path> = o.trim().split(":").map(|x| Path::new(x)).collect();

        if args.verbose {
            piglog::info!("Searching for binary: {}", binary.bright_yellow().bold());
        }

        for i in paths.iter() {
            if args.verbose {
                piglog::generic!("Searching in: {}", i.to_string_lossy().magenta());
            }

            let path = i.join(binary);

            if path.exists() {
                // if args.minimal == false {
                //     piglog::success!("Found '{}' in: {}", binary.bright_yellow().bold(), i.to_string_lossy().bright_green());
                // }
                return true;
            }
        }
    }

    if args.verbose {
        piglog::error!("Did not find binary! Seeing if absolute path exists...");
    }

    if Path::new(binary).exists() {
        if args.verbose {
            piglog::success!("Binary: {}", binary.bright_green());
        }
        return true;
    }

    if args.verbose {
        piglog::error!("Could not find binary: {}", binary.bright_red().bold());
    }

    return false;
}
