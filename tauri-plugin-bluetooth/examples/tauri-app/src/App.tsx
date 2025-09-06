import "./App.css";
import {
    connect_device,
    disconnect_device,
    read_rssi,
    set_passive_mode,
    start_scanning,
    stop_scanning
} from "../../../bluetooth-api";

function App() {

    async function startScan() {
        await start_scanning().finally();
    }

    async function stopScan() {
        await stop_scanning().finally()
    }

    async function setPassiveMode(mode: boolean) {
        await set_passive_mode(mode).finally();
    }

    return (
        <main className="container">
            <h1>Demo of Bluetooth Plug</h1>
            <button type="submit" onClick={() => startScan().finally()}>Start Scan</button>
            <button type="submit" onClick={() => stopScan().finally()}>Stop Scan</button>
            <button type="submit" onClick={() => setPassiveMode(true).finally()}>PassiveMode</button>
            <button type="submit" onClick={() => setPassiveMode(false).finally()}>ActiveMode</button>
            <button type="submit" onClick={() => read_rssi("E337A089-2E40-C91B-9153-869A90FFA727").finally()}>ReadRssi
            </button>
            <button type="submit"
                    onClick={() => connect_device("E337A089-2E40-C91B-9153-869A90FFA727").finally()}>Connect
            </button>
            <button type="submit"
                    onClick={() => disconnect_device("E337A089-2E40-C91B-9153-869A90FFA727").finally()}>Disconnect
            </button>
        </main>
    );
}

export default App;
