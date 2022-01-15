// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenVesting {

    function initialize(address beneficiary_, uint256 start_, uint256 duration_, bool revocable_) external;

    function beneficiary() external view returns (address);

    function start() external view returns (uint256);

    function duration() external view returns (uint256);

    function revocable() external view returns (uint256);

    function released(address token) external view returns (uint256);

    function revoked(address token) external view returns (bool);

    function release(address token) external;

    function revoke(address token) external;

    function vested(address token) external view returns (uint256);

    function _releasableAmount(address token) external view returns (uint256);

    function _vestedAmount(address token) external view returns (uint256);


    }
