//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// the Invariants

// 1. The total supply of the PRCoin should be less than the value of the value of collateral
// 2. Getter functions should never revert <- evergreen invariant

import {DeployPureCoin} from "./../../script/DeployPRC.s.sol";
import {PREngine} from "./../../src/PREngine.sol";
import {PureStableCoin} from "./../../src/PureStableCoin.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {HelperConfig} from "./../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InvariantPRCoinTest is StdInvariant, Test {
    PREngine prEngine;
    PureStableCoin prCoin;
    HelperConfig config;
    address weth;
    address wbtc;

    function setUp() public {
        DeployPureCoin deployer = new DeployPureCoin();
        (prCoin, prEngine, config) = deployer.run();
        (,, weth, wbtc) = config.activeNetworkConfig( );

        console.log(wbtc);
        console.log(weth);

        targetContract(address(prEngine));
    }

    function invariant_verifyThatTheCollateralInTheProtocolIsGreaterThanTheMintedStableCoin() public view {
       
    }
}

