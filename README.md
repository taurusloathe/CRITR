# CRITR
A savings app for the disabled under construction that increases exponentially in value upon deposits after deposit of 0.06 ETH
![Polish_20240225_192414755](https://github.com/taurusloathe/CRITR-Token/assets/110080228/2343bf36-819d-4651-b169-b8cdf7caa281)
The app deploys a factory smart contract that deploys both a token contract and a price oracle contract for that token simultaneously. Before deployment, the app user will be able to customize the name of their savings token in the apps user interface, then the app will deploy their token to the ETH blockchain, allowing for the app user to purchase their own tokens.
The app user can exchange their tokens for Ethereum, or any ERC-20 based token in Uniswap.
# How it works:
The token contract that is deployed by users leverages an exponential bonding curve with a divisor of 500 that raises the price of the users' token. Everytime the user adds more to their account (buys more of their own token), their initial deposit value increases exponentially.
![1000021157](https://github.com/taurusloathe/CRITR-App/assets/110080228/89333138-ea05-4375-882e-0dc6ee6f522f)

Run the provided python file 'token_price_calculator.py' to calculate how many of your tokens to purchase to reach your personal price target.

![1000021158](https://github.com/taurusloathe/CRITR-App/assets/110080228/550a48a7-40be-4884-980e-2a33c60f2981)

# Updates:
# Cross-Chain Bridge
The constructor of the token contract deployed from the factory contract will initialize the Wormhole bridge contract and the Solana chain ID, allowing users to exchange the token they deploy for Solana.
![1000021177](https://github.com/taurusloathe/CRITR/assets/110080228/56657172-296f-4344-9a81-97efa5ee4c28)
![1000021176](https://github.com/taurusloathe/CRITR/assets/110080228/d6074f4f-1711-4758-ab17-506e6e4b1d30)
![1000021087](https://github.com/taurusloathe/CRITR/assets/110080228/19785f67-b96e-4399-b269-142db193ee4f)

# UniswapX Protocol Integration
UniswapX aggregates both onchain and offchain liquidity, internalizes MEV in the form of price improvement, offers gas-free swaps, and can be extended to support cross-chain trading. You can access the full UniswapX whitepaper here: https://uniswap.org/whitepaper-uniswapx.pdf
![1000021092](https://github.com/taurusloathe/CRITR/assets/110080228/eb2373df-92d0-493a-b6a8-ff8c47d758b1)
