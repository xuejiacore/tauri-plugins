import "./App.css";
import {connect} from "../../../bluetooth-api";
import {useState} from "react";

function App() {

    const [echoValue, setEchoValue] = useState<string | null>('');

    async function tryEcho() {
        await connect().then(r => {
            setEchoValue(`connected:${r}`);
        });
    }

    return (
        <main className="container">
            <h1>Example for Bluetooth Plugin</h1>

            <form
                className="row"
                onSubmit={(e) => {
                    e.preventDefault();
                    tryEcho().finally();
                }}>
                <input
                    id="greet-input"
                    placeholder="Echo value"
                />
                <button type="submit">Test Echo</button>

            </form>
            <p>{echoValue}</p>
        </main>
    );
}

export default App;
