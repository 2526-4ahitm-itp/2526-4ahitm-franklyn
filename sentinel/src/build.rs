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

    let output = Command::new("cargo")
        .args(["bundle-licenses", "-f", "yaml", "-o", "/dev/stdout"])
        .output()
        .expect("failed to run cargo bundle-licenses — is it installed?");

    assert!(
        output.status.success(),
        "cargo bundle-licenses failed with exit code: {}",
        output.status
    );

    let license_src = env::var("LICENSE_PATH").map_or_else(
        |_| Path::new(&manifest_dir).join("../LICENSE"),
        PathBuf::from,
    );

    let license_content = read_to_string(license_src).expect("license couldn't be read!");

    let yaml_content =
        String::from_utf8(output.stdout).expect("bundle-licenses was not valid UTF-8 output");
    let bundled: BundledLicenses =
        serde_yaml_ng::from_str(&yaml_content).expect("failed to parse licenses.yaml");

    let libs = &bundled.third_party_libraries;

    let short_content = generate_short(libs);

    let full_content = generate_full(libs);

    let out_dir = env::var("OUT_DIR").expect("NO OUT_DIR VARIABLE");
    let out = std::path::Path::new(&out_dir);

    println!("cargo:rerun-if-changed=Cargo.lock");
    println!("cargo:rerun-if-env-changed=LICENSE_PATH");

    fs::write(out.join("PROJECT_LICENSE.txt"), license_content)
        .expect("Failed to write PROJECT_LICENSE");
    fs::write(out.join("THIRDPARTY_SHORT.txt"), short_content)
        .expect("Failed to write THIRDPARTY_SHORT");
    fs::write(out.join("THIRDPARTY_FULL.txt"), full_content)
        .expect("Failed to write THIRDPARTY_FULL");
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
    let manifest_dir = env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR not set");

    let version_src = env::var("VERSION_PATH").map_or_else(
        |_| Path::new(&manifest_dir).join("../VERSION"),
        PathBuf::from,
    );

    let franklyn_version = read_to_string(version_src)
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
