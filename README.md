# CRITR
A savings app under construction that is restricted to individuals whose income is under $100,000 per year. Your savings is stored in the form of your own customizable ETH-based token, and the value increases exponentially upon deposits after an initial deposit of 0.06 ETH.

![1000025788](https://github.com/user-attachments/assets/fcae97ad-d167-42a7-8710-a7f4d0c6da12)

Income verification is determined through the WealthEngine API when the user provides their email address. Once user passes eligibility, the app will allow the user to deploy a factory smart contract that deploys both a token contract and a price oracle contract for that token simultaneously. Before deployment, the app user will be able to customize the name of their savings token in the apps user interface, then the app will deploy their token to the ETH blockchain, allowing for the app user to purchase their own tokens.
The app user can exchange their tokens gas-free for any token in Uniswap.
# How it works:
Only the app user has access to the contract controls and their custom token. The token contract that is deployed by users leverages an exponential bonding curve with a divisor of 500 that raises the value of the users' token. Everytime the user adds more to their account (buys more of their own token), their initial deposit value increases exponentially.

![1000025789](https://github.com/user-attachments/assets/35bd777f-9b36-402b-ade4-5abf4f508d7d)

Your token starts at 0.00001 ETH (approx. $0.03) per token. You can get up to 6,000 tokens at this initial price. Use the Token Price Calculator to calculate how many of your tokens to purchase after initial deposit to reach your personal price target.

Example:

![1000021242](https://github.com/taurusloathe/CRITR/assets/110080228/40a12549-2fe6-4789-819c-ddeab8a84bdf)

# UniswapX Protocol Integration
CRITR has built in UniswapX compatibility. UniswapX aggregates both onchain and offchain liquidity, internalizes MEV in the form of price improvement, offers gas-free swaps, and can be extended to support cross-chain trading. You can access the full UniswapX whitepaper here: https://uniswap.org/whitepaper-uniswapx.pdf
![1000021092](https://github.com/taurusloathe/CRITR/assets/110080228/eb2373df-92d0-493a-b6a8-ff8c47d758b1)
