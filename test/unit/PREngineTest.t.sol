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
    address bob = makeAddr("bob");
    uint256 private constant AMOUNT = 10 ether;
    uint256 private constant FUNDS = 100 ether;

    function setUp() public {
        deployer = new DeployPureCoin();
        (pureCoin, prEngine) = deployer.run();

        
         vm.deal(bob, FUNDS);
    }

    address[] private tokenAddresses;
    address[] private priceFeedAddresses;

    modifier depositCollateral() {
        address wethAddress = prEngine.getWETHAddress(); //ERC20Mock WETH token address
        
        uint256 allowance = 20 ether;

       

        //mint WETH tokens
        vm.startPrank(bob);
        ERC20Mock(wethAddress).mint(bob, AMOUNT);
        ERC20Mock(wethAddress).approve(address(prEngine), allowance);

        // deposit collateral
        prEngine.depositCollateral(wethAddress, AMOUNT);
        vm.stopPrank();

        _;
    }

    //// /////////// //////// ////
    //// Constructor tests /////

    function testRevertIfTokenAddressesExceedsPriceFeeds() public {
        address weth = prEngine.getWETHAddress();
        address wbtc = prEngine.getWBTCAddress();
        address wethUsdPriceFeedAddress = prEngine.getPriceFeedAddress(weth);
        address wbtcUsdPriceFeedAddress = prEngine.getPriceFeedAddress(wbtc);

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

    function testMintPRCoin() public {
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

    function testRevertsWithUnapprovedTokenCollateral() public {
        uint256 amountCollateral = 100 ether;
        uint256 depositFee = 10 ether;
        ERC20Mock rado = new ERC20Mock("RADO", "RADO", bob, amountCollateral);

        vm.startPrank(bob);
        vm.expectRevert(PREngine.PREngine__InvalidTokenAddress.selector);
        prEngine.depositCollateral(address(rado), depositFee);
        vm.stopPrank();
    }

    function testRevertsOnNotZeroModifier() public {
        address wethAddress = prEngine.getWETHAddress(); //ERC20Mock WETH token address
        uint256 allowance = 100 ether;

        vm.deal(bob, allowance);

        //mint WETH tokens
        vm.startPrank(bob);
        ERC20Mock(wethAddress).mint(bob, AMOUNT);
        ERC20Mock(wethAddress).approve(address(prEngine), allowance);

        // deposit collateral
        vm.expectRevert(PREngine.PREngine__MustBeGreaterThanZero.selector);
        prEngine.depositCollateral(wethAddress, 0);
        vm.stopPrank();
    }

    function testDepositCollateralAndGetAccountInfo() public depositCollateral {
        uint256 expectedPRCoinMinted = 0;
        address weth = prEngine.getWETHAddress();

        (uint256 totalPRcoinMinted, uint256 totalCollateralDepositedInUSD) = prEngine.getAccountInformation(bob);
        uint256 expectedDepositedCollateral = prEngine.getTokenAmountFromUSDValue(weth, totalCollateralDepositedInUSD);

        assertEq(totalPRcoinMinted, expectedPRCoinMinted);
        assertEq(AMOUNT, expectedDepositedCollateral);
    }

    function testDepositCollateralAndMintPRCoin() public {
        uint256 amountToMint = 50 ether;
        uint256 allowance = 20 ether;
        address weth = prEngine.getWETHAddress();

        vm.startPrank(bob);
        ERC20Mock(weth).mint(bob, amountToMint);
        ERC20Mock(weth).approve(address(prEngine), allowance);

        prEngine.depositCollateralAndMintPRCoin(weth, AMOUNT, amountToMint);
        vm.stopPrank();

        (uint256 totalPRcoinMinted, uint256 totalCollateralDepositedInUSD) = prEngine.getAccountInformation(bob);

        assert(totalPRcoinMinted == amountToMint);
        assert(totalCollateralDepositedInUSD == prEngine.getUSDValue(weth, AMOUNT));
    }

    function testBurnPRCoin() public depositCollateral {
        uint256 prCoinToMint = 10 ether;
        uint256 prCoinToBurn = 5 ether;
        uint256 amountToApprove = 20 ether;

        vm.startPrank(bob);
        // mint PRCoin
        prEngine.mintPRCoin(prCoinToMint);
        //approving the prEngine in order to transfer the PRCoin on my behalf
        pureCoin.approve(address(prEngine), amountToApprove);

        //Burn PRCoin
        prEngine.burnPRCoin(prCoinToBurn);
        vm.stopPrank();

        uint256 expectedBalance = 5 ether;

        assert(prEngine.getPRCoinMinted(bob) == expectedBalance);
    }

    function testRedeemCollateral() public depositCollateral {
        uint256 prCoinToMint = 15 ether;
        uint256 amountToRedeem = 5 ether;
        uint256 amountToBurn = 5 ether;
        address wethAddress = prEngine.getWETHAddress();
        uint256 startingBalance = ERC20Mock(wethAddress).balanceOf(bob);

        vm.startPrank(bob);
        prEngine.mintPRCoin(prCoinToMint);

        //burning the PRCoin in order to redeem collateral
        pureCoin.approve(address(prEngine), amountToBurn);
        prEngine.burnPRCoin(amountToBurn);

        prEngine.redeemCollateral(wethAddress, amountToRedeem);
        vm.stopPrank();

        uint256 newWethBalance = amountToRedeem + startingBalance;
        uint256 remainingPRCoin = 10 ether;

        assertEq(pureCoin.balanceOf(bob), remainingPRCoin);
        assert(ERC20Mock(wethAddress).balanceOf(bob) == newWethBalance);
    }

    function testGetHealthFactor() public depositCollateral {
        uint256 amountToMint = 10 ether;
        
         
         vm.startPrank(bob);
         prEngine.mintPRCoin(amountToMint);
         vm.stopPrank();

         uint256 healthFactor = prEngine.getHealthFactor(bob);
         console.log(healthFactor);

        uint256 MIN_HEALTH_FACTOR = 1;
         
         assert(healthFactor > MIN_HEALTH_FACTOR);
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

    function testGetTokenAmountFromUSDValue() public view {
        uint256 debtToCoverInUsd = 1000 ether;
        uint256 expectedTokenAmount = 0.5 ether;
        address weth = prEngine.getWETHAddress();

        uint256 obtainedTokenAmount = prEngine.getTokenAmountFromUSDValue(weth, debtToCoverInUsd);
        console.log(obtainedTokenAmount);

        assert(expectedTokenAmount == obtainedTokenAmount);
    }
}

