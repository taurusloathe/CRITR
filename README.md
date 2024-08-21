# CRITR
A savings app under construction that is restricted to individuals whose income is under $100,000 per year. Your savings increase exponentially in value upon deposits after deposit of 0.06 ETH. The deposit covers the cost to deploy your token contracts.
![1000025075](https://github.com/user-attachments/assets/353673fb-89fc-4527-9603-692692aaaa61)

The app deploys a factory smart contract that deploys both a token contract and a price oracle contract for that token simultaneously. Before deployment, the app user will be able to customize the name of their savings token in the apps user interface, then the app will deploy their token to the ETH blockchain, allowing for the app user to purchase their own tokens.
The app user can exchange their tokens gas-free for any token in Uniswap.
# How it works:
Only the app user has access to the contract controls and their custom token. The token contract that is deployed by users leverages an exponential bonding curve with a divisor of 500 that raises the value of the users' token. Everytime the user adds more to their account (buys more of their own token), their initial deposit value increases exponentially.

![1000021199](https://github.com/taurusloathe/CRITR/assets/110080228/7d098885-6b08-424c-b15d-330a66b70031)

Your token starts at 0.00001 ETH (approx. $0.03) per token. You can get up to 6,000 tokens at this initial price. Use the Token Price Calculator to calculate how many of your tokens to purchase after initial deposit to reach your personal price target.

![1000021235](https://github.com/taurusloathe/CRITR/assets/110080228/5cf8dae3-e3e9-41d0-b372-bdc3caac9596)

Example:

![1000021242](https://github.com/taurusloathe/CRITR/assets/110080228/40a12549-2fe6-4789-819c-ddeab8a84bdf)

Wormhole SDK Integration for gasless swaps across a variety of blockchains:
![1000021200](https://github.com/taurusloathe/CRITR/assets/110080228/642bcfd2-991c-463d-a192-0150a6a534c5)
![1000021208](https://github.com/taurusloathe/CRITR/assets/110080228/9bdebcf2-9086-4f27-94bc-c5f3ea31864f)

# Updates:
# Wormhole SDK Cross-Chain Bridge Integration 
The constructor of the token contract deployed from the factory contract will initialize the Wormhole bridge contract and the Solana chain ID, allowing users to exchange the token they deploy for Solana and other tokens. 
https://www.npmjs.com/package/@certusone/wormhole-sdk
![1000021087](https://github.com/taurusloathe/CRITR/assets/110080228/0c2886e8-6534-447f-b7de-8a764e1d8b58)
![1000021176](https://github.com/taurusloathe/CRITR/assets/110080228/899ba30d-1dd5-4213-9fc2-f2c69b7a9390)
![1000021177](https://github.com/taurusloathe/CRITR/assets/110080228/71329df7-a7db-4d0d-b410-88bfef3df253)

# UniswapX Protocol Integration
UniswapX aggregates both onchain and offchain liquidity, internalizes MEV in the form of price improvement, offers gas-free swaps, and can be extended to support cross-chain trading. You can access the full UniswapX whitepaper here: https://uniswap.org/whitepaper-uniswapx.pdf
![1000021092](https://github.com/taurusloathe/CRITR/assets/110080228/eb2373df-92d0-493a-b6a8-ff8c47d758b1)
