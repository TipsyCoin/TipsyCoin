// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenTimelock {

    function initialize(address token_, address beneficiary_, uint256 releaseTime_) external;

    function token() external view returns (address);

    function beneficiary() external view returns (address);

    function releaseTime() external view returns (uint256);

    function release() external;

    }
