// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CRITR is ERC20 {
    uint256 public constant INITIAL_SUPPLY = 10000; // Initial supply of tokens
    uint256 public constant INITIAL_PRICE = 1000000000000000; // Initial price of the token (in wei)
    uint256 public constant PRICE_MULTIPLIER = 1000000; // Price multiplier

    uint256 public totalTokensSold;
    uint256 public tokenPrice;

    event TokenSwapInitiated(
        address indexed sender,
        address indexed recipient,
        address indexed token,
        uint256 amount
    );

    constructor() ERC20("CRITR", "CRITR") {
        _mint(msg.sender, INITIAL_SUPPLY);
        totalTokensSold = 0;
        tokenPrice = INITIAL_PRICE;
    }

    // Calculate the price of the token based on the number of tokens sold
    function calculatePrice() public view returns (uint256) {
        return tokenPrice;
    }

    // Buy tokens by sending Ethereum to the contract
    function buyTokens() public payable {
        uint256 tokensToBuy = msg.value / tokenPrice;
        require(tokensToBuy <= balanceOf(address(this)), "Insufficient token balance");
        totalTokensSold += tokensToBuy;

        // Adjust token price based on total tokens sold
        if (totalTokensSold == 10) {
            tokenPrice = INITIAL_PRICE * PRICE_MULTIPLIER;
        }

        _transfer(address(this), msg.sender, tokensToBuy);
    }

    // Swap tokens for ETH
    function swapTokensForETH(uint256 amount) public {
        require(amount <= balanceOf(msg.sender), "Insufficient token balance");
        uint256 ethAmount = amount * tokenPrice;
        require(address(this).balance >= ethAmount, "Contract does not have enough ETH");
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(ethAmount);
    }

    // Allow users to transfer tokens to the contract and receive ETH in exchange
    function transferTokensToContract(uint256 amount) public {
        require(amount <= balanceOf(msg.sender), "Insufficient token balance");
        uint256 ethAmount = amount * tokenPrice;
        require(address(this).balance >= ethAmount, "Contract does not have enough ETH");
        _transfer(msg.sender, address(this), amount);
        payable(msg.sender).transfer(ethAmount);
    }

    // Allow users to swap their custom tokens for ETH
    function swapCustomTokensForETH(uint256 amount) public {
        require(amount <= balanceOf(msg.sender), "Insufficient token balance");
        uint256 ethAmount = amount * tokenPrice;
        require(address(this).balance >= ethAmount, "Contract does not have enough ETH");
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(ethAmount);
    }

    // Function to initiate a token swap
    function initiateTokenSwap(address recipient, address token, uint256 amount) public {
        emit TokenSwapInitiated(msg.sender, recipient, token, amount);
    }
}
