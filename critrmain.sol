// SPDX-License-Identifier: MIT 
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
    constructor(address _uniswapRouterAddress) ERC20("CRITR", "CRITR") { 
        _mint(msg.sender, INITIAL_SUPPLY); 
        totalTokensSold = 0; 
        tokenPrice = INITIAL_PRICE; 
        uniswapRouterAddress = _uniswapRouterAddress; 
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
  
    // Distribute vested tokens to users 
    function distributeVestedTokens() external { 
        // Ensure there are enough tokens for distribution 
        require(totalVestedAmount >= TOKENS_PER_MONTH_PER_USER, "Insufficient vested tokens for distribution"); 
  
        // Implement your logic to fetch user addresses from your social network data 
        address[] memory users = getUsersFromSocialNetwork(); // Replace with your logic 
  
        for (uint256 i = 0; i < users.length; i++) { 
            address user = users[i]; 
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
  
    // Define a struct to store user profiles
struct UserProfile {
    address walletAddress; // Ethereum wallet address associated with the user's profile
    bool isActive; // Flag to indicate if the user's profile is active
}

// Mapping to store user profiles
mapping(address => UserProfile) public userProfiles;

// Event to notify when a user profile is created
event UserProfileCreated(address indexed user, address indexed walletAddress);

// Function to create or update a user profile
function createUserProfile(address _user, address _walletAddress) external {
    require(_user != address(0), "Invalid user address");
    require(_walletAddress != address(0), "Invalid wallet address");

    // Check if the user already has a profile
    if (!userProfiles[_user].isActive) {
        // Create a new user profile
        userProfiles[_user] = UserProfile(_walletAddress, true);
        emit UserProfileCreated(_user, _walletAddress);
    } else {
        // Update the user's wallet address
        userProfiles[_user].walletAddress = _walletAddress;
    }
}

// Function to fetch active user addresses from your social network data
function getUsersFromSocialNetwork() internal view returns (address[] memory) {
    // Initialize an array to store active user addresses
    address[] memory activeUsers = new address[](totalUsers);
    uint256 index = 0;

    // Iterate through user profiles and add active users to the array
    for (uint256 i = 0; i < totalUsers; i++) {
        address user = getUserAtIndex(i);
        if (userProfiles[user].isActive) {
            activeUsers[index] = userProfiles[user].walletAddress;
            index++;
        }
    }

    // Resize the array to remove any unused slots
    assembly {
        mstore(activeUsers, index)
    }

    return activeUsers;
}

// Function to get user address at a specific index (assuming totalUsers is maintained elsewhere)
function getUserAtIndex(uint256 _index) internal view returns (address) {
    // Implement your logic to retrieve user addresses based on the index
    // This function depends on how you manage user data in your social network
    // Return user address at the specified index
}

