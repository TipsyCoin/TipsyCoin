// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

pragma solidity ^0.8.0;


contract BasicTokenContract {
    address public owner;
    string public description;
    
        constructor() {
        owner = address(~uint160(0));
        }
    
    function initialize(address _owner, string memory _description) public {
        require(owner == address(0), "initialized outside of proxy call");
        //require(msg.sender == owner, "not owner");
        owner = _owner;
        description = _description;
    }
    
    
        function sweepTo(IERC20 token, uint256 amount, address target) public
    {
        require(msg.sender == owner, "Not owner");
        //uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "Nothing to sweep");
        require(token.balanceOf(address(this)) >= amount, "Not enough balance!");
        token.transfer(target, amount);
    }
    
        function withdrawTo(address target) public
    {
        require(msg.sender == owner, "Not owner");
        require(address(this).balance > 0, "Nothing to withdraw");
        payable(target).transfer(address(this).balance);
    }

    function transferOwnership(address newOwner) public
    {
        require(msg.sender == owner, "Not owner");
        owner = newOwner;
    }

    function updateDescription(string memory newDescription) public
    {
        require(msg.sender == owner, "Not owner");
        description = newDescription;
    }
    
    receive() external payable {}
    
}
