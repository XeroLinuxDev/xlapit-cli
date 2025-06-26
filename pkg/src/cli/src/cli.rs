use clap::*;
use piglog::LogMode;

#[derive(Parser)]
/// XeroLinux Post Installation Tool
pub struct Cli {
    #[clap(subcommand)]
    /// Subcommand
    pub command: Option<Commands>,

    #[clap(short, long, global = true)]
    /// Print verbose text
    pub verbose: bool,

    #[clap(short, long, global = true)]
    /// Print less text (not recommended, because this hides important information)
    pub minimal: bool,

    #[clap(long, global = true)]
    /// Prevent the program from clearing the terminal output! (Useful for when you want to see the output all the time)
    pub do_not_clear: bool,

    #[clap(long)]
    /// Manually specify an AUR helper
    pub aur_helper: Option<String>,

    #[clap(long)]
    /// Directory with all the scripts in it
    pub scripts_path: Option<String>,
}

#[derive(Subcommand)]
pub enum Commands {
    Api {
        #[clap(subcommand)]
        /// API command
        command: APICommand,
    },
}

#[derive(Subcommand)]
/// API Commands (Should Be Used Really Only By Scripts)
pub enum APICommand {
    /// Prompt the user for input
    Prompt {
        /// The prompt text
        text: String,
    },

    /// Prompt the user with a yes or no question
    BoolPrompt {
        /// The prompt text
        text: String,

        /// Fallback answer (when the user just presses ENTER without supplying yes or no)
        fallback: Option<bool>,
    },

    /// Print errors, info, warnings, etc...
    Echo {
        /// The message
        msg: String,

        /// The message type
        mode: LogMode,
    },

    /// Print generic messages
    GenericEcho {
        /// The message
        msg: String,
    },
}
