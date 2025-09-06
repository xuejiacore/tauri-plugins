import {useEffect, useRef} from "react";
import {Event, EventName, listen, Options, UnlistenFn} from "@tauri-apps/api/event";
import {DragDropEvent, getCurrentWebview} from "@tauri-apps/api/webview";

export type Callback<T> = (event: Event<T>, listenerId?: number) => void;

export function useEvent<T>(event: EventName, handler: Callback<T>, options?: Options) {
    const unlistenFnRef = useRef<UnlistenFn>();
    const effectListenId = useRef(0);
    useEffect(() => {
        const currentListenId = Date.now() + Math.random() * 1000;
        effectListenId.current = currentListenId;

        listen<T>(event, event => {
            handler(event, currentListenId);
        }, options).then((unlistenFn: UnlistenFn) => {
            if (effectListenId.current === currentListenId) {
                // listener id never changed.
                unlistenFnRef.current = unlistenFn;
            } else {
                // invalidate listener. deconstruct it.
                unlistenFn();
            }
        });

        return () => {
            if (unlistenFnRef.current) {
                unlistenFnRef.current();
                unlistenFnRef.current = undefined;
            }
        };
    }, []);
}

export function useDragDrop(callback: (event: DragDropEvent) => void) {
    const unlistenFnRef = useRef<UnlistenFn>();
    const effectListenId = useRef(0);

    useEffect(() => {
        const currentListenId = Date.now() + Math.random() * 1000;
        effectListenId.current = currentListenId;
        getCurrentWebview().onDragDropEvent((event) => {
            callback(event.payload);
        }).then((unlistenFn: UnlistenFn) => {
            if (effectListenId.current === currentListenId) {
                // listener id never changed.
                unlistenFnRef.current = unlistenFn;
            } else {
                // invalidate listener. deconstruct it.
                unlistenFn();
            }
        });

        return () => {
            if (unlistenFnRef.current) {
                unlistenFnRef.current();
                unlistenFnRef.current = undefined;
            }
        };
    });
}