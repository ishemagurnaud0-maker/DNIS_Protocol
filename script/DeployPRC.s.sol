//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


import {Script} from "forge-std/Script.sol";
import {PureStableCoin} from "./../src/PureStableCoin.sol";
import {PREngine} from "./../src/PREngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployPureCoin is Script {

    function run() external returns(PureStableCoin) {

        HelperConfig config = new HelperConfig(); 
        (
            address wethUsdPriceFeedAddress,
            address wbtcUsdPriceFeedAddress,
            address weth,
            address wbtc,
            uint256 deployerKey
        ) = config.activeNetworkConfig;

        vm.startBroadcast();
        PureStableCoin pureCoin = new PureStableCoin();
        PREngine prEngine = new PREngine();
        vm.stopBroadcast();

        return pureCoin;
    }
}