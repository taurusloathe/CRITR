import React, { useEffect, useState } from 'react';
import ReactDOM from 'react-dom';
import App from './App';
import Web3Modal from 'web3modal';

const AppWrapper = () => {
    const [provider, setProvider] = useState(null);
    const [signer, setSigner] = useState(null);
    const [account, setAccount] = useState(null);

    const connectWallet = async () => {
        const web3Modal = new Web3Modal({
            cacheProvider: true, // optional
            providerOptions: {} // required
        });
        const instance = await web3Modal.connect();
        const library = new ethers.providers.Web3Provider(instance);
        const signer = library.getSigner();
        const account = await signer.getAddress();
        setProvider(library);
        setSigner(signer);
        setAccount(account);
    };

    return <App provider={provider} signer={signer} account={account} connectWallet={connectWallet} />;
};

ReactDOM.render(
    <React.StrictMode>
        <AppWrapper />
    </React.StrictMode>,
    document.getElementById('root')
);
