// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./IPancake.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
	//transfer to non 0 addy during constructor when deploying 4real to prevent our base contracts being taken over. Ensures only our proxy is usable
        //_transferOwnership(address(~uint160(0)));
        _transferOwnership(address(uint160(0)));
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _transferOwnership(address(0x000000000000000000000000000000000000dEaD));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function initOwnership(address newOwner) public virtual {
        require(_owner == address(0), "Ownable: owner already set");
        require(newOwner != address(0), "Ownable: new owner can't be 0 address");
        _owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
    }

}

interface WethLike {
function deposit() external payable;
function withdraw(uint256) external;
}

contract TipsyBuyBack is Ownable, Initializable {

using SafeERC20 for IERC20;

address public WETH;
address public pancakeSwapRouter02;
IPancakeRouter02 public pancakeV2Router;
address public lpTimelock;
address public tipsy;
uint public burnAmount;
uint public reflectAmount;
uint public liquidityAmount;
uint public totalBuyBackWeight;
address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

event BuybackWeightsAdjusted(uint indexed newBurn, uint indexed newReflect, uint indexed newLiquidity);


    constructor(address _tipsyCoin) payable
    {   //this is just for testing
        //address bigbeef = 0xbeefa0b80F7aC1f1a5B5a81C37289532c5D85e88;
        address pancakeTest = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        address lpLocker = 0x98c1F42c7Fb70768d3163253872d8eB655379deD;
        address tipsyCoin = _tipsyCoin;
        // owner_, _pancakeSwapRouter02, _tipsy, _lpTimelock, _burnAmount, _reflectAmount, _liquidityAmount) public initializer
        initialize(msg.sender, pancakeTest, tipsyCoin, lpLocker, 0, 0, 1000);
    }

    function BuyBack(uint _amount) external onlyOwner returns (bool)
    {
        require(IERC20(pancakeV2Router.WETH()).balanceOf(address(this)) >= _amount, "tipsy: proposed amount > WBNB balance");
        uint _reflectAmount = _amount * reflectAmount / totalBuyBackWeight;
        uint _burnAmount = _amount * burnAmount / totalBuyBackWeight;
        uint _liquidityAmount = _amount * liquidityAmount / totalBuyBackWeight;
        if (_burnAmount > 0) require(burn(_burnAmount), "tipsy: burn failed");
        if (_reflectAmount > 0) require(reflect(_reflectAmount), "tipsy: reflect failed");
        if (_liquidityAmount > 0) require(addLiquidity(_liquidityAmount), "tipsy: add liquidity failed");
        return true;
    }

    function burn(uint _amount) internal returns (bool)
    {   
        require(_amount >= 1e9, "tipsy: don't burn with < 1 gwei of BNB");
        IERC20 token = IERC20(tipsy);
        address[] memory _WETHTokenPath = new address[](2);
        _WETHTokenPath[0] = pancakeV2Router.WETH();
        _WETHTokenPath[1] = tipsy;
        IERC20(_WETHTokenPath[0]).safeApprove(pancakeSwapRouter02, _amount);
        uint _soldtipsy = pancakeV2Router.swapExactTokensForTokens(_amount, 1, _WETHTokenPath, address(this), block.timestamp)[1];
        token.safeTransfer(DEAD_ADDRESS, _soldtipsy);
        return true;
    }

    function reflect(uint _amount) internal returns (bool)
    {
        require(_amount >= 1e9, "tipsy: don't reflect with < 1 gwei of BNB");
        IERC20 token = IERC20(tipsy);
        address[] memory _WETHTokenPath = new address[](2);
        _WETHTokenPath[0] = WETH;
        _WETHTokenPath[1] = tipsy;
        IERC20(_WETHTokenPath[0]).safeApprove(pancakeSwapRouter02, _amount);
        uint _soldtipsy = pancakeV2Router.swapExactTokensForTokens(_amount, 1, _WETHTokenPath, address(this), block.timestamp)[1];
        token.safeTransfer(address(0), _soldtipsy);
        return true;
    }

    function addLiquidity(uint _amount) internal returns (bool)
    {
        require(_amount >= 2e9, "tipsy: don't add liquidity with < 2 gwei of BNB");
        uint _halfAmount = _amount/2;
        address[] memory _WETHTokenPath = new address[](2);
        _WETHTokenPath[0] = WETH;
        _WETHTokenPath[1] = tipsy;
        IERC20(_WETHTokenPath[0]).safeApprove(pancakeSwapRouter02, _amount);
        uint _soldtipsy = pancakeV2Router.swapExactTokensForTokens(_halfAmount, 1, _WETHTokenPath, address(this), block.timestamp)[1];
        (,,uint _lpAdded) = pancakeV2Router.addLiquidity(_WETHTokenPath[0], _WETHTokenPath[1], _halfAmount, _soldtipsy, 1, 1, lpTimelock, block.timestamp);
        require (_lpAdded > 0, "tipsy: no LP tokens minted");
        return true;
    }

    function initialize(address owner_, address _pancakeSwapRouter02, address _tipsy, address _lpTimelock, uint256 _burnAmount, uint256 _reflectAmount, uint256 _liquidityAmount) public initializer
    {   
        require(owner_ != address(0), "tipsy: owner can't be 0 address");
        require(_pancakeSwapRouter02 != address(0), "tipsy: PancakeswapRouter02 can't be 0 address");
        require(_tipsy != address(0), "tipsy: Tipsy can't be 0 address");
        require(_lpTimelock != address(0), "tipsy: Timelock can't be 0 address");
        initOwnership(owner_);
        pancakeSwapRouter02 = _pancakeSwapRouter02;
        pancakeV2Router =  IPancakeRouter02(pancakeSwapRouter02);
        lpTimelock = _lpTimelock;
        burnAmount = _burnAmount;
        reflectAmount = _reflectAmount;
        liquidityAmount = _liquidityAmount;
        totalBuyBackWeight = reflectAmount + liquidityAmount + burnAmount;
        require(totalBuyBackWeight >= 1000, "tipsy: to avoiding division rounding errors, buyback weight sum must be >= 1000");
        tipsy = _tipsy;
        WETH = pancakeV2Router.WETH();

    }

    function adjustWeights(uint256 _burnAmount, uint256 _reflectAmount, uint256 _liquidityAmount) external onlyOwner
    {
        require(_burnAmount + _reflectAmount + _liquidityAmount == totalBuyBackWeight, "tipsy: total weight may not change");
        burnAmount = _burnAmount;
        reflectAmount = _reflectAmount;
        liquidityAmount = _liquidityAmount;
        emit BuybackWeightsAdjusted(_burnAmount, _reflectAmount, _liquidityAmount);
    }

    function salvage(address _token) external onlyOwner
    {   
        IERC20 token = IERC20(_token);
        require (_token != WETH, "tipsy: cannot salvage WETH, it must be used for buyback");
        //Maybe??? -> require (_token != tipsy, "tipsy: cannot salvage tipsy");
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }
}