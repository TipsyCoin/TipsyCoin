// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../contracts/TipsyCoin.sol";
import "../contracts/IPancake.sol";

interface ITipsyCoin is IERC20 {
    function addLiquidity(uint256 releaseTime_) external payable;
    function _rTotal() external returns (uint256);
    function includeInFee(address) external;
    function excludeFromFee(address) external;
    }

contract Helper{
    address immutable tipsycoin ;
    IPancakeRouter02 public pancakeV2Router;
    address public pancakeSwapRouter02 = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    IERC20 public WETH;
    ITipsyCoin public tipsy123;
    //using SafeERC20 for IERC20;

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
            if (_i == 0) {
                return "0";
            }
            uint j = _i;
            uint len;
            while (j != 0) {
                len++;
                j /= 10;
            }
            bytes memory bstr = new bytes(len);
            uint k = len;
            while (_i != 0) {
                k = k-1;
                uint8 temp = (48 + uint8(_i - _i / 10 * 10));
                bytes1 b1 = bytes1(temp);
                bstr[k] = b1;
                _i /= 10;
            }
            return string(bstr);
        }

    function getByteCode1() public pure returns (bytes memory) {
        bytes memory bytecode = type(TipsyCoin).creationCode;
        return bytecode;
    }
    function getCalldata(address token, address benif, uint256 releaseTime) external pure returns (bytes memory) {
        return abi.encodeWithSignature("initialize(address,address,uint256)", token, benif, releaseTime);
    }
    function getCalldataLiq(uint256 releaseTime) external pure returns (bytes memory) {
        return abi.encodeWithSignature("addLiquidity(uint256)", releaseTime);
    }

    function deploy(bytes memory _code) public returns (address addr)
    {
        assembly {
            addr:= create(0,add(_code,0x20), mload(_code))
        }
        require(addr != address(0), "deploy fail");
        return addr;
    }

constructor() payable
{
    tipsycoin = deploy(getByteCode1());
    tipsy123 = ITipsyCoin(tipsycoin);
    //require(tipsy123.balanceOf(address(this)) == 1e27, uint2str(tipsy123.balanceOf(address(this))));
    //tipsy123.transfer(msg.sender, tipsy123.balanceOf(address(this)));
    //IERC20(tipsy123).safeTransfer(DEAD_ADDRESS, tipsy123.balanceOf(address(this)));
    tipsy123.excludeFromFee(address(this));
    tipsy123.addLiquidity{value:address(this).balance}(0);
    tipsy123.includeInFee(address(this));
    testSell();
    testReflection();
}

function testSell() public payable {
    uint _amount = 4e26; //5e26 is max tx size
    require(tipsy123.balanceOf(address(this)) > _amount, "Not enuff tipsy");
    pancakeV2Router = IPancakeRouter02(pancakeSwapRouter02);
    address[] memory _tokenWETHPath = new address[](2);
    _tokenWETHPath[0] = tipsycoin;
    _tokenWETHPath[1] = pancakeV2Router.WETH();
    WETH = IERC20(pancakeV2Router.WETH());
    IERC20(_tokenWETHPath[0]).approve(pancakeSwapRouter02, _amount);
    pancakeV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, 1, _tokenWETHPath, address(this), block.timestamp);
    require(tipsy123._rTotal() > 1e18, "rTotal didn't go up");
} 

function testReflection() public {
    //require(tipsy123.balanceOf(address(this)) > 1, "No tokens");
    //40e27 is my start balance
    require(tipsy123.balanceOf(address(this)) >= 39e27, "Balance, huh?");
    //require(WETH.balanceOf(address(this)) > 1e9, uint2str(WETH.balanceOf(address(this))));
    tipsy123.transfer(DEAD_ADDRESS, 100e18);
    require(tipsy123.balanceOf(DEAD_ADDRESS) > 99e18, "DeadAddy: Wasn't burnt");
    require(tipsy123.totalSupply() <= 100e27 - 100e18, "supply no good"); //uint2str(tipsy123.totalSupply())
    tipsy123.transfer(address(0), 1e27);
    require(tipsy123._rTotal() >= 101e16, uint2str(tipsy123._rTotal()));
    require(tipsy123.totalSupply() <= 100e27 - 100e18, uint2str(tipsy123.totalSupply())); //uint2str(tipsy123.totalSupply())

}
}
