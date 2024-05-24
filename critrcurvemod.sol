// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol"; 
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Factory.sol"; 
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@certusone/wormhole-sdk/ethereum/contracts/interfaces/IWormhole.sol";

contract CRITR is ERC20, ReentrancyGuard { 
    using SafeERC20 for IERC20;

    // Constants 
    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** 18); // Initial supply of tokens (multiplying by 10^18 to account for decimals) 
    uint256 public constant INITIAL_PRICE = 10000000000000; // Initial price of the token (in wei) 
    uint256 public constant TOKENS_PER_MONTH_PER_USER = 1; // Number of tokens vested per month per user 
    uint256 public constant PRICE_FLOOR_LIMIT = 5999; // Number of tokens sold at the initial price

    // State variables 
    uint256 public totalTokensSold; 
    uint256 public tokenPrice; 
    uint256 public totalVestedAmount; // Total amount of tokens vested for distribution 
    address public uniswapRouterAddress; 
    address public priceOracleAddress; // Address of the Price Oracle contract
    address public uniswapXRouterAddress; // Address of the UniswapX Router contract
    mapping(address => VestingSchedule) public vestingSchedules; 
    mapping(address => bool) public isAdmin; // Mapping to store admin privileges 
    mapping(address => bool) public authorizedSources; // Mapping to store authorized Price Oracle sources
    uint256 public totalUsers;

    IWormhole public wormhole;
    uint16 public solanaChainId;

    // Vesting 
    struct VestingSchedule { 
        uint256 startTime; 
    } 

    // Events 
    event TokensVested(address indexed beneficiary, uint256 amount); 
    event TokensSwapped(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut); 
    event AdminAdded(address indexed admin); 
    event AdminRemoved(address indexed admin); 
    event TokensTransferredToSolana(address indexed user, uint256 amount, bytes32 solanaRecipient);
    event TokensReceivedFromSolana(address indexed recipient, uint256 amount);

    // Constructor 
    constructor(
        address _uniswapRouterAddress, 
        address _priceOracleAddress,
        address _wormholeAddress,
        uint16 _solanaChainId,
        address _uniswapXRouterAddress
    ) ERC20("CRITR", "CRITR") { 
        _mint(msg.sender, INITIAL_SUPPLY); 
        totalTokensSold = 0; 
        tokenPrice = INITIAL_PRICE; 
        uniswapRouterAddress = _uniswapRouterAddress; 
        priceOracleAddress = _priceOracleAddress; 
        uniswapXRouterAddress = _uniswapXRouterAddress;
        isAdmin[msg.sender] = true; // Contract deployer is the initial admin 
        authorizedSources[priceOracleAddress] = true; // Price Oracle contract is initially authorized
        wormhole = IWormhole(_wormholeAddress);
        solanaChainId = _solanaChainId;
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
        uint256 currentPrice = IPriceOracle(priceOracleAddress).getPrice();
        // Exponential curve: price increases exponentially with tokens sold
        return currentPrice * (2 ** (tokensSold / 500)); // Adjust the curve parameters as needed
    }

    // Buy tokens by sending Ethereum to the contract
    function buyTokens(uint256 tokensToBuy) external payable nonReentrant {
        require(tokensToBuy > 0, "Number of tokens to buy must be greater than zero");

        uint256 ethAmount;
        if (totalTokensSold + tokensToBuy <= PRICE_FLOOR_LIMIT) {
            // All tokens within the initial price floor
            ethAmount = tokensToBuy * INITIAL_PRICE;
        } else if (totalTokensSold >= PRICE_FLOOR_LIMIT) {
            // All tokens are subject to exponential pricing
            ethAmount = exponentialCurve(totalTokensSold + tokensToBuy);
        } else {
            // Some tokens at the initial price, others at the exponential price
            uint256 tokensAtInitialPrice = PRICE_FLOOR_LIMIT - totalTokensSold;
            uint256 tokensAtExponentialPrice = tokensToBuy - tokensAtInitialPrice;
            ethAmount = (tokensAtInitialPrice * INITIAL_PRICE) + exponentialCurve(totalTokensSold + tokensAtExponentialPrice);
        }

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

    // Swap tokens for other token using UniswapX
    function swapTokensForOtherTokenUsingUniswapX(address tokenOut, uint256 amountIn) external nonReentrant ownsTokens(amountIn) {
        require(tokenOut != address(this), "Invalid token address"); // Ensure the token to swap is not the same as this token
        require(amountIn > 0, "Invalid amount");

        IERC20(this).approve(uniswapXRouterAddress, amountIn); // Approve the UniswapX router to spend tokens

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = tokenOut;

        IUniswapV2Router02 uniswapXRouter = IUniswapV2Router02(uniswapXRouterAddress);
        // Perform the swap and check the return values for success
        try uniswapXRouter.swapExactTokensForTokens(
            amountIn,
            0, // Accept any amount of the other token
            path,
            msg.sender, // Receive the swapped tokens back to this contract
            block.timestamp + 1800 // Deadline for the swap (30 minutes)
        ) {
            emit TokensSwapped(msg.sender, address(this), tokenOut, amountIn, 0);
        } catch Error(string memory reason) {
            revert(reason); // Revert with the specific reason for failure
        } catch {
            revert("Swap failed"); // Revert with a generic message if no specific reason is available
        }
    }

    // Transfer tokens to Solana
    function transferToSolana(uint256 amount, bytes32 solanaRecipient) external nonReentrant {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);

        wormhole.transferTokens(
            address(this),
            amount,
            solanaChainId,
            solanaRecipient,
            0,
            block.timestamp + 600
        );

        emit TokensTransferredToSolana(msg.sender, amount, solanaRecipient);
    }

    // Receive tokens from Solana
    function receiveFromSolana(bytes memory vaa) public {
        (address recipient, uint256 amount) = wormhole.completeTransfer(vaa);
        _mint(recipient, amount);

        emit TokensReceivedFromSolana(recipient, amount);
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

    // Update token price based on total tokens sold
    function updateTokenPrice() internal {
        tokenPrice = exponentialCurve(totalTokensSold);
    }

    // Function to vest tokens to beneficiaries
    function vestTokens(address beneficiary, uint256 amount) external onlyAdmin {
        require(amount > 0, "Vesting amount must be greater than zero");
        _transfer(msg.sender, beneficiary, amount);

        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        schedule.startTime = block.timestamp;

        emit TokensVested(beneficiary, amount);
    }

    // Function to claim vested tokens
    function claimVestedTokens() external {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(schedule.startTime > 0, "No tokens vested");

        uint256 vestedMonths = (block.timestamp - schedule.startTime) / 30 days;
        uint256 vestedAmount = vestedMonths * TOKENS_PER_MONTH_PER_USER;

        require(vestedAmount > 0, "No vested tokens available");
        require(vestedAmount <= balanceOf(address(this)), "Insufficient contract balance");

        _transfer(address(this), msg.sender, vestedAmount);

        emit TokensVested(msg.sender, vestedAmount);
    }
}
