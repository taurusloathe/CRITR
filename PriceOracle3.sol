// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// Standard interface for price oracles
interface IPriceOracle {
    function getPrice() external view returns (uint256);
}

contract PriceOracle is Ownable, IPriceOracle {
    uint256 public tokenPrice;
    address public authorizedSource;
    mapping(address => bool) public authorizedDEX;

    event PriceUpdated(uint256 newPrice);
    event AuthorizedDEXAdded(address indexed dex);
    event AuthorizedDEXRemoved(address indexed dex);

    constructor(address _authorizedSource, address initialOwner) Ownable(initialOwner) {
        authorizedSource = _authorizedSource;
    }

    function updatePrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be greater than zero");
        tokenPrice = newPrice;
        emit PriceUpdated(newPrice);
    }

    function getPrice() external view override returns (uint256) {
        return tokenPrice;
    }

    function setAuthorizedSource(address _authorizedSource) external onlyOwner {
        authorizedSource = _authorizedSource;
    }

    function addAuthorizedDEX(address dex) external onlyOwner {
        authorizedDEX[dex] = true;
        emit AuthorizedDEXAdded(dex);
    }

    function removeAuthorizedDEX(address dex) external onlyOwner {
        authorizedDEX[dex] = false;
        emit AuthorizedDEXRemoved(dex);
    }

    modifier onlyAuthorizedSource() {
        require(msg.sender == authorizedSource, "Caller is not the authorized source");
        _;
    }

    modifier onlyAuthorizedDEX() {
        require(authorizedDEX[msg.sender], "Caller is not an authorized DEX");
        _;
    }

    // Function to calculate the token price in US dollars
    function getPriceInUSD(uint256 ethPriceUSD) external view returns (uint256) {
        return tokenPrice * ethPriceUSD / 1e18; // Assuming ethPriceUSD is in wei
    }

    // Function to calculate the token price in ETH
    function getPriceInETH() external view returns (uint256) {
        return tokenPrice / 1e18; // Token price already in wei
    }
}
