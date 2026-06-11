use std::{path::PathBuf, sync::LazyLock};

use config::{Config, Environment, File, FileFormat};
use directories::ProjectDirs;
use serde::{Deserialize, Serialize};

use crate::ConfigAction;

pub static CONFIG: LazyLock<AppConfig> = LazyLock::new(AppConfig::load);

#[derive(Debug, Serialize, Deserialize)]
pub struct AppConfig {
    pub api_url: String,
    pub oidc_url: String,
    pub oidc_realm: String,
    pub oidc_client_id: String,
    pub oidc_scopes: String,
}

impl AppConfig {
    pub fn load() -> Self {
        let mut config_builder = Config::builder();

        config_builder = config_builder.add_source(File::from_str(
            include_str!("../config/default.toml"),
            FileFormat::Toml,
        ));

        #[cfg(debug_assertions)]
        {
            config_builder = config_builder.add_source(File::from_str(
                include_str!("../config/dev.toml"),
                FileFormat::Toml,
            ));
        }

        config_builder = config_builder
            .add_source(File::from(system_config_path()).required(false))
            .add_source(File::from(config_path()).required(false))
            .add_source(Environment::with_prefix("FRANKLYN"));

        config_builder
            .build()
            .expect("config builder build")
            .try_deserialize::<Self>()
            .expect("serialized config to AppConfig")
    }
}

static QUALIFIER: &'static str = "at";
static ORGANIZATION: &'static str = "htl-leonding";
static APPLICATION: &'static str = "franklyn";

fn config_path() -> PathBuf {
    ProjectDirs::from(QUALIFIER, ORGANIZATION, APPLICATION)
        .expect("no valid home directory")
        .config_dir()
        .join("config.toml")
}

fn system_config_path() -> PathBuf {
    if let Ok(data_dir) = std::env::var("FRANKLYN_DATA_DIR") {
        return PathBuf::from(data_dir).join("config.toml");
    }

    #[cfg(target_os = "windows")]
    {
        let base = std::env::var("PROGRAMDATA").unwrap_or_else(|_| "C:\\ProgramData".to_string());
        PathBuf::from(base)
            .join(ORGANIZATION)
            .join(APPLICATION)
            .join("config.toml")
    }

    #[cfg(target_os = "macos")]
    {
        PathBuf::from("/Library/Application Support")
            .join(format!("{}.{}.{}", QUALIFIER, ORGANIZATION, APPLICATION))
            .join("config.toml")
    }

    #[cfg(not(any(target_os = "windows", target_os = "macos")))]
    {
        PathBuf::from("/etc").join(APPLICATION).join("config.toml")
    }
}

fn read_config() -> String {
    let path = config_path();
    if !path.exists() {
        std::fs::create_dir_all(path.parent().expect("config path has no parent"))
            .expect("create config dir");
        std::fs::write(&path, "").expect("create empty config file");
    }
    std::fs::read_to_string(path).expect("read config file")
}

pub fn run(action: &ConfigAction) {
    match action {
        ConfigAction::Get { key } => {
            let content = read_config();
            let doc = content
                .parse::<toml_edit::DocumentMut>()
                .expect("parse config as toml");
            match doc.get(key.as_str()) {
                Some(value) => println!("{}", value),
                None => println!("Key '{}' does not exist in the configuration.", key),
            }
        }
        ConfigAction::Set { key, value } => {
            let content = read_config();
            let mut doc = content
                .parse::<toml_edit::DocumentMut>()
                .expect("parse config as toml");
            doc[key.as_str()] = toml_edit::value(value.as_str());
            std::fs::write(config_path(), doc.to_string()).expect("write config file");
        }
        ConfigAction::List => {
            let cfg = &*CONFIG;
            if let serde_json::Value::Object(map) =
                serde_json::to_value(cfg).expect("serialize config")
            {
                let mut pairs: Vec<_> = map.into_iter().collect();
                pairs.sort_by_key(|(k, _)| k.clone());
                for (key, value) in pairs {
                    let display = match value {
                        serde_json::Value::String(s) => s,
                        other => other.to_string(),
                    };
                    println!("{} = {}", key, display);
                }
            }
        }
        ConfigAction::Unset { key } => {
            let content = read_config();
            let mut doc = content
                .parse::<toml_edit::DocumentMut>()
                .expect("parse config as toml");
            doc.remove(key.as_str());
            std::fs::write(config_path(), doc.to_string()).expect("write config file");
        }
        ConfigAction::Path => {
            println!("{}", config_path().display());
        }
        ConfigAction::Edit => {
            let editor = std::env::var("EDITOR").unwrap_or_else(|_| "vi".to_string());
            std::process::Command::new(editor)
                .arg(config_path())
                .status()
                .expect("open editor");
        }
    }
}
