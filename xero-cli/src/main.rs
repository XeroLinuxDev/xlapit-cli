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

use script::*;
use prompt::*;
use command::run_command_silent;

enum ExitCode {
    Success,
    Fail,
}

enum Script {
    SystemSetup,
    Drivers,
    Distrobox,
    RecommendedPackages,
    Customization,
    Service,
    Gaming,
    Exit,
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
            Self::Exit => "exit",
        }.to_string();
    }
}

fn main() {
    match app() {
        ExitCode::Success => (),
        ExitCode::Fail => std::process::exit(1),
    };
}

fn app() -> ExitCode {
    let term = Arc::new(AtomicBool::new(false));
    flag::register(SIGINT, Arc::clone(&term)).expect("Failed to register SIGINT handler");

    // Parse CLI arguments.
    let args = cli::Cli::parse();

    if args.minimal && args.verbose {
        piglog::fatal!("Are you trying to create an explosion or something? (Don't use --verbose and --minimal together!)");

        return ExitCode::Fail;
    }

    // Check for termination signal
    if term.load(Ordering::Relaxed) {
        return ExitCode::Success;
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
                            false => return ExitCode::Fail,
                        };
                    },
                    cli::APICommand::Echo { msg, mode } => {
                        piglog::log_core_print(msg, mode);
                    },
                    cli::APICommand::GenericEcho { msg } => {
                        piglog::log_generic_print(msg);
                    },
                };

                return ExitCode::Success;
            },
        };
    }

    let scripts = Path::new(&args.scripts_path.unwrap_or("/usr/share/xero-scripts".to_string()));

    if scripts.exists() == false {
        piglog::fatal!("The directory ({}) containing all the scripts does not exist!", scripts.to_string().bright_red().bold());

        return ExitCode::Fail;
    }

    // Export environment variable.
    std::env::set_var("SCRIPTS_PATH", scripts.to_string());

    let os_release = match file::read(&Path::new("/etc/os-release")) {
        Ok(o) => o,
        Err(e) => {
            eprintln!("Failed to read os-release file: {}", e);

            return ExitCode::Fail;
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

        return ExitCode::Fail;
    }

    // Options.
    let options = vec![
        ("System Setup.", Script::SystemSetup),
        ("System Drivers.", Script::Drivers),
        ("Distrobox & Docker.", Script::Distrobox),
        ("System Customization.", Script::Customization),
        ("Game Launchers/Tweaks.", Script::Gaming),
        ("Recommended System Packages.", Script::RecommendedPackages),
        ("System Troubleshooting & Tweaks.", Script::Service),

        ("Exit the toolkit. (If it doesn't just close the Window).", Script::Exit),
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
        match detect_aur_helper() {
            Some(helper) => {
                piglog::info!("AUR helper selected: {}", helper.bright_yellow().bold());
                println!("         App Version: {}", version_str.split_whitespace().last().unwrap_or("").bright_yellow());
                println!("");
            },
            None => return ExitCode::Fail,
        };

        println!("Welcome, {username}! What would you like to do today?\n");

        for (i, j) in options.iter().enumerate() {
            let prefix = if i == options.len() - 1 { "X" } else { &(i + 1).to_string() };
            piglog::generic!("{} {} {}", prefix.bright_cyan().bold(), ":".bright_black().bold(), j.0.bright_green().bold());
            if i == options.len() - 2 {  // Add empty line before last option
                println!("");  // Single newline before exit option
            }
        }
        println!("");  // Single newline before prompt

        // Modified selection handling
        let mut selected: Option<usize> = None;
        while selected == None {
            let answer = prompt("Please select option (by number or X to exit).");
            let answer = answer.trim();

            if answer.eq_ignore_ascii_case("x") {
                // Exit immediately when X is pressed
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
                else if sel > options.len() - 1 {  // Subtract 1 to exclude Exit option from number selection
                    piglog::error!("Number must not exceed the amount of options!");
                    selected = None;
                }
            }
        }

        // Converting selected to the index of the options array
        let selected: usize = selected.unwrap() - 1;
        let option = options.get(selected).unwrap();

        // Don't try to run a script for the Exit option
        if matches!(option.1, Script::Exit) {
            return ExitCode::Success;
        }

        user_run_script(&option.1.script_name());
        clear_terminal();
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

fn select_aur_helper(aur_helper: &str) {
    std::env::set_var("AUR_HELPER", aur_helper);
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

    // Detect AUR helper.
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
        let paths: Vec<Path> = o.trim().split(":").map(|x| Path::new(x)).collect();

        if args.verbose {
            piglog::info!("Searching for binary: {}", binary.bright_yellow().bold());
        }

        for i in paths.iter() {
            if args.verbose {
                piglog::generic!("Searching in: {}", i.to_string().magenta());
            }

            let path = i.add_str(binary);

            if path.exists() {
                if args.minimal == false {
                    piglog::success!("Found '{}' in: {}", binary.bright_yellow().bold(), i.to_string().bright_green());
                }
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
