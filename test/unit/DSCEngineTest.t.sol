// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import { ERC20Mock } from "@openzeppelin/contracts/mocks/ERC20Mock.sol"; Updated mock location
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
// import { MockMoreDebtDSC } from "../mocks/MockMoreDebtDSC.sol";
// import { MockFailedMintDSC } from "../mocks/MockFailedMintDSC.sol";
// import { MockFailedTransferFrom } from "../mocks/MockFailedTransferFrom.sol";
// import { MockFailedTransfer } from "../mocks/MockFailedTransfer.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DSCEngineTest is StdCheats, Test {
    DSCEngine public dsce;
    DecentralizedStableCoin public dsc;
    HelperConfig public helperConfig;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;
    uint256 public deployerKey;
    address public user = makeAddr("user");
    address public liquidator = makeAddr("liquidator");

    uint256 amountCollateral = 10 ether;
    uint256 amountDscToMint = 100e18;
    uint256 amountToRedeem = 0.1e18;
    uint256 amountToBurn = 50e18;

    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployDSC deployer = new DeployDSC();
        (dsc, dsce, helperConfig) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc, deployerKey) = helperConfig.activeNetworkConfig();
        if (block.chainid == 31337) {
            vm.deal(user, STARTING_USER_BALANCE);
        }
        ERC20Mock(weth).mint(user, STARTING_USER_BALANCE);
        ERC20Mock(wbtc).mint(user, STARTING_USER_BALANCE);
    }

    ///////////////////////
    // Constructor Tests //
    ///////////////////////
    address[] public tokenAddresses;
    address[] public feedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        feedAddresses.push(ethUsdPriceFeed);
        feedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, feedAddresses, address(dsc));
    }

    //////////////////
    // Price Tests //
    //////////////////

    function testGetTokenAmountFromUsd() public view {
        // If we want $100 of WETH @ $2000/WETH, that would be 0.05 WETH
        uint256 expectedWeth = 0.05 ether;
        uint256 amountWeth = dsce.getTokenAmountFromUsd(weth, 100 ether);
        assertEq(amountWeth, expectedWeth);
    }

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        // 15e18 ETH * $2000/ETH = $30,000e18
        uint256 expectedUsd = 30000e18;
        console.log("Expected USD Value:", expectedUsd);
        uint256 usdValue = dsce.getUsdValue(weth, ethAmount);
        assertEq(usdValue, expectedUsd);
    }

    ///////////////////////////////////////
    // depositCollateral Tests //
    ///////////////////////////////////////

    modifier depositedCollateral() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(weth, amountCollateral);
        vm.stopPrank();
        _;
    }

    modifier depositedCollateralAndMint() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral);
        dsce.depositCollateralAndMintDsc(weth, amountCollateral, amountDscToMint);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralWithoutMinting() public depositedCollateral {
        uint256 userBalance = dsc.balanceOf(user);
        assertEq(userBalance, 0);
    }

    function testCanDepositeCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(user);
        uint256 expectedDepositedAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(totalDscMinted, 0);
        assertEq(expectedDepositedAmount, amountCollateral);
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock randToken = new ERC20Mock("RAN", "RAN", user, amountCollateral);
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__TokenNotAllowed.selector, address(randToken)));
        dsce.depositCollateral(address(randToken), amountCollateral);
        vm.stopPrank();
    }

    function testRevertsIfCollateralZero() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testCanDepositCollateralAndMintDsc() public depositedCollateralAndMint {
        uint256 dscBalance = dsc.balanceOf(user);
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(user);
        uint256 expectedCollateralInUsd = dsce.getUsdValue(weth, amountCollateral);

        assertEq(dscBalance, amountDscToMint, "DSC balance mismatch after minting");
        assertEq(totalDscMinted, amountDscToMint, "Total DSC minted mismatch");
        assertEq(collateralValueInUsd, expectedCollateralInUsd);
    }

    function testCanRedeemCollateral() public depositedCollateralAndMint {
        // step 1: Deposit and Mint
        // step 2: Redeem a portion of collateral
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral);
        dsce.redeemCollateral(weth, amountToRedeem);
        vm.stopPrank();

        // Step 3: Check that collateral is reduced
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(user);
        uint256 expectedCollateralAfterRedemption = dsce.getUsdValue(weth, amountCollateral - amountToRedeem);
        assertEq(totalDscMinted, amountDscToMint, "DSC debt should remain the same");
        assertApproxEqAbs(collateralValueInUsd, expectedCollateralAfterRedemption, 1e10);
    }

    function testCanBurnDscAndReduceDebt() public {
        uint256 amountToMint = 200e18;

        // Start acting as the user
        vm.startPrank(user);

        // Approve and deposit collateral
        ERC20Mock(weth).approve(address(dsce), amountCollateral);
        dsce.depositCollateralAndMintDsc(weth, amountCollateral, amountToMint);

        // Sanity check: user received DSC
        assertEq(dsc.balanceOf(user), amountToMint);
        console.log("User's DSC balance before burn: => 180", dsc.balanceOf(user));

        // Approve DSCEngine to spend user's DSC before burning
        dsc.approve(address(dsce), amountToBurn);

        dsce.burnDsc(amountToBurn);

        vm.stopPrank();

        // Post-conditions
        uint256 expectedBalance = amountToMint - amountToBurn;
        console.log("Expected DSC balance after burn: => 181", expectedBalance);
        uint256 userBalance = dsc.balanceOf(user);
        (uint256 totalDscMinted,) = dsce.getAccountInformation(user);

        assertEq(userBalance, expectedBalance, "User's DSC balance should be reduced");
        assertEq(totalDscMinted, expectedBalance, "User's debt should be reduced");
    }

    function testBurnDscRevertsIfNotApproved() public {
        uint256 amountToMint = 100e18;

        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral);
        dsce.depositCollateralAndMintDsc(weth, amountCollateral, amountToMint);

        // Do NOT approve DSC for burn — should revert
        vm.expectRevert();
        dsce.burnDsc(amountToBurn);
        vm.stopPrank();
    }

    function testCanRedeemCollateralForDsc() public {
        uint256 amountToMint = 200e18;
        uint256 _amountToRedeem = 0.05e18; // Equivalent to ~$100 assuming 1 WETH = $2000

        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral);
        dsce.depositCollateralAndMintDsc(weth, amountCollateral, amountToMint);

        dsc.approve(address(dsce), amountToBurn);

        // Redeem collateral by burning DSC
        dsce.redeemCollateralForDsc(weth, _amountToRedeem, amountToBurn);

        vm.stopPrank();

        (uint256 totalDscMinted, uint256 remainingCollateralUsd) = dsce.getAccountInformation(user);
        uint256 userDscBalance = dsc.balanceOf(user);
        uint256 expectedDscRemaining = amountToMint - amountToBurn;
        uint256 expectedCollateralRemaining = dsce.getUsdValue(weth, amountCollateral - _amountToRedeem);

        assertEq(totalDscMinted, expectedDscRemaining, "DSC debt not updated correctly");
        assertEq(userDscBalance, expectedDscRemaining, "DSC token balance not updated");
        assertApproxEqAbs(remainingCollateralUsd, expectedCollateralRemaining, 1e10);
    }

    function testCanLiquidateUndercollateralizedUser() public {
        uint256 mintAmount = 1000e18;
        uint256 debtToCover = 100e18;
        uint256 userCollateral = 1e18;
        uint256 liquidatorCollateral = 1e18;

        // Step 1: User deposits 1 WETH and mints 1000 DSC (health factor = 1.0)
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), userCollateral);
        dsce.depositCollateralAndMintDsc(weth, userCollateral, mintAmount);
        vm.stopPrank();

        // Simulate price drop: WETH now worth $1500 instead of $2000
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(1500e8); // assuming 8 decimals

        // Step 2: Liquidator setup
        ERC20Mock(weth).mint(liquidator, liquidatorCollateral);
        vm.startPrank(liquidator);
        ERC20Mock(weth).approve(address(dsce), liquidatorCollateral);
        dsce.depositCollateralAndMintDsc(weth, liquidatorCollateral, debtToCover);
        dsc.approve(address(dsce), debtToCover);
        vm.stopPrank();

        // Step 3: Confirm user is undercollateralized
        uint256 startingHF = dsce.getHealthFactor(user);
        assertLt(startingHF, 1e18, "User should be undercollateralized");

        // Step 4: Liquidate
        vm.prank(liquidator);
        dsce.liquidate(weth, user, debtToCover);

        // Step 5: Assert post-liquidation changes
        (uint256 userDscDebtAfter,) = dsce.getAccountInformation(user);
        uint256 expectedDebt = mintAmount - debtToCover;
        assertEq(userDscDebtAfter, expectedDebt, "User's DSC debt not reduced correctly");

        uint256 baseCollateral = dsce.getTokenAmountFromUsd(weth, debtToCover);
        uint256 bonus = (baseCollateral * 10) / 100;
        uint256 totalExpectedCollateral = baseCollateral + bonus;
        uint256 liquidatorBalance = IERC20(weth).balanceOf(liquidator);
        assertEq(liquidatorBalance, totalExpectedCollateral, "Liquidator did not receive correct collateral");

        uint256 endingHF = dsce.getHealthFactor(user);
        assertGt(endingHF, startingHF, "User's health factor should improve after liquidation");
    }
}
