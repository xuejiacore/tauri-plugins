use serde::{Deserialize, Serialize};
use std::ffi::c_char;
use std::fmt::Debug;
use tauri::Runtime;

///  Describe the bluetooth device.
#[derive(Debug, Serialize, Deserialize)]
pub struct Device {
    pub(crate) uuid: String,
    pub(crate) manufacture: Option<String>,
    pub(crate) model: Option<String>,
    pub(crate) adv_data: i64,
    pub(crate) rssi: i32,
    pub(crate) mac_addr: Option<String>,
    pub(crate) bl_name: Option<String>,
    pub(crate) name: Option<String>,
    pub(crate) state: Option<String>,
}

pub trait BLEDelegate: Send + Sync {
    fn new_device(&self, device: Device);
    fn update_device(&self, device: Device);
    fn remove_device(&self, device: Device);
    fn update_rssi(&self, rssi: i32, estimated_rssi: i32, active: bool);
    fn update_presence(&self, presence: bool, reason: String);
    fn bluetooth_power_warn(&self);
}

pub type NativeDeviceDelegate = extern "C" fn(
    uuid: *const c_char,
    manufacture: *const c_char,
    model: *const c_char,
    adv_data: i64,
    rssi: i32,
    mac_addr: *const c_char,
    bl_name: *const c_char,
    name: *const c_char,
    state: *const c_char,
);
pub type NativeRssiUpdateDelegate = extern "C" fn(rssi: i32, estimated_rssi: i32, active: bool);
pub type NativeUpdatePresence = extern "C" fn(presence: bool, reason: *const c_char);
pub type NativeBluetoothPowerWarnHandler = extern "C" fn();

extern "C" {
    pub(crate) fn echo(value: *const c_char) -> *const c_char;

    pub(crate) fn initialize();

    pub(crate) fn start_scanning() -> bool;

    pub(crate) fn stop_scanning() -> bool;

    pub(crate) fn set_passive_mode(mode: bool);

    pub(crate) fn connect_device(identifier: *const c_char) -> bool;

    pub(crate) fn disconnect_device(identifier: *const c_char) -> bool;

    pub(crate) fn read_rssi(identifier: *const c_char);

    pub(crate) fn set_delegate(
        on_device_new: NativeDeviceDelegate,
        on_device_update: NativeDeviceDelegate,
        on_device_removed: NativeDeviceDelegate,
        on_rssi_updated: NativeRssiUpdateDelegate,
        presence_updated: NativeUpdatePresence,
        bluetooth_power_warn: NativeBluetoothPowerWarnHandler,
    );
}

pub(crate) trait BluetoothApi<R: Runtime> {
    fn echo(&self, value: String) -> String;

    fn initialize(&self);

    fn start_scanning(&self) -> bool;

    fn stop_scanning(&self) -> bool;

    fn set_passive_mode(&self, mode: bool);

    fn connect_device(&self, identifier: String) -> bool;

    fn disconnect_device(&self, identifier: String) -> bool;

    fn read_rssi(&self, identifier: String);

    fn set_delegate<DELEGATE>(&self, delegate: DELEGATE)
    where
        DELEGATE: BLEDelegate + Sized + 'static;
}
