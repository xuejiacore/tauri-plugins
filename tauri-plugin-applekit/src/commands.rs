use tauri::{AppHandle, command, Runtime};

use crate::models::*;
use crate::Result;
use crate::ApplekitExt;

#[command]
pub(crate) async fn ping<R: Runtime>(
    app: AppHandle<R>,
    payload: PingRequest,
) -> Result<PingResponse> {
    app.applekit().ping(payload)
}
