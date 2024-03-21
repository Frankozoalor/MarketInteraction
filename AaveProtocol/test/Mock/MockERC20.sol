pragma solidity ^0.6.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() public ERC20("name", "AVT") {
        _mint(msg.sender, 100e18);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function getTotalSupply() external returns (uint256) {
        return totalSupply();
    }
}
