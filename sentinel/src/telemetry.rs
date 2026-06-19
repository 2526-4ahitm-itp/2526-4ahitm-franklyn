// TODO: put in actual DSN string
const DSN: &str = "replaceme";

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
