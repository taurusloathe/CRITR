// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceOracle is Ownable {
    uint256 private price;

    event PriceUpdated(uint256 newPrice);

    // Update the price by the owner
    function updatePrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
        emit PriceUpdated(_newPrice);
    }

    // Get the current price
    function getPrice() external view returns (uint256) {
        return price;
    }
}
