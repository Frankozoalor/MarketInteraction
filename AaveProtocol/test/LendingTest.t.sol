// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {Test, console} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Lending} from "../src/Lending.sol";
import {ILendingPoolAddressesProvider} from "protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "protocol-v2/contracts/interfaces/ILendingPool.sol";
import {MockERC20} from "./Mock/MockERC20.sol";

contract LendingTest is Test {
    address addressProvider = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
    address aaveLendingPool = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address aDai = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;
    address DAI_WHALE = 0x66F62574ab04989737228D18C3624f7FC1edAe14;
    address usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    Lending lending;
    address alice = makeAddr("alice");

    uint256 FEE = 10_00;
    uint256 FEE_DIVISOR = 10_000;

    function setUp() public {
        vm.startPrank(DAI_WHALE);
        lending = new Lending(dai, aaveLendingPool, addressProvider);
        IERC20(dai).approve(address(aaveLendingPool), 1000e18);
        IERC20(dai).transferFrom(DAI_WHALE, address(lending), 1000e18);
        lending.setAllowedToken(dai, true);
        lending.setAllowedToken(usdt, true);
        vm.stopPrank();
    }

    function test_allowedToken() public {
        bool assetToken = lending.tokenAllowed(address(dai));
        assertEq(assetToken, true);
    }

    function test_getAddressProvider() public {
        ILendingPoolAddressesProvider addProvider = lending
            .getAddressProvider_();
        address _addProvider = address(addProvider);
    }

    function test_Deposit() public {
        vm.startPrank(address(lending));
        IERC20(dai).approve(address(aaveLendingPool), 100e18);
        lending._deposit(dai, 70e18, address(lending), 0);
        uint256 AfterDeposit_ContractBalance = IERC20(aDai).balanceOf(
            address(lending)
        );
        assertEq(AfterDeposit_ContractBalance, 70e18);
        vm.stopPrank();
    }

    function test_withdraw() public {
        uint256 amount = 100e18;
        vm.startPrank(address(lending));
        IERC20(dai).approve(address(aaveLendingPool), amount);
        lending._deposit(dai, amount, address(lending), 0);
        uint256 prevContractBalance = IERC20(dai).balanceOf(address(lending));
        // console.log("previousContractBalance", prevContractBalance);
        console.log("previousContractBalance %e", prevContractBalance);
        lending._withdraw(dai, amount, alice);
        uint256 feePercentage = (amount * FEE) / FEE_DIVISOR;
        uint256 currentContractBalance = IERC20(dai).balanceOf(
            address(lending)
        );
        uint256 feeCollected = currentContractBalance - prevContractBalance;
        assertEq(feeCollected, feePercentage);
        vm.stopPrank();
    }

    function test_borrow() public {
        uint256 amount = 500e18;
        vm.startPrank(address(lending));
        IERC20(dai).approve(aaveLendingPool, amount);
        lending._deposit(dai, amount, address(lending), 0);
        lending._borrow(dai, 300e18, 2, 0, address(lending));
        vm.stopPrank();
    }

    function test__getUserAccountData() public {
        uint256 amount = 500e18;
        vm.startPrank(address(lending));
        IERC20(dai).approve(address(aaveLendingPool), amount);
        lending._deposit(dai, amount, address(lending), 0);
        (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) = lending._getUserAccountData(address(lending));
    }
}
