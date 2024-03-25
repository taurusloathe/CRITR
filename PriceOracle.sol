// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceOracle is Ownable {
    uint256 public tokenPrice;
    address public authorizedSource;

    event PriceUpdated(uint256 newPrice);

    constructor(address _authorizedSource) {
        authorizedSource = _authorizedSource;
    }

    function updatePrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be greater than zero");
        tokenPrice = newPrice;
        emit PriceUpdated(newPrice);
    }

    function getPrice() external view returns (uint256) {
        return tokenPrice;
    }

    function setAuthorizedSource(address _authorizedSource) external onlyOwner {
        authorizedSource = _authorizedSource;
    }

    modifier onlyAuthorizedSource() {
        require(msg.sender == authorizedSource, "Caller is not the authorized source");
        _;
    }
}
