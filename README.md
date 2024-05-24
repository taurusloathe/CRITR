# CRITR App - Invest in yourself!
A savings app for the disabled under construction that increases exponentially in value upon deposits after deposit of 0.06 ETH
![Polish_20240225_192414755](https://github.com/taurusloathe/CRITR-Token/assets/110080228/2343bf36-819d-4651-b169-b8cdf7caa281)
The app deploys a factory smart contract that deploys both a token contract and a price oracle contract for that token simultaneously. Before deployment, the app user will be able to customize the name of their savings token in the apps user interface, then the app will deploy their token to the ETH blockchain, allowing for the app user to purchase their own tokens.
The app user can exchange their tokens for Ethereum, or any ERC-20 based token in Uniswap.
# How it works:
The token contract that is deployed by users leverages an exponential bonding curve with a divisor of 500 that raises the price of the users' token. Everytime the user adds more to their account (buys more of their own token), their initial deposit value increases exponentially.
# Updates:
# Cross-Chain Bridge
The constructor of the token contract deployed deployed from the factory contract now initializes the Wormhole bridge contract and the Solana chain ID, allowing users to exchange the token they deploy for Solana.
# UniswapX Protocol Integration
UniswapX aggregates both onchain and offchain liquidity, internalizes MEV in the form of price improvement, offers gas-free swaps, and can be extended to support cross-chain trading. You can access the full UniswapX whitepaper here: https://uniswap.org/whitepaper-uniswapx.pdf
