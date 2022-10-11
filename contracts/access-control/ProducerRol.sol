// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Roles.sol";

contract ProducerRole {
    /** using is used for including a library within a contract in solidity */
    using Roles for Roles.Role;

    // Define 2 events, one for Adding, and other for Removing
    event ProducerAdded(address indexed account);
    event ProducerRemoved(address indexed account);

    // Define a struct 'producers' by inheriting from 'Roles' library, struct Role
    Roles.Role private producers;

    constructor() {
        _addProducer(msg.sender);
    }

    // Define a modifier that checks to see if msg.sender has the appropriate role
    modifier onlyProducer() {
        require(isProducer(msg.sender));
        _;
    }

    // Define a function 'isFarmer' to check this role
    function isProducer(address account) public view returns (bool) {
        return producers.has(account);
    }

    // Define a function 'addProducer' that adds this role
    function addProducer(address account) public onlyProducer {
        _addProducer(account);
    }

    // Define a function 'renounceFarmer' to renounce this role
    function renounceProducer() public {
        _removeProducer(msg.sender);
    }

    // Define an internal function '_addProducer' to add this role, called by 'addFarmer'
    function _addProducer(address account) internal {
        producers.add(account);
        emit ProducerAdded(account);
    }

      // Define an internal function '_removeProducer' to remove this role, called by 'renounceProducer'
    function _removeProducer(address account) internal {
        producers.remove(account);
        emit ProducerRemoved(account);
    }
}
