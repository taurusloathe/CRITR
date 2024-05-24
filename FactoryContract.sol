// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CRITR.sol";
import "./PriceOracle.sol";

contract FactoryContract {
    event ContractsDeployed(address tokenAddress, address oracleAddress, string tokenName, string tokenSymbol);

    function deployContracts(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply,
        address uniswapRouterAddress,
        address wormholeAddress,
        uint16 solanaChainId,
        address uniswapXRouterAddress
    ) external returns (address, address) {
        // Deploy Price Oracle Contract
        PriceOracle oracle = new PriceOracle(msg.sender);
        address priceOracleContract = address(oracle);

        // Deploy Token Contract
        CRITR token = new CRITR(
            tokenName,
            tokenSymbol,
            initialSupply,
            uniswapRouterAddress,
            priceOracleContract,
            wormholeAddress,
            solanaChainId,
            uniswapXRouterAddress
        );
        address tokenContract = address(token);

        emit ContractsDeployed(tokenContract, priceOracleContract, tokenName, tokenSymbol);
        return (tokenContract, priceOracleContract);
    }
}
