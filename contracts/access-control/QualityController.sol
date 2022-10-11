// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Roles.sol";

contract QualityControllerRole {
    using Roles for Roles.Role;

    event QualityControllerAdded(address indexed account);
    event QualityControllerRemoved(address indexed account);

    Roles.Role private qualityControllers;

    constructor() {
        _addQualityController(msg.sender);
    }

    modifier onlyQualityController() {
        require(isQualityController(msg.sender));
        _;
    }

    function isQualityController(address account) public view returns (bool) {
        return qualityControllers.has(account);
    }

    function addQualityController(address account) public onlyQualityController {
        _addQualityController(account);
    }

    function renounceQualityController() public {
        _removeQualityController(msg.sender);
    }

    function _addQualityController(address account) internal {
        qualityControllers.add(account);
        emit QualityControllerAdded(account);
    }

    function _removeQualityController(address account) internal {
        qualityControllers.remove(account);
        emit QualityControllerRemoved(account);
    }
}
