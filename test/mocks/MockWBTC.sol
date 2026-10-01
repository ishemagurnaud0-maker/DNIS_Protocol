//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MockWBTC is ERC20 {

    constructor() ERC20("Wrapped BTC", "WBTC") {}

    
    /*
    * @notice The normal decimals function for ERC20s returns 18 but for standard Wrapped BTC it must return only 8 for precision
     */    

    function decimals() public view virtual override returns(uint256) {
        return 8;
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}