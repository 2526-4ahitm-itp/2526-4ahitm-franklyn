const DSN: &str =
    "https://de9d7c4114ec43b0897ec196d688f51a@franklyn.htl-leonding.ac.at/glitchtip/1";

pub fn init() -> sentry::ClientInitGuard {
    let options = sentry::ClientOptions {
        release: Some(format!("franklyn-sentinel@{}", crate::VERSION).into()),
        environment: Some(
            if cfg!(debug_assertions) {
                "development"
            } else {
                "production"
            }
            .into(),
        ),
        enable_logs: true,
        ..Default::default()
    };

    sentry::init((DSN, options))
}
