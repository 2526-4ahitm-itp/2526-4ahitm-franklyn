use std::fmt::Write as _;
use std::fs::{read_dir, read_to_string, remove_dir_all};
use std::path::{Path, PathBuf};
use std::process::Command;
use std::{env, fs};

use serde::Deserialize;

fn main() {
    set_version();
    build_proto();
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
    repository: Option<String>,
    license: String,
    licenses: Vec<LicenseText>,
}

#[derive(Deserialize)]
struct LicenseText {
    text: String,
}

fn build_proto() {
    let manifest_dir = env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR not set");

    let protobuf_gen_path = env::var("PROTOBUF_GEN_PATH");

    let protobuf_location = match protobuf_gen_path {
        Ok(path) => PathBuf::from(path),
        Err(_) => {
            let protobuf_root = env::var("PROTOBUF_PATH").map_or_else(
                |_| Path::new(&manifest_dir).join("../protobuf"),
                PathBuf::from,
            );

            Command::new("buf")
                .current_dir(&protobuf_root)
                .args(["generate", "."])
                .status()
                .expect("failed to run 'buf generate .'");

            protobuf_root.join("gen")
        }
    };

    let gen_src_path = protobuf_location.join("rust");
    let out_path = PathBuf::from(env::var("OUT_DIR").expect("OUT_DIR not set"));

    fs::read_dir(&gen_src_path)
        .expect("Failed to read generated src dir")
        .filter_map(Result::ok)
        .map(|entry| entry.path())
        .for_each(|path| {
            println!("cargo:rerun-if-changed={}", path.to_string_lossy());

            let file_name = path
                .file_name()
                .expect("Generated src entry missing filename");

            dbg!(&path);
            dbg!(out_path.join(file_name));

            fs::write(out_path.join(file_name), fs::read(&path).unwrap()).unwrap();
        });

    dbg!(protobuf_location.join("rust"));
    dbg!(&protobuf_location);
}

fn bundle_licenses() {
    let manifest_dir = env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR not set");

    let out_dir = env::var("OUT_DIR").expect("NO OUT_DIR VARIABLE");
    let out = std::path::Path::new(&out_dir);
    let bundle_output_path = out.join("bundled_licenses.yaml");

    let output = Command::new("cargo")
        .args([
            "bundle-licenses",
            "-f",
            "yaml",
            "-o",
            bundle_output_path.to_str().unwrap(),
        ])
        .output()
        .expect("failed to run cargo bundle-licenses - is it installed?");

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        let stdout = String::from_utf8_lossy(&output.stdout);
        panic!(
            "cargo bundle-licenses failed with exit code: {}\nstdout: {}\nstderr: {}",
            output.status, stdout, stderr
        );
    }

    let license_src = env::var("LICENSE_PATH").map_or_else(
        |_| Path::new(&manifest_dir).join("../LICENSE"),
        PathBuf::from,
    );

    let license_content = read_to_string(license_src).expect("license couldn't be read!");

    let yaml_content = read_to_string(&bundle_output_path)
        .expect("Failed to read the generated licenses yaml file");

    let bundled: BundledLicenses =
        serde_yaml_ng::from_str(&yaml_content).expect("failed to parse licenses.yaml");

    let libs = &bundled.third_party_libraries;

    let short_content = generate_short(libs);

    let full_content = generate_full(libs);

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

        writeln!(out, "{branch} {}@{}", lib.package_name, lib.package_version).unwrap();

        if let Some(repository) = &lib.repository {
            writeln!(out, "{pipe} \u{251c}\u{2500} License: {}", lib.license).unwrap();
            writeln!(out, "{pipe} \u{2514}\u{2500} URL: {}", repository).unwrap();
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

        if let Some(repository) = &lib.repository {
            writeln!(
                out,
                "A copy of the source code may be downloaded from {}",
                repository
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

fn set_version() {
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
}
