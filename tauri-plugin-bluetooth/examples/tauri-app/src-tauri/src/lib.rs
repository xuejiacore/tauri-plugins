use tauri_plugin_bluetooth::bridge::{BLEDelegate, Device};

// Learn more about Tauri commands at https://v2.tauri.app/develop/calling-rust/#commands
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

pub(crate) struct BluetoothDelegate;

impl BluetoothDelegate {
    fn new() -> Self {
        BluetoothDelegate
    }
}

impl BLEDelegate for BluetoothDelegate {
    fn new_device(&self, device: Device) {
        println!("New device: {:?}", device);
    }

    fn update_device(&self, device: Device) {
        //println!("Updated device: {:?}", device);
    }

    fn remove_device(&self, device: Device) {
        //println!("Removed device: {:?}", device);
    }

    fn update_rssi(&self, rssi: i32, estimated_rssi: i32, active: bool) {
        println!("应用层收到更新 {}, {}, {}", rssi, estimated_rssi, active);
    }

    fn update_presence(&self, presence: bool, reason: String) {
        println!("应用层 update_presence {}, {}", presence, reason);
    }

    fn bluetooth_power_warn(&self) {
        println!("应用层 bluetooth_power_warn");
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let delegate = BluetoothDelegate::new();
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![greet])
        .plugin(tauri_plugin_bluetooth::init(delegate))
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
