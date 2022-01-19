// contracts/TokenVesting.sol
// SPDX-License-Identifier: Apache-2.0
// Based on Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable, Initializable, ReentrancyGuard {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event TokensReleased(address token, uint256 amount);
    event TokenVestingRevoked(address token);

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private _start;
    uint256 private _duration;

    bool private _revocable;

    mapping (address => uint256) private _released;
    mapping (address => uint256) private _revoked;
    mapping (address => uint256) private _refunded;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param beneficiary_ address of the beneficiary to whom vested tokens are transferred
     * @param start_ the time (as Unix time) at which point vesting starts
     * @param duration_ duration in seconds of the period in which the tokens will vest
     * @param revocable_ whether the vesting is revocable or not
     */
    function initialize(address beneficiary_, uint256 start_, uint256 duration_, bool revocable_) external initializer {
        require(beneficiary_ != address(0), "TokenVesting: beneficiary is the zero address");
        // solhint-disable-next-line max-line-length
        require(duration_ > 0, "TokenVesting: duration is 0");
        // solhint-disable-next-line max-line-length
        require((start_ + duration_) > block.timestamp, "TokenVesting: final time is before current time");

        _beneficiary = beneficiary_;
        _revocable = revocable_;
        _duration = duration_;
        _start = start_;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() external view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() external view returns (uint256) {
        return _start;
    }

    /**
     * @return the duration of the token vesting.
     */
    function duration() external view returns (uint256) {
        return _duration;
    }

    /**
     * @return true if the vesting is revocable.
     */
    function revocable() external view returns (bool) {
        return _revocable;
    }

    /**
     * @return the amount of the token released.
     */
    function released(address token) external view returns (uint256) {
        return _released[token];
    }

    /**
     * @return true if the token is revoked.
     */
    function revoked(address token) external view returns (bool) {
        return (_revoked[token] != 0);
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param token ERC20 token which is being vested
     */
    function release(IERC20Upgradeable  token) external nonReentrant {
        uint256 unreleased = _releasableAmount(token);
        require(unreleased > 0, "TokenVesting: no tokens are due");

        _released[address(token)] = _released[address(token)] + unreleased;

        token.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(address(token), unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param token ERC20 token which is being vested
     */
    function revoke(IERC20Upgradeable token) external onlyOwner {
        require(_revocable, "TokenVesting: cannot revoke");
        require(_revoked[address(token)] == 0, "TokenVesting: token already revoked");

        uint256 balance = token.balanceOf(address(this));

        _revoked[address(token)] = block.timestamp;

        uint256 unreleased = _releasableAmount(token);
        uint256 refund = balance - unreleased;

        _refunded[address(token)] = refund;

        token.safeTransfer(owner(), refund);

        emit TokenVestingRevoked(address(token));
    }

    /**
     * @return the vested amount of the token vesting.
     */
    function vested(IERC20Upgradeable token) external view returns (uint256) {
        return _vestedAmount(token);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param token ERC20 token which is being vested
     */
    function _releasableAmount(IERC20Upgradeable token) internal view returns (uint256) {
        return _vestedAmount(token) - (_released[address(token)]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param token ERC20 token which is being vested
     */
    function _vestedAmount(IERC20Upgradeable token) internal view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance + (_released[address(token)]) + (_refunded[address(token)]);

        if (block.timestamp >= _start + (_duration) && _revoked[address(token)] <1e19) { //covers tipsy dust
            return totalBalance;
        } else if (_revoked[address(token)] > 0) {
            return (totalBalance * (_revoked[address(token)] - (_start)))/(_duration);
        } else {
            return (totalBalance * (block.timestamp - _start))/(_duration);
        }
    }
}