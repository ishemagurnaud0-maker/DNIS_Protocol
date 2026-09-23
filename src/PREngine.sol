//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


/*
* @title PUREStableCoin Engine
* @author ISHEMA Gurnaud
* 
* @dev The system is designed to be as minimal and have the tokens maintain the value of one Dollar
     token == 1 USD

* This stablecoin has the properties :
   - Exogenous Collateral
   - Dollar Pegged
   - Algorithmic Stable

 * It is similar to DAI if DAI had no governance , no fees and was only backed by wETH and wBTC.
 *
 * @notice This contract is the core of the PURE StableCoin
 */