fn main() {
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
