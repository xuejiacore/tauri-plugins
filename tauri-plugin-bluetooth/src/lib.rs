use tauri::{
    plugin::{Builder, TauriPlugin},
    Manager, Runtime,
};

pub use models::*;

#[cfg(desktop)]
mod desktop;
#[cfg(mobile)]
mod mobile;

pub mod bridge;
mod commands;
mod error;
mod models;

pub use error::{Error, Result};

use crate::bridge::{BLEDelegate, BluetoothApi};
use crate::commands::{set_passive_mode, start_scanning, stop_scanning, connect_device, disconnect_device, read_rssi};
#[cfg(desktop)]
use desktop::Bluetooth;
#[cfg(mobile)]
use mobile::Bluetooth;

/// Extensions to [`tauri::App`], [`tauri::AppHandle`] and [`tauri::Window`] to access the bluetooth APIs.
pub trait BluetoothExt<R: Runtime> {
    fn bluetooth(&self) -> &Bluetooth<R>;
}

impl<R: Runtime, T: Manager<R>> crate::BluetoothExt<R> for T {
    fn bluetooth(&self) -> &Bluetooth<R> {
        self.state::<Bluetooth<R>>().inner()
    }
}

/// Initializes the plugin.
pub fn init<R: Runtime, DELEGATE: BLEDelegate + 'static>(delegate: DELEGATE) -> TauriPlugin<R> {
    Builder::new("bluetooth")
        .invoke_handler(tauri::generate_handler![
            start_scanning,
            stop_scanning,
            set_passive_mode,
            connect_device,
            disconnect_device,
            read_rssi,
        ])
        .setup(|app, api| {
            #[cfg(mobile)]
            let bluetooth = mobile::init(app, api)?;
            #[cfg(desktop)]
            let bluetooth = desktop::init(app, api, delegate)?;
            bluetooth.initialize();
            app.manage(bluetooth);
            Ok(())
        })
        .build()
}
