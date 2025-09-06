use crate::bridge;
use crate::bridge::{set_delegate, BLEDelegate, BluetoothApi, Device};
use once_cell::sync::OnceCell;
use serde::de::DeserializeOwned;
use std::ffi::{c_char, CStr, CString};
use std::fmt::Debug;
use tauri::{plugin::PluginApi, AppHandle, Runtime};

pub(crate) static GLOBAL_BLE_DELEGATE: OnceCell<Option<Box<dyn BLEDelegate>>> = OnceCell::new();

pub fn init<R: Runtime, C: DeserializeOwned, DELEGATE: BLEDelegate + Sized + 'static>(
    app: &AppHandle<R>,
    _api: PluginApi<R, C>,
    delegate: DELEGATE,
) -> crate::Result<Bluetooth<R>> {
    let bluetooth = Bluetooth(app.clone());

    unsafe {
        set_delegate(
            on_device_new,
            on_device_update,
            on_device_removed,
            on_rssi_updated,
            presence_update,
            bluetooth_power_warn,
        );
    }
    bluetooth.set_delegate(delegate);
    Ok(bluetooth)
}

/// Access to the bluetooth APIs.
pub struct Bluetooth<R: Runtime>(AppHandle<R>);

impl<R: Runtime> BluetoothApi<R> for Bluetooth<R> {
    fn echo(&self, value: String) -> String {
        unsafe {
            let value = CString::new(value.as_str()).unwrap();
            let ret = bridge::echo(value.as_ptr());
            CStr::from_ptr(ret).to_str().unwrap().to_string()
        }
    }

    fn initialize(&self) {
        unsafe {
            bridge::initialize();
        }
    }

    fn start_scanning(&self) -> bool {
        unsafe { bridge::start_scanning() }
    }

    fn stop_scanning(&self) -> bool {
        unsafe { bridge::stop_scanning() }
    }

    fn set_passive_mode(&self, mode: bool) {
        unsafe { bridge::set_passive_mode(mode) }
    }

    fn connect_device(&self, identifier: String) -> bool {
        unsafe {
            let value = CString::new(identifier.as_str()).unwrap();
            bridge::connect_device(value.as_ptr())
        }
    }

    fn disconnect_device(&self, identifier: String) -> bool {
        unsafe {
            let value = CString::new(identifier.as_str()).unwrap();
            bridge::disconnect_device(value.as_ptr())
        }
    }

    fn read_rssi(&self, identifier: String) {
        unsafe {
            let value = CString::new(identifier.as_str()).unwrap();
            bridge::read_rssi(value.as_ptr())
        }
    }

    fn set_delegate<DELEGATE>(&self, delegate: DELEGATE)
    where
        DELEGATE: BLEDelegate + Sized + 'static,
    {
        // binding the new bluetooth event delegate.
        let _ = GLOBAL_BLE_DELEGATE.set(Some(Box::new(delegate)));
    }
}

extern "C" fn on_device_new(
    uuid: *const c_char,
    manufacture: *const c_char,
    model: *const c_char,
    adv_data: i64,
    rssi: i32,
    mac_addr: *const c_char,
    bl_name: *const c_char,
    name: *const c_char,
    state: *const c_char,
) {
    let device = extract_device(
        uuid,
        manufacture,
        model,
        adv_data,
        rssi,
        mac_addr,
        bl_name,
        name,
        state,
    );
    if let Some(Some(delegate)) = GLOBAL_BLE_DELEGATE.get() {
        delegate.new_device(device)
    }
}

extern "C" fn on_device_update(
    uuid: *const c_char,
    manufacture: *const c_char,
    model: *const c_char,
    adv_data: i64,
    rssi: i32,
    mac_addr: *const c_char,
    bl_name: *const c_char,
    name: *const c_char,
    state: *const c_char,
) {
    let device = extract_device(
        uuid,
        manufacture,
        model,
        adv_data,
        rssi,
        mac_addr,
        bl_name,
        name,
        state,
    );
    if let Some(Some(delegate)) = GLOBAL_BLE_DELEGATE.get() {
        delegate.update_device(device)
    }
}

extern "C" fn on_device_removed(
    uuid: *const c_char,
    manufacture: *const c_char,
    model: *const c_char,
    adv_data: i64,
    rssi: i32,
    mac_addr: *const c_char,
    bl_name: *const c_char,
    name: *const c_char,
    state: *const c_char,
) {
    let device = extract_device(
        uuid,
        manufacture,
        model,
        adv_data,
        rssi,
        mac_addr,
        bl_name,
        name,
        state,
    );
    if let Some(Some(delegate)) = GLOBAL_BLE_DELEGATE.get() {
        delegate.remove_device(device)
    }
}

extern "C" fn on_rssi_updated(rssi: i32, estimated_rssi: i32, active: bool) {
    if let Some(Some(delegate)) = GLOBAL_BLE_DELEGATE.get() {
        delegate.update_rssi(rssi, estimated_rssi, active);
    }
}

extern "C" fn presence_update(presence: bool, reason: *const c_char) {
    if let Some(Some(delegate)) = GLOBAL_BLE_DELEGATE.get() {
        unsafe {
            if !reason.is_null() {
                let reason_val = take_string(reason);
                delegate.update_presence(presence, reason_val);
            }
        }
    }
}

extern "C" fn bluetooth_power_warn() {
    if let Some(Some(delegate)) = GLOBAL_BLE_DELEGATE.get() {
        delegate.bluetooth_power_warn();
    }
}

/// 把 `*const c_char` 转成 Rust String，并在转换后释放内存
unsafe fn take_string(ptr: *const c_char) -> String {
    if ptr.is_null() {
        return String::new();
    }
    // 只读取，不接管所有权
    CStr::from_ptr(ptr).to_string_lossy().into_owned()
}

fn extract_device(
    uuid: *const c_char,
    manufacture: *const c_char,
    model: *const c_char,
    adv_data: i64,
    rssi: i32,
    mac_addr: *const c_char,
    bl_name: *const c_char,
    name: *const c_char,
    state: *const c_char,
) -> Device {
    unsafe {
        let uuid = take_string(uuid);
        let manufacture = take_string(manufacture);
        let model = take_string(model);
        let mac_addr = take_string(mac_addr);
        let bl_name = take_string(bl_name);
        let name = take_string(name);
        let state = take_string(state);
        let device = Device {
            uuid,
            manufacture: (!manufacture.is_empty()).then_some(manufacture),
            model: (!model.is_empty()).then_some(model),
            adv_data,
            rssi,
            mac_addr: (!mac_addr.is_empty()).then_some(mac_addr),
            bl_name: (!bl_name.is_empty()).then_some(bl_name),
            name: (!name.is_empty()).then_some(name),
            state: (!state.is_empty()).then_some(state),
        };
        device
    }
}
