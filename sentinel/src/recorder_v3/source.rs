use std::env;

use anyhow::Context;
use anyhow::{Ok, Result, anyhow};
#[cfg(all(unix, not(target_os = "macos")))]
use ashpd::{
    desktop::{
        CreateSessionOptions, PersistMode, Session,
        screencast::{CursorMode, Screencast, SelectSourcesOptions, SourceType},
    },
    enumflags2::BitFlags,
    zvariant::OwnedFd,
};
use gstreamer::{Element, ElementFactory};
#[cfg(all(unix, not(target_os = "macos")))]
use std::os::fd::AsRawFd;

#[derive(Debug, Clone, Copy)]
pub enum SourceLostError {
    PermissionRevoked,
    SessionClosed,
}

#[derive(Debug, Clone, Copy)]
pub enum Recoverable {
    Permanent,
    Temporary,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Backend {
    X11,
    Wayland,
    Quartz,
    Windows,
}

#[derive(Debug)]
pub enum Source {
    #[cfg(all(unix, not(target_os = "macos")))]
    PipeWire {
        fd: OwnedFd,
        node_id: u32,
        session: Session<Screencast>,
        restore_token: Option<String>,
    },
    XImage,
    AvfScreen,
    D3d11Screen,
}

impl Source {
    pub async fn wait_lost(&self) -> SourceLostError {
        match &self {
            #[cfg(all(unix, not(target_os = "macos")))]
            Self::PipeWire {
                fd: _,
                node_id: _,
                session,
                restore_token: _,
            } => {
                let _ = session.receive_closed().await;
                SourceLostError::SessionClosed
            }
            _ => {
                let future = std::future::pending();
                let () = future.await;
                unreachable!("cannot reach after std::future::pending().await!")
            }
        }
    }

    pub fn make_element(&self) -> Result<Element> {
        match self {
            #[cfg(all(unix, not(target_os = "macos")))]
            Source::PipeWire {
                fd,
                node_id,
                session: _,
                restore_token: _,
            } => ElementFactory::make("pipewiresrc")
                .property("fd", fd.as_raw_fd())
                .property("path", format!("{}", node_id))
                .property("min-buffers", 1i32)
                .property("do-timestamp", true)
                .property("always-copy", true)
                .build()
                .context("failed to create pipewiresrc"),
            #[cfg(target_os = "macos")]
            Source::AvfScreen => ElementFactory::make("avfvideosrc")
                .property("capture-screen", true)
                .property("capture-screen-cursor", true)
                .property("do-timestamp", true)
                .build()
                .context("failed to create avfvideosrc"),
            #[cfg(target_os = "windows")]
            Source::D3d11Screen => ElementFactory::make("d3d11screencapturesrc")
                .property("show-cursor", true)
                .property("do-timestamp", true)
                .build()
                .context("failed to create d3d11screencapturesrc"),
            #[cfg(all(unix, not(target_os = "macos")))]
            Source::XImage => ElementFactory::make("ximagesrc")
                .property("use-damage", false)
                .property("show-pointer", true)
                .property("do-timestamp", true)
                .build()
                .context("failed to create ximagesrc"),
            source => {
                return Err(anyhow!(
                    "\"{}\" capture is not supported on platform \"{}\"",
                    match source {
                        #[cfg(all(unix, not(target_os = "macos")))]
                        Source::PipeWire { .. } => "Wayland",
                        Source::XImage => "Xorg",
                        Source::AvfScreen => "MacOS",
                        Source::D3d11Screen => "Windows",
                    },
                    std::env::consts::OS
                ));
            }
        }
    }

    pub async fn reacquire(&mut self) -> anyhow::Result<Recoverable> {
        match self {
            #[cfg(all(unix, not(target_os = "macos")))]
            Self::PipeWire { .. } => todo!(),
            Self::AvfScreen => {
                todo!()
            }
            _ => Ok(Recoverable::Permanent),
        }
    }

    pub async fn make() -> anyhow::Result<Self> {
        match Self::detect_backend()? {
            #[cfg(all(unix, not(target_os = "macos")))]
            Backend::Wayland => get_portal_capture_source().await,
            #[cfg(not(all(unix, not(target_os = "macos"))))]
            Backend::Wayland => Err(anyhow!(
                "Wayland capture is not supported on platform \"{}\"",
                std::env::consts::OS
            )),
            Backend::X11 => Ok(Self::XImage),
            Backend::Quartz => {
                ensure_capture_permission().map_err(|_| {
                    anyhow!(
                        "Screen Recording permission is missing. Allow your
                        terminal app under System Settings → Privacy & \
                        Security → Screen & System Audio Recording, \
                        restart the terminal, then run the command again"
                    )
                })?;
                Ok(Self::AvfScreen)
            }
            Backend::Windows => Ok(Self::D3d11Screen),
        }
    }

    fn detect_backend() -> anyhow::Result<Backend> {
        if cfg!(target_os = "windows") {
            return Ok(Backend::Windows);
        }

        if cfg!(target_os = "macos") {
            return Ok(Backend::Quartz);
        }

        if env::var("WAYLAND_DISPLAY").is_ok()
            || matches!(
                env::var("XDG_SESSION_TYPE").as_deref(),
                Result::Ok("wayland")
            )
        {
            Ok(Backend::Wayland)
        } else if env::var("DISPLAY").is_ok() {
            Ok(Backend::X11)
        } else {
            Err(anyhow!("Failed to detect backend"))
        }
    }
}

#[cfg(all(unix, not(target_os = "macos")))]
pub async fn get_portal_capture_source() -> anyhow::Result<Source> {
    let proxy = Screencast::new().await?;

    let session = proxy
        .create_session(CreateSessionOptions::default())
        .await?;

    proxy
        .select_sources(
            &session,
            SelectSourcesOptions::default()
                // TODO: if cursor is not supported, do not fail or just don't get the cursor
                .set_cursor_mode(CursorMode::Embedded)
                .set_sources(BitFlags::from_flag(SourceType::Monitor))
                .set_multiple(false)
                .set_persist_mode(PersistMode::ExplicitlyRevoked),
        )
        .await?;

    let response = proxy
        .start(&session, None, Default::default())
        .await?
        .response()
        .map_err(|e| {
            let msg = e.to_string();
            if msg.to_lowercase().contains("cancel") {
                anyhow!("XDG portal dialog was cancelled by the user")
            } else {
                anyhow::Error::from(e)
            }
        })?;

    // there will never be multiple sources selecte
    let stream = response
        .streams()
        .first()
        .ok_or(anyhow!("failed to get stream of portal capture"))?;

    let fd = proxy
        .open_pipe_wire_remote(&session, Default::default())
        .await?;

    Ok(Source::PipeWire {
        fd: fd.into(),
        node_id: stream.pipe_wire_node_id(),
        restore_token: response.restore_token().map(|o| o.to_string()),
        session,
    })
}

#[cfg(target_os = "macos")]
pub fn ensure_capture_permission() -> anyhow::Result<()> {
    #[link(name = "CoreGraphics", kind = "framework")]
    unsafe extern "C" {
        fn CGPreflightScreenCaptureAccess() -> bool;
        fn CGRequestScreenCaptureAccess() -> bool;
    }

    if unsafe { CGPreflightScreenCaptureAccess() } {
        return Ok(());
    }

    unsafe { CGRequestScreenCaptureAccess() };
    Err(anyhow!("macos capture denied!"))
}

#[cfg(not(target_os = "macos"))]
pub const fn ensure_capture_permission() -> Result<()> {
    anyhow::Result::Ok(())
}
