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
    address bob = makeAddr("bob");

    function setUp() public {
        deployer = new DeployPureCoin();
        (pureCoin, prEngine, weth, wethUsdPriceFeedAddress, wbtcUsdPriceFeedAddress) = deployer.run();
    }

    address[] private tokenAddresses;
    address[] private priceFeedAddresses;


    modifier depositCollateral() {
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

        _; 
    }

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
        ERC20Mock rado = new ERC20Mock("RADO","RADO", bob, amountCollateral);

        vm.startPrank(bob);
        vm.expectRevert(PREngine.PREngine__InvalidTokenAddress.selector);
        prEngine.depositCollateral(address(rado),depositFee);
        vm.stopPrank();
    }

    function testDepositCollateralAndGetAccountInfo() public depositCollateral {
         uint256 expectedPRCoinMinted = 0;
         uint256 expectedCollateralInUsd = 20000e18;
        (uint256 totalPRcoinMinted, uint256 totalCollateralDepositedInUSD) = prEngine.getAccountInformation(bob);

        assertEq(totalPRcoinMinted,expectedPRCoinMinted);
        assertEq(totalCollateralDepositedInUSD, expectedCollateralInUsd);

        
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

        uint256 obtainedTokenAmount = prEngine.getTokenAmountFromUSDValue(weth, debtToCoverInUsd);
        console.log(obtainedTokenAmount);

        assert(expectedTokenAmount == obtainedTokenAmount);
    }


}

