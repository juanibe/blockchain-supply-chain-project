// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Roles.sol";

contract ConsumerRole {
    using Roles for Roles.Role;

    event ConsumerAdded(address indexed account);
    event ConsumerRemoved(address indexed account);

    Roles.Role private consumers;

    constructor(){}

    modifier onlyConsumer(){
        require (isConsumer(msg.sender));
        _;
    }

    function isConsumer(address account)public view returns (bool){
        return consumers.has(account);
    }

    function addConsumer(address account) public onlyConsumer {
        _addConsumer(account);
    }

    function renounceConsumer() public {
        _removeConsumer(msg.sender);
    }

    function _addConsumer(address account) internal{
        consumers.add(account);
        emit ConsumerAdded(account);
    }

    function _removeConsumer(address account) internal {
        consumers.remove(account);
        emit ConsumerRemoved(account);
    }
}
