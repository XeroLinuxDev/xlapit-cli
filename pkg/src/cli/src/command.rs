#![allow(dead_code)]

use piglog::prelude::*;
use colored::Colorize;

pub fn run_command(command: &str) -> bool {
    piglog::info!("Running command: '{}'", command.bright_yellow());
    return run_command_silent(command);
}

pub fn run_command_silent(command: &str) -> bool {
    match std::process::Command::new("bash")
        .args(["-c", command])
        .status() 
    {
        Ok(status) => match status.code() {
            Some(code) => code == 0,
            None => {
                // Process terminated by signal (e.g., SIGINT)
                // Exit the program with the same signal
                std::process::exit(0);
            }
        },
        Err(_e) => false,
    }
}
