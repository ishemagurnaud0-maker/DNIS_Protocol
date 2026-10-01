//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test, console } from "forge-std/Test.sol";
import { DeployPureCoin } from "../../script/DeployPRC.s.sol";
import { PREngine } from "../../src/PREngine.sol";
import { PureStableCoin } from "../../src/PureStableCoin.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract TestPREngine is Test {
    PREngine public prEngine;
    PureStableCoin public pureCoin;
    DeployPureCoin public deployer;

    address bob = makeAddr("bob");

    function setUp() public {
        deployer = new DeployPureCoin();
        (pureCoin, prEngine) = deployer.run();
    }

    function testEngineDeployment() public {
        assert(address(prEngine) != address(0));
    }

    function testDepositCollateral() public {
        address wethAddress = prEngine.getWETHAddress();
        uint256 depositAmount = 1 ether;

        // Mint WETH to Bob's address
        vm.startPrank(bob);
        pureCoin.mint(bob, depositAmount);
        pureCoin.approve(address(prEngine), depositAmount);
        
        // Deposit collateral
        prEngine.depositCollateral(wethAddress, depositAmount);
        vm.stopPrank();

        uint256 collateralDeposited = prEngine.s_collateralDeposited(bob, wethAddress);

        assertEq(collateralDeposited, depositAmount);

    }


}