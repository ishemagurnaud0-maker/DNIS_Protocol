//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test, console } from "forge-std/Test.sol";
import { DeployPureCoin } from "../../script/DeployPRC.s.sol";
import { PREngine } from "../../src/PREngine.sol";
import { PureStableCoin } from "../../src/PureStableCoin.sol";
import {ERC20Mock} from "./../mocks/ERC20Mock.sol";

contract TestPREngine is Test {
    PREngine public prEngine;
    PureStableCoin public pureCoin;
    DeployPureCoin public deployer;

    function setUp() public {
        deployer = new DeployPureCoin();
        (pureCoin, prEngine) = deployer.run();
    }

    function testEngineDeployment() public {
        assert(address(prEngine) != address(0));
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
        vm.stopPrank();

        vm.startPrank(bob);
        prEngine.depositCollateral(wethAddress, amount);
        vm.stopPrank();

        assert(amount == prEngine.getCollateralDeposited(bob, wethAddress));
    }


}