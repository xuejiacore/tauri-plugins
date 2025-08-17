import {invoke} from '@tauri-apps/api/core'

export async function echo(value: string): Promise<string | null> {
    return await invoke<{ value?: string }>('plugin:bluetooth|echo', {
        data: {
            value,
        },
    }).then((r) => (r.value ? r.value : null));
}

export async function connect(): Promise<boolean> {
    return await invoke<{ success: boolean }>('plugin:bluetooth|connect', {
        data: {}
    }).then((r) => r.success)
}