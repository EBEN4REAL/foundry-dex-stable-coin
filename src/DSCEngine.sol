// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { OracleLib, AggregatorV3Interface } from "./libraries/OracleLib.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { DecentralizedStableCoin } from "./DecentralizedStableCoin.sol";

/*
 * @title DSCEngine
 * @author Ebenezer Igbinoba
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of
 * all collateral < the $ backed value of all the DSC.
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 */
contract DSCEngine is ReentrancyGuard {
    // function depositCollateralAndMintDsc(
    //     address tokenCollateralAddress,
    //     uint256 amountCollateral,
    //     uint256 amountDscToMint
    // )
    //     external
    // {
    //     depositCollateral(tokenCollateralAddress, amountCollateral);
    //     mintDsc(amountDscToMint);
    // }

    //  function depositCollateral(
    //     address tokenCollateralAddress,
    //     uint256 amountCollateral
    // )
    //     public
    //     moreThanZero(amountCollateral)
    //     nonReentrant
    //     isAllowedToken(tokenCollateralAddress)
    // {
    //     s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
    //     emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
    //     bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
    //     if (!success) {
    //         revert DSCEngine__TransferFailed();
    //     }
    // }

    // function redeemCollateralForDsc(
    //     address tokenCollateralAddress,
    //     uint256 amountCollateral,
    //     uint256 amountDscToBurn
    // )
    //     external
    //     moreThanZero(amountCollateral)
    //     isAllowedToken(tokenCollateralAddress)
    // {
    //     _burnDsc(amountDscToBurn, msg.sender, msg.sender);
    //     _redeemCollateral(tokenCollateralAddress, amountCollateral, msg.sender, msg.sender);
    //     _revertIfHealthFactorIsBroken(msg.sender);
    // }

    // function redeemCollateral(
    //     address tokenCollateralAddress,
    //     uint256 amountCollateral
    // )
    //     external
    //     moreThanZero(amountCollateral)
    //     nonReentrant
    //     isAllowedToken(tokenCollateralAddress)
    // {
    //     _redeemCollateral(tokenCollateralAddress, amountCollateral, msg.sender, msg.sender);
    //     _revertIfHealthFactorIsBroken(msg.sender);
    // }

    // function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
    //     s_DSCMinted[msg.sender] += amountDscToMint;
    //     _revertIfHealthFactorIsBroken(msg.sender);
    //     bool minted = i_dsc.mint(msg.sender, amountDscToMint);

    //     if (minted != true) {
    //         revert DSCEngine__MintFailed();
    //     }
    // }

    // function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) private {
    //     s_DSCMinted[onBehalfOf] -= amountDscToBurn;

    //     bool success = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn);
    //     // This conditional is hypothetically unreachable
    //     if (!success) {
    //         revert DSCEngine__TransferFailed();
    //     }
    //     i_dsc.burn(amountDscToBurn);
    // }
}