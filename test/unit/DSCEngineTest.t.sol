// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { DeployDSC } from "../../script/DeployDSC.s.sol";
import { DSCEngine } from "../../src/DSCEngine.sol";
import { DecentralizedStableCoin } from "../../src/DecentralizedStableCoin.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
// import { ERC20Mock } from "@openzeppelin/contracts/mocks/ERC20Mock.sol"; Updated mock location
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import { MockV3Aggregator } from "../mocks/MockV3Aggregator.sol";
// import { MockMoreDebtDSC } from "../mocks/MockMoreDebtDSC.sol";
// import { MockFailedMintDSC } from "../mocks/MockFailedMintDSC.sol";
// import { MockFailedTransferFrom } from "../mocks/MockFailedTransferFrom.sol";
// import { MockFailedTransfer } from "../mocks/MockFailedTransfer.sol";
import { Test, console } from "forge-std/Test.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

contract DSCEngineTest is StdCheats, Test {
    DSCEngine public dsce;
    DecentralizedStableCoin public dsc;
    HelperConfig public helperConfig;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;
    uint256 public deployerKey;

    address public user = address(1);

    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployDSC deployer = new DeployDSC();
        (dsc, dsce, helperConfig) = deployer.run();
        console.log("dsce  =>", address(dsce));
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc, deployerKey) = helperConfig.activeNetworkConfig();
        if (block.chainid == 31337) {
            vm.deal(user, STARTING_USER_BALANCE);
        }
    }

    //////////////////
    // Price Tests //
    //////////////////

    // function testGetTokenAmountFromUsd() public {
    //     // If we want $100 of WETH @ $2000/WETH, that would be 0.05 WETH
    //     uint256 expectedWeth = 0.05 ether;
    //     uint256 amountWeth = dsce.getTokenAmountFromUsd(weth, 100 ether);
    //     assertEq(amountWeth, expectedWeth);
    // }

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        // 15e18 ETH * $2000/ETH = $30,000e18
        uint256 expectedUsd = 30000e18;
        console.log("Expected USD Value:", expectedUsd);
        uint256 usdValue = dsce.getUsdValue(weth, ethAmount);
        assertEq(usdValue, expectedUsd);
    }
}