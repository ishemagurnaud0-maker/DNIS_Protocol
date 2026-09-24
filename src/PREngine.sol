//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {PureStableCoin} from "./PureStableCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    error PREngine__HealthFactorHasBroken();


    event CollateralDeposited(address indexed owner, address indexed tokenAddress, uint256 amount);

    mapping(address account => mapping(address token => uint256 amount)) public s_collateralDeposited;
    mapping(address token => address priceFeed) private s_tokenToPriceFeed;
    mapping(address account => uint256 amountMinted) private s_amountMinted;


    PureStableCoin private immutable i_PRCoin;
    uint256 private immutable i_LiquidationThreshold;


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

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address PRCoinAddress, uint256 LtThreshold) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert PREngine__TokenAddressesExceedPriceFeeds();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_tokenToPriceFeed[tokenAddresses[i]] = priceFeedAddresses[i];
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

       if(!success) {
         revert PREngine__TransferFailed();
       }

       emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

    }

    

    function redeemCollateralForPRCoin() external {}

    function redeemCollateral() external {}

    function liquidate() external {}

    function burnPRCoin() external {}

    /*
    * @notice follows CEI
    * @param amountToMint The amount of PURE stablecoin to mint 
    * @notice They must have more collateral value than the minimum threshold
     */

    function mintPRCoin(uint256 amountToMint) external NotZero(amountToMint) nonReentrant{

    }

    function getHealthFactor() external view {}




    function _healthFactor(address user, address tokenCollateralAddress) internal view returns(uint256) {
        uint256 totalCollateralDeposited = s_collateralDeposited[user][tokenCollateralAddress];

            if(totalCollateralDeposited == 0) {
                revert PREngine__InsufficientCollateral();
            }

           uint256 healthFactor = (totalCollateralDeposited * i_LiquidationThreshold)/s_amountMinted[user];

           return healthFactor;
    }

    function _revertIfHealthFactorIsBroken(address tokenCollateralAddress) internal view {
        uint256 healthFactor = _healthFactor(msg.sender, tokenCollateralAddress);

            if(healthFactor < 1) {
                revert PREngine__HealthFactorHasBroken();
            }
    }
}
