use crate::bridge::BluetoothApi;
use crate::models::*;
use crate::BluetoothExt;
use crate::Result;
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
pub(crate) async fn start_scanning<R: Runtime>(
    app: AppHandle<R>,
    data: ConnectConf,
) -> Result<ConnectResp> {
    let success = app.bluetooth().start_scanning();
    Ok(ConnectResp { success })
}

#[command]
pub(crate) async fn stop_scanning<R: Runtime>(
    app: AppHandle<R>,
    data: ConnectConf,
) -> Result<ConnectResp> {
    let success = app.bluetooth().stop_scanning();
    Ok(ConnectResp { success })
}

#[command]
pub(crate) async fn set_passive_mode<R: Runtime>(
    app: AppHandle<R>,
    passive_mode: bool,
) -> Result<ConnectResp> {
    app.bluetooth().set_passive_mode(passive_mode);
    Ok(ConnectResp { success: true })
}

#[command]
pub(crate) async fn connect_device<R: Runtime>(
    app: AppHandle<R>,
    identifier: String,
) -> Result<ConnectResp> {
    app.bluetooth().connect_device(identifier);
    Ok(ConnectResp { success: true })
}

#[command]
pub(crate) async fn disconnect_device<R: Runtime>(
    app: AppHandle<R>,
    identifier: String,
) -> Result<ConnectResp> {
    app.bluetooth().disconnect_device(identifier);
    Ok(ConnectResp { success: true })
}

#[command]
pub(crate) async fn read_rssi<R: Runtime>(
    app: AppHandle<R>,
    identifier: String,
) -> Result<ConnectResp> {
    app.bluetooth().read_rssi(identifier);
    Ok(ConnectResp { success: true })
}
