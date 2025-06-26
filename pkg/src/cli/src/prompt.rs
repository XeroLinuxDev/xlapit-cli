#![allow(dead_code)]

use cli_input::prelude::*;
use piglog::prelude::*;
use colored::Colorize;

pub fn prompt(text: &str) -> String {
    return input!(
        "{l}{}{r} {} {} ",
        "Prompt".bright_cyan().bold(),
        text,
        "->".bright_magenta().bold(),
        l = "[".bright_black().bold(),
        r = "] :".bright_black().bold(),
    );
}

pub fn bool_question(text: &str, fallback: Option<bool>) -> bool {
    let y_n = match fallback {
        None => ("y", "n"),
        Some(s) => {
            match s {
                true => ("Y", "n"),
                false => ("y", "N"),
            }
        },
    };

    let mut ret: Option<bool> = None;
    while ret == None {
        let answer = input!(
            "{l}{}{r} {} {}{}{}{}{} {} ",
            "Boolean".bright_yellow().bold(),
            text,
            "[".bright_black().bold(),
            y_n.0.bright_green().bold(),
            "/".bright_black().bold(),
            y_n.1.bright_red().bold(),
            "]".bright_black().bold(),
            "->".bright_magenta().bold(),
            l = "[".bright_black().bold(),
            r = "] :".bright_black().bold(),
        );

        match answer.trim().to_lowercase().as_str() {
            "y" => { ret = Some(true); },
            "n" => { ret = Some(false); },
            "" => {
                if let Some(s) = fallback {
                    ret = Some(s);
                } else {
                    piglog::error!("You must specify either 'y' or 'n'! Try again!");
                }
            },
            _ => piglog::error!("Invalid input! Try again!"),
        };
    }

    return ret.unwrap();
}
