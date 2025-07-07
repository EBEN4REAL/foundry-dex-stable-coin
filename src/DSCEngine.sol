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

    ///////////////////
    // Errors
    ///////////////////
    error DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenNotAllowed(address token);
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactorValue);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    ///////////////////
    // State Variables
    ///////////////////

    /// @dev Mapping of token address to price feed address
    mapping(address collateralToken => address priceFeed) private s_priceFeeds;
    /// @dev Amount of collateral deposited by user
    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_collateralDeposited;

    ///////////////////
    // Events
    ///////////////////

    /**
     * @dev Emitted when collateral is deposited
     * @dev indexed tells the EVM to copy that event parameter into the log’s topic list, 
     * enabling cheap server-side filtering and fast dApp look-ups at the cost of a few extra gas 
     * per event.
     * @param user The address of the user depositing collateral
     * @param token The address of the collateral token
     * @param amount The amount of collateral being deposited
    */
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    // event CollateralRedeemed(address indexed redeemFrom, address indexed redeemTo, address token, uint256 amount); // if redeemFrom != redeemedTo, then it was liquidated

    ///////////////////
    // Modifiers
    ///////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__TokenNotAllowed(token);
        }
        _;
    }

    ///////////////////
    // Functions
    ///////////////////
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }
        // These feeds will be the USD pairs
        // For example ETH / USD or MKR / USD
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            // s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }
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

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral you're depositing
    */
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        public
        moreThanZero(amountCollateral)
        nonReentrant
        isAllowedToken(tokenCollateralAddress)
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        /** @dev IERC20 is a metadata until it is pointed to a real address (tokenCollateralAddress)
         * in this case, it is the address of the ERC20 token contract
        */
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

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