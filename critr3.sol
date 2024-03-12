pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract CRITR is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Constants
    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** 18); // Initial supply of tokens (multiplying by 10^18 to account for decimals)
    uint256 public constant INITIAL_PRICE = 10000000000000; // Initial price of the token (in wei)
    uint256 public constant TOKENS_PER_MONTH_PER_USER = 1; // Number of tokens vested per month per user

    // State variables
    uint256 public totalTokensSold;
    uint256 public tokenPrice;
    uint256 public totalVestedAmount; // Total amount of tokens vested for distribution
    address public uniswapRouterAddress;

    // Vesting
    struct VestingSchedule {
        uint256 startTime;
    }

    mapping(address => VestingSchedule) public vestingSchedules;

    // Events
    event TokensVested(address indexed beneficiary, uint256 amount);
    event TokensSwapped(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    // Constructor
    constructor(address _uniswapRouterAddress) ERC20("CRITR", "CRITR") {
        _mint(msg.sender, INITIAL_SUPPLY);
        totalTokensSold = 0;
        tokenPrice = INITIAL_PRICE;
        uniswapRouterAddress = _uniswapRouterAddress;
    }

    // Exponential bonding curve function to adjust token price
    function exponentialCurve(uint256 tokensSold) internal pure returns (uint256) {
        // Exponential curve: price increases exponentially with tokens sold
        return INITIAL_PRICE * (2 ** (tokensSold / 1000)); // Adjust the curve parameters as needed
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
    function swapTokensForOtherToken(address tokenOut, uint256 amountIn) external nonReentrant {
        require(tokenOut != address(this), "Invalid token address"); // Ensure the token to swap is not the same as this token
        require(amountIn > 0, "Invalid amount");

        IERC20(this).approve(uniswapRouterAddress, amountIn); // Approve the Uniswap router to spend tokens

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = tokenOut;

        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
        uniswapRouter.swapExactTokensForTokens(
            amountIn,
            0, // Accept any amount of the other token
            path,
            address(this), // Receive the swapped tokens back to this contract
            block.timestamp + 1800 // Deadline for the swap (30 minutes)
        );

        emit TokensSwapped(msg.sender, address(this), tokenOut, amountIn, 0);
    }

    // Distribute vested tokens to users
    function distributeVestedTokens() external {
        // Ensure there are enough tokens for distribution
        require(totalVestedAmount >= TOKENS_PER_MONTH_PER_USER, "Insufficient vested tokens for distribution");

        // Iterate through all users with vesting schedules
        for (uint256 i = 0; i < totalUsers; i++) {
            address user = // Get user address from your social network data;
            VestingSchedule storage vestingSchedule = vestingSchedules[user];

            // Check if user has a vesting schedule and it's time to distribute tokens
            if (vestingSchedule.startTime > 0 && block.timestamp >= vestingSchedule.startTime) {
                // Distribute tokens to the user
                _transfer(address(this), user, TOKENS_PER_MONTH_PER_USER);

                // Decrease total vested amount
                totalVestedAmount -= TOKENS_PER_MONTH_PER_USER;

                emit TokensVested(user, TOKENS_PER_MONTH_PER_USER);
            }
        }
    }
}
