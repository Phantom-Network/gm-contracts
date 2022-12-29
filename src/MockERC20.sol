//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract MockERC20 is ERC20 {

    /**
     * @dev Constructor that gives _msgSender() all of existing tokens.
     */
    constructor (address to) ERC20("Mock USDC", "USDC") {
        _mint(to, 10000 * (10 ** uint256(decimals())));
    }

    /** 
     * @dev Returns the decimals of the token, overriden to 6
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}