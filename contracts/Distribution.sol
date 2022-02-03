//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Distribution is Ownable, Initializable, ReentrancyGuard {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event PayeeAdded(address account, uint256 shares);
    event PayeeModified(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);

    IERC20Upgradeable internal paymentToken;
    uint256 internal _totalShares;
    uint256 internal _totalTokenReleased;
    address[] internal _payees;
    mapping(address => uint256) internal _shares;
    mapping(address => uint256) internal _tokenReleased;

    function initialize(address[] memory payees, uint256[] memory shares_, IERC20Upgradeable _paymentToken) external initializer {
        require(
            payees.length == shares_.length,
            "TokenPaymentSplitter: payees and shares length mismatch"
        );
        require(payees.length > 0, "TokenPaymentSplitter: no payees");
        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
        paymentToken = _paymentToken;
    }

    function totalShares() external view returns (uint256) {
        return _totalShares;
    }

    function shares(address account) external view returns (uint256) {
        return _shares[account];
    }

    function payee(uint256 index) external view returns (address) {
        return _payees[index];
    }

    function _release(uint256 tokens, address account) internal nonReentrant {
        require(
            _shares[account] > 0,
            "TokenPaymentSplitter: account has no shares"
        );

        uint256 payment = (tokens * _shares[account]) /
            _totalShares;

        require(
            payment != 0,
            "TokenPaymentSplitter: account is not due payment"
        );

        _tokenReleased[account] = _tokenReleased[account] + payment;
        _totalTokenReleased = _totalTokenReleased + payment;

        IERC20Upgradeable(paymentToken).safeTransfer(account, payment);
        emit PaymentReleased(account, payment);
    }

    function release_all() external {
        uint256 tokensNow = IERC20Upgradeable(paymentToken).balanceOf(
            address(this)
        );
        
        for(uint256 i = 0; i < _payees.length; i++) {
            _release(tokensNow, _payees[i]);
        }
    }

    function _addPayee(address account, uint256 shares_) internal {
        require(
            account != address(0),
            "TokenPaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "TokenPaymentSplitter: shares are 0");
        require(
            _shares[account] == 0,
            "TokenPaymentSplitter: account already has shares"
        );
        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    function addNewPayee(address account, uint256 shares_) external onlyOwner {
        _addPayee(account, shares_);
    }

    function adjustWeight(address account, uint256 shares_) external onlyOwner {
        require(
            account != address(0),
            "TokenPaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "TokenPaymentSplitter: shares are 0");
        require(
            _shares[account] > 0,
            "TokenPaymentSplitter: account does not have any shares"
        );
        uint256 oldshares = _shares[account];
        _shares[account] = shares_;

        _totalShares = _totalShares - oldshares;
        _totalShares = _totalShares + shares_;

        emit PayeeModified(account, shares_);
    }


}
