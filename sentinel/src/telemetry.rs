// TODO: put in actual DSN string
const DSN: &str = "replaceme";

pub fn init() -> sentry::ClientInitGuard {
    sentry::init((
        DSN,
        sentry::ClientOptions {
            release: Some(format!("franklyn-sentinel@{}", crate::VERSION).into()),
            environment: Some(
                if cfg!(debug_assertions) {
                    "development"
                } else {
                    "production"
                }
                .into(),
            ),
            ..Default::default()
        },
    ))
}
