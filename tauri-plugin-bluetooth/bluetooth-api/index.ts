import {invoke} from '@tauri-apps/api/core'

export async function echo(value: string): Promise<string | null> {
    return await invoke<{ value?: string }>('plugin:bluetooth|echo', {
        data: {
            value,
        },
    }).then((r) => (r.value ? r.value : null));
}

export async function start_scanning(): Promise<boolean> {
    return await invoke<{ success: boolean }>('plugin:bluetooth|start_scanning', {
        data: {}
    }).then((r) => r.success)
}

export async function stop_scanning(): Promise<boolean> {
    return await invoke<{ success: boolean }>('plugin:bluetooth|stop_scanning', {
        data: {}
    }).then((r) => r.success)
}

export async function set_passive_mode(passiveMode: boolean): Promise<boolean> {
    return await invoke<{ success: boolean }>('plugin:bluetooth|set_passive_mode', {
        passiveMode,
    }).then((r) => r.success)
}

export async function connect_device(identifier: string): Promise<boolean> {
    return await invoke<{ success: boolean }>('plugin:bluetooth|connect_device', {
        identifier,
    }).then((r) => r.success)
}

export async function disconnect_device(identifier: string): Promise<boolean> {
    return await invoke<{ success: boolean }>('plugin:bluetooth|disconnect_device', {
        identifier,
    }).then((r) => r.success)
}

export async function read_rssi(identifier: string): Promise<boolean> {
    return await invoke<{ success: boolean }>('plugin:bluetooth|read_rssi', {
        identifier,
    }).then((r) => r.success)
}
