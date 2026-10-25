use std::os::fd::{AsFd, AsRawFd};

use anyhow::Ok;
use ashpd::{
    desktop::{
        CreateSessionOptions, PersistMode, Session, SessionPortal,
        screencast::{CursorMode, Screencast, SelectSourcesOptions, SourceType},
    },
    enumflags2::BitFlags,
    zvariant::OwnedFd,
};
use futures_util::future;

use crate::recorder::{CaptureError, PortalCapture};

#[derive(Debug, Clone, Copy)]
pub enum SourceLostError {
    PermissionRevoked,
    NoFrames,
    SessionClosed,
}

pub enum Recoverable {
    Permanent,
    Temporary,
}

#[derive(Debug)]
pub enum Source {
    PipeWire {
        fd: OwnedFd,
        node_id: u32,
        session: Session<Screencast>,
        restore_token: Option<String>,
    },
    XImage {
        display_name: String,
    },
    AvfScreen {
        display_id: u32,
    },
    D3d11Screen {
        monitor: isize,
    },
}

impl Source {
    pub async fn wait_lost(&self) -> SourceLostError {
        match &self {
            Source::PipeWire {
                fd: _,
                node_id: _,
                session,
                restore_token: _,
            } => {
                let _ = session.receive_closed().await;
                return SourceLostError::SessionClosed;
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
            Source::PipeWire {
                fd,
                node_id,
                session,
                restore_token,
            } => todo!(),
            Source::AvfScreen { display_id: _ } => {
                todo!()
            }
            _ => Ok(Recoverable::Permanent),
        }
    }
}

pub async fn acquire_src() -> anyhow::Result<Source> {
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
        .await
        .map_err(|e| CaptureError::PortalFailed(e.to_string()))?
        .response()?;

    // there will never be multiple sources selecte
    let stream = response
        .streams()
        .first()
        .ok_or(CaptureError::PortalNoStream)?;

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
