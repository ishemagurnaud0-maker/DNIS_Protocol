//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


import {Script, console} from "forge-std/Script.sol";
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
            address wbtc
        ) = config.activeNetworkConfig;

        console.log(wethUsdPriceFeedAddress);
        console.log(wbtcUsdPriceFeedAddress);
        console.log(weth);
        console.log(wbtc);

        address[] public tokenAddresses = new address[](2);
        tokenAddresses[0] = weth;
        tokenAddresses[1] = wbtc;

        address[] public priceFeedAddresses = new address[](2);
        priceFeedAddresses[0] = wethUsdPriceFeedAddress;
        priceFeedAddresses[1] = wbtcUsdPriceFeedAddress;

        uint256 private constant LT_THRESHOLD = 50;

        vm.startBroadcast();
        PureStableCoin pureCoin = new PureStableCoin();
        PREngine prEngine = new PREngine(tokenAddresses, priceFeedAddresses, address(pureCoin), LT_THRESHOLD);
        vm.stopBroadcast();

        return pureCoin;
    }
}