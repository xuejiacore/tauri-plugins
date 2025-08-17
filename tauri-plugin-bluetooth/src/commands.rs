use crate::bridge::BluetoothApi;
use crate::models::*;
use crate::Result;
use crate::BluetoothExt;
use tauri::{command, AppHandle, Runtime};

#[command]
pub(crate) async fn echo<R: Runtime>(app: AppHandle<R>, data: EchoReq) -> Result<EchoResp> {
    let val = data.value.unwrap_or(String::default());
    let response = app.bluetooth().echo(val);
    Ok(EchoResp {
        value: Some(response),
    })
}

#[command]
pub(crate) async fn connect<R: Runtime>(
    app: AppHandle<R>,
    data: ConnectConf,
) -> Result<ConnectResp> {
    let success = app.bluetooth().connect();
    Ok(ConnectResp { success })
}
