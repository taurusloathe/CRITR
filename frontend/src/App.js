import React, { useState } from 'react';
import { ethers } from 'ethers';
import FactoryContract from './artifacts/contracts/FactoryContract.sol/FactoryContract.json';

const FACTORY_CONTRACT_ADDRESS = "YOUR_DEPLOYED_FACTORY_CONTRACT_ADDRESS";

function App({ provider, signer, account, connectWallet }) {
    const [tokenName, setTokenName] = useState("");
    const [tokenSymbol, setTokenSymbol] = useState("");
    const [initialSupply, setInitialSupply] = useState(0);

    const deployContracts = async () => {
        if (!signer) {
            alert("Please connect your wallet first.");
            return;
        }

        const factoryContract = new ethers.Contract(
            FACTORY_CONTRACT_ADDRESS,
            FactoryContract.abi,
            signer
        );

        try {
            const tx = await factoryContract.deployContracts(
                tokenName,
                tokenSymbol,
                ethers.utils.parseUnits(initialSupply.toString(), 18),
                "UNISWAP_ROUTER_ADDRESS",
                "WORMHOLE_ADDRESS",
                "SOLANA_CHAIN_ID",
                "UNISWAPX_ROUTER_ADDRESS",
                {
                    value: ethers.utils.parseEther("0.1") // Assuming it costs 0.1 ETH to deploy
                }
            );
            await tx.wait();
            alert("Contracts deployed successfully!");
        } catch (error) {
            console.error(error);
            alert("Error deploying contracts");
        }
    };

    return (
        <div>
            <h1>Deploy Your Own Token and Price Oracle</h1>
            {account ? (
                <div>
                    <p>Connected account: {account}</p>
                    <input
                        type="text"
                        placeholder="Token Name"
                        value={tokenName}
                        onChange={(e) => setTokenName(e.target.value)}
                    />
                    <input
                        type="text"
                        placeholder="Token Symbol"
                        value={tokenSymbol}
                        onChange={(e) => setTokenSymbol(e.target.value)}
                    />
                    <input
                        type="number"
                        placeholder="Initial Supply"
                        value={initialSupply}
                        onChange={(e) => setInitialSupply(e.target.value)}
                    />
                    <button onClick={deployContracts}>Deploy Contracts</button>
                </div>
            ) : (
                <button onClick={connectWallet}>Connect Wallet</button>
            )}
        </div>
    );
}

export default App;
