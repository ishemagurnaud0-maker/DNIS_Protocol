//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


import { ERC20Burnable, ERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/*
* @title Pure StableCoin Contract
* @author ISHEMA Gurnaud
* Collateral: Exogenous(ETH & BTC)
* Minting Stability: Algorithmic
* Relative Stability: Anchored to USD (dollar)

*
* This is the contract met to be governed by the PREngine. This is an ERC20 implementation
  for the ERC20 token.

 */

contract PureStableCoin is ERC20Burnable, Ownable {

    error PureStableCoin__FundsMustBeGreaterFunds();
    error PureStableCoin__InsufficientFunds();
    error PureStableCoin__NotZeroAddress();


    constructor() ERC20("PURE", "PR") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner{
        
    uint256 balance = balanceOf(msg.sender);

    if(_amount <= 0) {
        revert PureStableCoin__FundsMustBeGreaterFunds();
    }

    if(balance < _amount) {
        revert PureStableCoin__InsufficientFunds();
    }

    super.burn(_amount);
}


    function mint(address _to, uint256 _amount) external onlyOwner returns(bool) {
        if(_to == address(0)) {
            revert PureStableCoin__NotZeroAddress();
        }

            if(_amount <= 0) {
                revert PureStableCoin__FundsMustBeGreaterFunds();
            }

            _mint(_to, _amount);

           return true; 
    }



}   