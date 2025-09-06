use crate::ApplekitExt;
use crate::Result;
use tauri::{command, AppHandle, Runtime};

#[command]
pub(crate) async fn set_user_default<R: Runtime>(
    app: AppHandle<R>,
    key: String,
    value: String,
) -> Result<()> {
    let applekit = app.applekit();
    applekit.set_user_default(key, value)
}

#[command]
pub(crate) async fn get_user_default<R: Runtime>(
    app: AppHandle<R>,
    key: String,
) -> Result<Option<String>> {
    let applekit = app.applekit();
    applekit.get_user_default(key)
}
