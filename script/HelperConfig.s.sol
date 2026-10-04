//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {MockWBTC} from "./../test/mocks/MockWBTC.sol";
import {MockV3Aggregator} from "./../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "./../test/mocks/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wethUsdPriceFeedAddress;
        address wbtcUsdPriceFeedAddress;
        address weth;
        address wbtc;
    }

    uint8 private constant DECIMALS = 8;
    int256 private constant ETH_USD_PRICE = 2000e8;
    int256 private constant BTC_USD_PRICE = 10000e8;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        getActiveNetwork();
    }

    function getSepoliaConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        MockWBTC wbtc = new MockWBTC();
        vm.stopBroadcast();

        return NetworkConfig({
            wethUsdPriceFeedAddress: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUsdPriceFeedAddress: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14,
            wbtc: address(wbtc)
        });
    }

    function getActiveNetwork() public returns (NetworkConfig memory) {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }

        return activeNetworkConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.wethUsdPriceFeedAddress != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        // WETH stablecoin mock

        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        ERC20Mock wethERC20Mock = new ERC20Mock("WETH", "WETH", msg.sender, 1000e8);

        //WBTC stablecoin mock

        MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(DECIMALS, BTC_USD_PRICE);
        ERC20Mock wbtcERC20Mock = new ERC20Mock("WBTC", "WETH", msg.sender, 1000e8);

        vm.stopBroadcast();

        return NetworkConfig({
            wethUsdPriceFeedAddress: address(ethUsdPriceFeed),
            wbtcUsdPriceFeedAddress: address(btcUsdPriceFeed),
            weth: address(wethERC20Mock),
            wbtc: address(wbtcERC20Mock)
        });
    }
}

