//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {PureStableCoin} from "./PureStableCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/*
* @title PUREStableCoin Engine
* @author ISHEMA Gurnaud
*
* @dev The system is designed to be as minimal and have the tokens maintain the value of one Dollar
     token == 1 USD

* This stablecoin has the properties :
   - Exogenous Collateral
   - Dollar Pegged
   - Algorithmic Stable

 * It is similar to DAI if DAI had no governance , no fees and was only backed by wETH and wBTC.
 *
 * @notice This contract is the core of the PURE StableCoin System.
 */

contract PREngine is ReentrancyGuard {
    error PREngine__MustBeGreaterThanZero();
    error PREngine__InvalidAddress();
    error PREngine__TokenAddressesExceedPriceFeeds();
    error PREngine__InvalidTokenAddress();
    error PREngine__TransferFailed();
    error PREngine__InsufficientCollateral();
    error PREngine__FailedToMintPRStableCoin();
    error PREngine__HealthFactorIsBroken(uint256 healthFactor);
    error PREngine__InvalidPriceFeedAnswer();

    event CollateralDeposited(address indexed owner, address indexed tokenAddress, uint256 amount);
    event PUREStableCoinMinted(address indexed account, uint256 indexed amount);

    mapping(address account => mapping(address token => uint256 amount)) public s_collateralDeposited;
    mapping(address token => address priceFeed) private s_tokenToPriceFeed;
    mapping(address account => uint256 amountMinted) private s_PRCoinMinted;

    uint256 private constant MIN_HEALTH_FACTOR = 1;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_PRECISION = 1e18;
    uint256 private constant LIQUIDATION_PRECISION = 100;

    PureStableCoin private immutable i_PRCoin;
    uint256 private immutable i_LiquidationThreshold;
    address[] private s_collateralTokens;

    modifier NotZero(uint256 _amount) {
        if (_amount <= 0) {
            revert PREngine__MustBeGreaterThanZero();
        }

        _;
    }

    modifier isTokenAllowed(address token) {
        if (s_tokenToPriceFeed[token] == address(0)) {
            revert PREngine__InvalidTokenAddress();
        }

        _;
    }

    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address PRCoinAddress,
        uint256 LtThreshold
    ) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert PREngine__TokenAddressesExceedPriceFeeds();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_tokenToPriceFeed[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }

        i_PRCoin = PureStableCoin(PRCoinAddress);
        i_LiquidationThreshold = LtThreshold;
    }

    function depositCollateralAndMintPRCoin() external {}

    /*
    * @param tokenCollateralAddress The address of the token to deposit as collateral
    * @param amountCollateral The amount of collateral that you are to put up in order to borrow the PURE stablecoin

    */

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        NotZero(amountCollateral)
        isTokenAllowed(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);

        if (!success) {
            revert PREngine__TransferFailed();
        }

        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
    }

    function redeemCollateralForPRCoin() external {}

    function redeemCollateral() external {}

    function liquidate() external {}

    /*@notice This function is used to burn unnecessary stable coins in order to get back your collateral
     *@param amountToBurn is the amount of tokens you want to burn or destroy

     */

    function burnPRCoin(uint256 amountToBurn) external nonReentrant {
        i_PRCoin.burn(amountToBurn);
    }

    /*
    * @notice follows CEI
    * @param amountToMint The amount of PURE stablecoin to mint
    * @notice They must have more collateral value than the minimum threshold
     */

    function mintPRCoin(uint256 amountToMint) external NotZero(amountToMint) nonReentrant {
        _revertIfHealthFactorIsBroken(msg.sender);
        s_PRCoinMinted[msg.sender] += amountToMint;
        bool minted = i_PRCoin.mint(msg.sender, amountToMint);
        if (minted) {
            emit PUREStableCoinMinted(msg.sender, amountToMint);
        } else {
            revert PREngine__FailedToMintPRStableCoin();
        }
    }

    function getHealthFactor() external view {}

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert PREngine__HealthFactorIsBroken(userHealthFactor);
        }
    }

    function _healthFactor(address user) internal view returns (uint256) {
        (uint256 totalPRcoinMinted, uint256 totalCollateralDepositedInUSD) = _getAccountInfo(user);
        uint256 collateralAdjustedForThresHold =
            (totalCollateralDepositedInUSD * i_LiquidationThreshold) / LIQUIDATION_PRECISION;

        return (collateralAdjustedForThresHold * PRECISION) / totalPRcoinMinted;
    }

    function _getAccountInfo(address user)
        private
        view
        returns (uint256 totalPRcoinMinted, uint256 totalCollateralDepositedInUSD)
    {
        totalPRcoinMinted = s_PRCoinMinted[user];
        totalCollateralDepositedInUSD = _getAccountCollateralValue(user);

        return (totalPRcoinMinted, totalCollateralDepositedInUSD);
    }

    function _getAccountCollateralValue(address user) public view returns (uint256 totalValue) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalValue += getUSDValue(token, amount);
        }

        return totalValue;
    }

    function getUSDValue(address token, uint256 amount) public view returns (uint256) {
        address _priceFeed = s_tokenToPriceFeed[token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);

        (, int256 price,,,) = priceFeed.latestRoundData();

        // casting to 'uint80' is safe because of previous checks
        // forge-lint: disable-next-line(unsafe-typecast)
        if (price <= 0 || uint256(price) > type(uint256).max) {
            revert PREngine__InvalidPriceFeedAnswer();
        }
        // casting to 'uint80' is safe because of previous checks
       // forge-lint: disable-next-line(unsafe-typecast)
        return (uint256(price) * ADDITIONAL_PRECISION * amount) / PRECISION;
    }

    //test helper functions

    function getWBTCAddress() external view returns (address) {
        return s_collateralTokens[1];
    }

    function getWETHAddress() external view returns (address) {
        return s_collateralTokens[0];
    }

    function getCollateralDeposited(address user, address tokenAddress) external view returns (uint256) {
        return s_collateralDeposited[user][tokenAddress];
    }
}
