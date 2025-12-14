// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "reactive-lib/abstract-base/AbstractReactive.sol";

import {AutoLooper} from "../aave/AutoLooper.sol";

/// @notice Reactive contract that monitors Chainlink price feeds and manages AutoLooper positions
/// @dev Subscribes to price feed updates and automatically unwinds positions when health factor drops
contract AutoLooperReactive is AbstractReactive {
    uint256 public immutable originChainId;
    address public immutable originFeed;
    uint256 public immutable destinationChainId;
    address public immutable helperContract;

    // AutoLooper parameters
    address public immutable autoLooper;
    address public immutable owner;
    address public immutable recipient;
    AutoLooper.OpenParams public openParams;

    bool public isActive;

    uint256 private constant ANSWER_UPDATED_TOPIC_0 =
        0x0559884fd3a460db3073b7fc896cc77986f16e378210ded43186175bf646fc5f;
    uint64 private constant CALLBACK_GAS_LIMIT = 500000;
    uint64 private constant OPEN_POSITION_GAS_LIMIT = 1000000; // Higher gas for opening position

    event Subscribed(
        address indexed service,
        uint256 indexed chainId,
        address indexed feed
    );
    event PositionOpenInitiated(AutoLooper.OpenParams params);
    event HealthCheckInitiated(
        uint80 indexed roundId,
        int256 answer,
        uint256 updatedAt
    );
    event PositionClosed();
    event PositionOpenFailed(string reason);

    constructor(
        address _originFeed,
        uint256 _originChainId,
        uint256 _destinationChainId,
        address _helperContract,
        address _autoLooper,
        address _owner,
        address _recipient,
        AutoLooper.OpenParams memory _openParams
    ) {
        require(_originFeed != address(0), "bad origin feed");
        require(_helperContract != address(0), "bad helper contract");
        require(_autoLooper != address(0), "bad autolooper");
        require(_owner != address(0), "bad owner");
        require(_recipient != address(0), "bad recipient");

        originFeed = _originFeed;
        originChainId = _originChainId;
        destinationChainId = _destinationChainId;
        helperContract = _helperContract;
        autoLooper = _autoLooper;
        owner = _owner;
        recipient = _recipient;
        openParams = _openParams;
        isActive = false;

        if (!vm) {
            service.subscribe(
                originChainId,
                _originFeed,
                ANSWER_UPDATED_TOPIC_0,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            );

            emit Subscribed(address(service), originChainId, _originFeed);
        }
    }

    /// @notice React to price feed updates
    /// @dev On first update after deployment, opens position. On subsequent updates, checks health factor.
    function react(LogRecord calldata log) external override {
        if (
            log.chain_id != originChainId ||
            log._contract != originFeed ||
            log.topic_0 != ANSWER_UPDATED_TOPIC_0
        ) {
            return;
        }

        int256 answer = int256(log.topic_1);
        uint80 roundId = uint80(log.topic_2);
        uint256 updatedAt = abi.decode(log.data, (uint256));

        if (!isActive) {
            _openPosition();
            return;
        }

        emit HealthCheckInitiated(roundId, answer, updatedAt);

        bytes memory payload = abi.encodeWithSignature("checkAndUnwind()");

        emit Callback(
            destinationChainId,
            helperContract,
            CALLBACK_GAS_LIMIT,
            payload
        );
    }

    /// @notice Internal function to initiate position opening
    function _openPosition() internal {
        emit PositionOpenInitiated(openParams);

        bytes memory payload = abi.encodeWithSignature(
            "openPositionForReactive((uint256,uint8,uint16,uint256,uint256))",
            openParams
        );

        emit Callback(
            destinationChainId,
            helperContract,
            OPEN_POSITION_GAS_LIMIT,
            payload
        );

        isActive = true;
    }

    /// @notice Get configuration
    function getConfig()
        external
        view
        returns (
            uint256 _originChainId,
            address _originFeed,
            uint256 _destinationChainId,
            address _helperContract,
            address _autoLooper,
            address _owner,
            address _recipient,
            bool _isActive,
            uint64 _callbackGasLimit
        )
    {
        return (
            originChainId,
            originFeed,
            destinationChainId,
            helperContract,
            autoLooper,
            owner,
            recipient,
            isActive,
            CALLBACK_GAS_LIMIT
        );
    }

    /// @notice Manually set isActive (for cases where we know position was closed)
    /// @dev This might be called via callback from helper contract in future
    function setActive(bool _active) external {
        isActive = _active;
        if (!_active) {
            emit PositionClosed();
        }
    }
}
