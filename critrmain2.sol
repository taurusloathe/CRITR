// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

// Import the PriceOracle contract
import "./PriceOracle.sol";

contract CRITR is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Constants
    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** 18); // Initial supply of tokens (multiplying by 10^18 to account for decimals)
    uint256 public constant INITIAL_PRICE = 10000000000000; // Initial price of the token (in wei) 
    uint256 public constant TOKENS_PER_MONTH_PER_USER = 1; // Number of tokens vested per month per user

    // State variables
    uint256 public totalTokensSold;
    uint256 public totalVestedAmount; // Total amount of tokens vested for distribution
    address public uniswapRouterAddress;
    address public priceOracleAddress; // Address of the Price Oracle contract
    PriceOracle public priceOracle; // Price Oracle contract instance
    mapping(address => VestingSchedule) public vestingSchedules;
    mapping(address => bool) public isAdmin; // Mapping to store admin privileges

    // Counter for total users
    uint256 public totalUsers;

    // Vesting
    struct VestingSchedule {
        uint256 startTime;
    }

    // Events
    event TokensVested(address indexed beneficiary, uint256 amount);
    event TokensSwapped(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    // Constructor
    constructor(address _uniswapRouterAddress, address _priceOracleAddress) ERC20("CRITR", "CRITR") {
        _mint(msg.sender, INITIAL_SUPPLY);
        totalTokensSold = 0;
        uniswapRouterAddress = _uniswapRouterAddress;
        priceOracleAddress = _priceOracleAddress; // Set the Price Oracle address
        priceOracle = PriceOracle(priceOracleAddress); // Initialize the Price Oracle contract instance
        isAdmin[msg.sender] = true; // Contract deployer is the initial admin
        emit AdminAdded(msg.sender);
    }

    // Modifier to restrict access to admins only
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Caller is not an admin");
        _;
    }

    // Modifier to ensure the caller owns the tokens they are attempting to swap
    modifier ownsTokens(uint256 amount) {
        require(balanceOf(msg.sender) >= amount, "Caller does not have enough tokens");
        _;
    }

    // Exponential bonding curve function to adjust token price
    function exponentialCurve(uint256 tokensSold) internal view returns (uint256) {
        // Use the getPrice function from the Price Oracle contract to get the current price
        uint256 currentPrice = priceOracle.getPrice();
        // Exponential curve: price increases exponentially with tokens sold
        return currentPrice * (2 ** (tokensSold / 500)); // Adjust the curve parameters as needed
    }

    // Buy tokens by sending Ethereum to the contract
    function buyTokens(uint256 tokensToBuy) external payable nonReentrant {
        require(tokensToBuy > 0, "Number of tokens to buy must be greater than zero");
        uint256 ethAmount = exponentialCurve(totalTokensSold + tokensToBuy);
        require(msg.value >= ethAmount, "Insufficient ETH sent");

        // Adjust token price based on total tokens sold
        totalTokensSold += tokensToBuy;

        // Mint additional tokens if the total supply is reached
        if (totalSupply() == INITIAL_SUPPLY) {
            _mint(msg.sender, tokensToBuy);
        } else {
            uint256 remainingSupply = INITIAL_SUPPLY - totalSupply();
            if (remainingSupply >= tokensToBuy) {
                _mint(msg.sender, tokensToBuy);
            } else {
                _mint(msg.sender, remainingSupply);
            }
        }

        // Increase total vested amount by purchased tokens
        totalVestedAmount += tokensToBuy;
    }

    // Transfer tokens between accounts
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Swap tokens for other token
    function swapTokensForOtherToken(address tokenOut, uint256 amountIn) external nonReentrant ownsTokens(amountIn) {
        require(tokenOut != address(this), "Invalid token address"); // Ensure the token to swap is not the same as this token
        require(amountIn > 0, "Invalid amount");

        IERC20(this).approve(uniswapRouterAddress, amountIn); // Approve the Uniswap router to spend tokens

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = tokenOut;

        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
        // Perform the swap and check the return values for success
        try uniswapRouter.swapExactTokensForTokens(
            amountIn,
            0, // Accept any amount of the other token
            path,
            address(this), // Receive the swapped tokens back to this contract
            block.timestamp + 1800 // Deadline for the swap (30 minutes)
        ) {
            emit TokensSwapped(msg.sender, address(this), tokenOut, amountIn, 0);
        } catch Error(string memory reason) {
            revert(reason); // Revert with the specific reason for failure
        } catch {
            revert("Swap failed"); // Revert with a generic message if no specific reason is available
        }
    }

    // Add a new admin
    function addAdmin(address _admin) external onlyAdmin {
        require(!isAdmin[_admin], "Address is already an admin");
        isAdmin[_admin] = true;
        emit AdminAdded(_admin);
    }

    // Remove an existing admin
    function removeAdmin(address _admin) external onlyAdmin {
        require(isAdmin[_admin], "Address is not an admin");
        isAdmin[_admin] = false;
        emit AdminRemoved(_admin);
    }
}
