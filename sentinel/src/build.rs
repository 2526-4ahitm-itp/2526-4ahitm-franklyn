use std::fmt::Write as _;
use std::fs::read_to_string;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::{env, fs};

use serde::Deserialize;

fn main() {
    set_env_cfg();
    bundle_licenses();
}

#[derive(Deserialize)]
struct BundledLicenses {
    third_party_libraries: Vec<Library>,
}

#[derive(Deserialize)]
struct Library {
    package_name: String,
    package_version: String,
    repository: String,
    license: String,
    licenses: Vec<LicenseText>,
}

#[derive(Deserialize)]
struct LicenseText {
    text: String,
}

fn bundle_licenses() {
    let manifest_dir = env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR not set");
    let out_path = Path::new(&manifest_dir).join("thirdparty");

    fs::create_dir_all(&out_path).expect("failed to create thirdparty/ directory");

    let yaml_path = out_path.join("licenses.yaml");
    let status = Command::new("cargo")
        .args([
            "bundle-licenses",
            "-f",
            "yaml",
            "-o",
            yaml_path
                .to_str()
                .expect("thirdparty path is not valid UTF-8"),
        ])
        .status()
        .expect("failed to run cargo bundle-licenses — is it installed?");

    assert!(
        status.success(),
        "cargo bundle-licenses failed with exit code: {status}"
    );

    let license_src = match env::var("LICENSE_PATH") {
        Ok(path) => PathBuf::from(path),
        Err(_) => Path::new(&manifest_dir).join("../LICENSE"),
    };
    let license_dst = out_path.join("LICENSE");
    fs::copy(&license_src, &license_dst).unwrap_or_else(|e| {
        panic!(
            "failed to copy LICENSE from {} to {}: {e}",
            license_src.display(),
            license_dst.display()
        )
    });

    let yaml_content = fs::read_to_string(&yaml_path).expect("failed to read licenses.yaml");
    let bundled: BundledLicenses =
        serde_yaml_ng::from_str(&yaml_content).expect("failed to parse licenses.yaml");

    let libs = &bundled.third_party_libraries;

    let short = generate_short(libs);
    fs::write(out_path.join("licenses-short.txt"), short)
        .expect("failed to write licenses-short.txt");

    let full = generate_full(libs);
    fs::write(out_path.join("licenses-full.txt"), full).expect("failed to write licenses-full.txt");

    println!("cargo:rerun-if-changed=Cargo.lock");
    println!("cargo:rerun-if-changed={}", license_src.display());
    println!("cargo:rerun-if-env-changed=LICENSE_PATH");
}

fn generate_short(libs: &[Library]) -> String {
    let mut out = String::from("Third-party open source licenses\n\n");
    let total = libs.len();

    for (i, lib) in libs.iter().enumerate() {
        let is_last = i == total - 1;
        let branch = if is_last {
            "\u{2514}\u{2500}"
        } else {
            "\u{251c}\u{2500}"
        };
        let pipe = if is_last { "  " } else { "\u{2502}  " };
        let has_url = !lib.repository.is_empty();

        writeln!(out, "{branch} {}@{}", lib.package_name, lib.package_version).unwrap();

        if has_url {
            writeln!(out, "{pipe} \u{251c}\u{2500} License: {}", lib.license).unwrap();
            writeln!(out, "{pipe} \u{2514}\u{2500} URL: {}", lib.repository).unwrap();
        } else {
            writeln!(out, "{pipe} \u{2514}\u{2500} License: {}", lib.license).unwrap();
        }
    }

    out
}

fn generate_full(libs: &[Library]) -> String {
    let mut out = String::new();

    for (i, lib) in libs.iter().enumerate() {
        if i > 0 {
            out.push_str("\n-----\n\n");
        }

        writeln!(
            out,
            "The following software may be included in this product: {}@{}",
            lib.package_name, lib.package_version
        )
        .unwrap();

        if !lib.repository.is_empty() {
            writeln!(
                out,
                "A copy of the source code may be downloaded from {}",
                lib.repository
            )
            .unwrap();
        }

        out.push_str("This software contains the following license and notice below:\n\n");

        for (j, license_text) in lib.licenses.iter().enumerate() {
            if j > 0 {
                out.push('\n');
            }
            out.push_str(license_text.text.trim_end());
            out.push('\n');
        }
    }

    out
}

fn set_env_cfg() {
    let franklyn_version = read_to_string("../VERSION")
        .expect("VERSION file doesn't exist!")
        .replace(['\n', '\r'], "");

    println!("cargo:rerun-if-changed=../VERSION");
    println!("cargo:rustc-env=FRANKLYN_VERSION={}", franklyn_version);

    // order of features is precedence (first)
    let env_features = [
        ("dev", cfg!(feature = "dev")),
        ("prod", cfg!(feature = "prod")),
    ];

    let enabled: Vec<&str> = env_features
        .iter()
        .filter(|(_, enabled)| *enabled)
        .map(|(name, _)| *name)
        .collect();

    match enabled.len() {
        0 => {
            println!("cargo:rustc-cfg=env=\"dev\"");
        }
        n => {
            if n > 1 {
                println!(
                    "cargo:warning=Multiple environment features enabled: {:?}. Using '{}' based on precedence.",
                    enabled, enabled[0]
                );
            }
            println!("cargo:rustc-cfg=env=\"{}\"", enabled[0]);
        }
    }
}
