// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ILendingPoolAddressesProvider} from "protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "protocol-v2/contracts/interfaces/ILendingPool.sol";

contract Lending is Ownable {
    ILendingPoolAddressesProvider addressProvider; //0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
    ILendingPool lendingPool; // 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9
    IERC20 assetToken; // DAI - 0x6B175474E89094C44Da98b954EedeAC495271d0F

    uint256 immutable FEE = 10_00;
    uint256 immutable FEE_DIVISOR = 10_000;

    using SafeERC20 for IERC20;

    mapping(address => bool) public tokenAllowed;

    constructor(
        address _asset,
        address _lendingPool,
        address _addressProvider
    ) public Ownable() {
        addressProvider = ILendingPoolAddressesProvider(_addressProvider);
        lendingPool = ILendingPool(_lendingPool);
        assetToken = IERC20(_asset);
    }

    modifier isTokenAllowed(address asset) {
        bool allowed = tokenAllowed[asset];
        require(allowed, "Token not allowed");
        _;
    }

    function _deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external isTokenAllowed(asset) {
        lendingPool.deposit(asset, amount, onBehalfOf, referralCode);
    }

    function _withdraw(
        address asset,
        uint256 amount,
        address to
    ) external isTokenAllowed(asset) returns (uint256) {
        uint256 feeaccured = (amount * FEE) / FEE_DIVISOR;
        uint256 actualAmountToWithdraw = amount - feeaccured;
        lendingPool.withdraw(asset, amount, address(this));
        IERC20(asset).transferFrom(address(this), to, actualAmountToWithdraw);
    }

    function _borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external isTokenAllowed(asset) {
        lendingPool.borrow(
            asset,
            amount,
            interestRateMode,
            referralCode,
            onBehalfOf
        );
    }

    function _repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external isTokenAllowed(asset) {
        lendingPool.repay(asset, amount, rateMode, onBehalfOf);
    }

    function _getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        return lendingPool.getUserAccountData(user);
    }

    function collectFees() external onlyOwner {
        assetToken.transfer(msg.sender, assetToken.balanceOf(address(this)));
    }

    function setAllowedToken(address token, bool allow) public onlyOwner {
        tokenAllowed[token] = allow;
    }

    function getAddressProvider()
        public
        view
        returns (ILendingPoolAddressesProvider)
    {
        return addressProvider;
    }

    function getLendingPool() public view returns (ILendingPool) {
        return lendingPool;
    }

    function getAddressProvider_()
        public
        returns (ILendingPoolAddressesProvider)
    {
        lendingPool.getAddressesProvider();
    }
}
