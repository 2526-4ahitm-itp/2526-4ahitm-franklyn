use std::env;

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

#[derive(Debug, Clone, Copy)]
pub enum SourceLostError {
    PermissionRevoked,
    NoFrames,
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

    pub async fn reacquire(&mut self) -> anyhow::Result<Recoverable> {
        match self {
            Self::PipeWire { .. } => todo!(),
            Self::AvfScreen => {
                todo!()
            }
            _ => Ok(Recoverable::Permanent),
        }
    }

    pub async fn make() -> anyhow::Result<Self> {
        match Self::detect_backend()? {
            Backend::Wayland => get_portal_capture_source().await,
            Backend::X11 => Ok(Self::XImage),
            Backend::Quartz => {
                ensure_capture_permission()?;
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
        .response()?;

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
