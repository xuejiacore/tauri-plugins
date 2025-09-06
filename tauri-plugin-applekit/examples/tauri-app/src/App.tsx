import "./App.css";
import {useEffect} from "react";
import {get, set} from "../../../applekit-api";

function App() {

    useEffect(() => {
        get('testkey').then(_ => {
        })

        set("testkey", "testvalue").then(_ => {
            get('testkey').then(_ => {
            })
        });
    }, []);

    return (
        <main className="container">
            <h1>Demo of AppletKit Plug</h1>
        </main>
    );
}

export default App;
