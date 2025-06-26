#![allow(dead_code)]

use piglog::prelude::*;
use colored::Colorize;
use fspp::Path;
use signal_hook::{consts::SIGINT, flag};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use crate::prompt::bool_question;
use crate::command::run_command_silent;

// This is just a function for running a script in a user-friendly way.
pub fn user_run_script(script_name: &str) -> bool {
    let term = Arc::new(AtomicBool::new(false));
    flag::register(SIGINT, Arc::clone(&term)).expect("Failed to register SIGINT handler");

    if term.load(Ordering::Relaxed) {
        return true; // Clean exit on SIGINT
    }

    match run_script(script_name) {
        true => true,
        false => {
            if term.load(Ordering::Relaxed) {
                return true; // Clean exit if SIGINT received during script
            }

            let answer = bool_question("Would you like to try and run it again?", None);

            if answer {
                user_run_script(script_name)
            } else {
                false
            }
        },
    }
}

pub fn run_script(script_name: &str) -> bool {
    let path = Path::new(&std::env::var("SCRIPTS_PATH").unwrap());

    println!("");
    piglog::info!("Running script: {}", script_name.bright_yellow().bold());
    println!("");

    let result = run_command_silent(&path.add_str(&format!("{script_name}.sh")).to_string());

    if result {
        println!("");
        piglog::success!("Successfully ran script: {}", script_name.bright_green().bold());
        println!("");
    } else {
        println!("");
        piglog::error!("Failed to run script: {}", script_name.bright_red().bold());
        println!("");
    }

    result
}
