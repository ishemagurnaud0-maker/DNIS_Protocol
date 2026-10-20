//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {DeployPureCoin} from "../../script/DeployPRC.s.sol";
import {PREngine} from "../../src/PREngine.sol";
import {PureStableCoin} from "../../src/PureStableCoin.sol";
import {ERC20Mock} from "./../mocks/ERC20Mock.sol";

contract TestPREngine is Test {
    PREngine public prEngine;
    PureStableCoin public pureCoin;
    DeployPureCoin public deployer;
    address weth;
    address wethUsdPriceFeedAddress;
    address wbtcUsdPriceFeedAddress;

    function setUp() public {
        deployer = new DeployPureCoin();
        (pureCoin, prEngine, weth, wethUsdPriceFeedAddress, wbtcUsdPriceFeedAddress) = deployer.run();
    }

    address[] private tokenAddresses;
    address[] private priceFeedAddresses;

    //// /////////// //////// ////
    //// Constructor tests /////

    function testRevertIfTokenAddressesExceedsPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(wbtcUsdPriceFeedAddress);
        priceFeedAddresses.push(wethUsdPriceFeedAddress);

        vm.expectRevert(PREngine.PREngine__TokenAddressesExceedPriceFeeds.selector);
        new PREngine(tokenAddresses, priceFeedAddresses, address(pureCoin), 50);
    }

    function testEngineDeployment() public view {
        assert(address(prEngine) != address(0));
    }

    //// /////////// //////// ////
    //// Unit function tests /////

    function testMintPRCoinFromThePREngine() public {
        address bob = makeAddr("bob");
        address wethAddress = prEngine.getWETHAddress(); //ERC20Mock WETH token address
        uint256 allowance = 200 ether;
        uint256 PRCoinToMint = 10 ether;
        uint256 wethToMint = 50 ether;
        uint256 wethDeposited = 50 ether;

        vm.deal(bob, allowance);

        //mint WETH tokens
        vm.startPrank(bob);
        ERC20Mock(wethAddress).mint(bob, wethToMint);
        ERC20Mock(wethAddress).approve(address(prEngine), wethToMint);

        //deposit collateral

        prEngine.depositCollateral(wethAddress, wethDeposited);

        //mint PRCoin

        prEngine.mintPRCoin(PRCoinToMint);
        vm.stopPrank();

        assert(PRCoinToMint == prEngine.getPRCoinMinted(bob));
        assert(PRCoinToMint == pureCoin.balanceOf(bob));
    }

    function testDepositCollateral() public {
        address wethAddress = prEngine.getWETHAddress(); //ERC20Mock WETH token address
        address bob = makeAddr("bob");
        uint256 allowance = 100 ether;
        uint256 amount = 10 ether; // 10e18

        vm.deal(bob, allowance);

        //mint WETH tokens
        vm.startPrank(bob);
        ERC20Mock(wethAddress).mint(bob, amount);
        ERC20Mock(wethAddress).approve(address(prEngine), allowance);

        // deposit collateral
        prEngine.depositCollateral(wethAddress, amount);
        vm.stopPrank();

        assert(amount == prEngine.getCollateralDeposited(bob, wethAddress));
    }

    //// /////////// //////// ////
    //// PriceFeed tests /////

    function testGetUSDValue() public view {
        address wethAddress = prEngine.getWETHAddress(); //ERC20Mock WETH token address
        uint256 amount = 10 ether; // 10e18

        // 1 ether = 2000 USD, so 10 ether = 10e18 * 2000 = 20000e18
        uint256 expectedUSDValue = 20000 ether; // 20000e18

        uint256 usdValue = prEngine.getUSDValue(wethAddress, amount);
        console.log("USD Value: ", usdValue);

        assert(usdValue == expectedUSDValue);
    }
}

