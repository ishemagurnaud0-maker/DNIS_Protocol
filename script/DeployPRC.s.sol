//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


import {Script} from "forge-std/Script.sol";
import {PureStableCoin} from "./../src/PureStableCoin.sol";


contract DeployPureCoin is Script {

    function run() external returns(PureStableCoin) {
        PureStableCoin pureCoin;

        vm.startBroadcast();
        pureCoin = new PureStableCoin();
        vm.stopBroadcast();

        return pureCoin;
    }
}