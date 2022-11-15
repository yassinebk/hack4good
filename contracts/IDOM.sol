// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDOM {
    function updateGovernanceToken(address _newGovernanceToken) external;

    function createGroup(string memory _name, uint16 _shareValue) external;

    function checkGroupMembership(uint256 _groupId, address _member)
        external
        view
        returns (bool);

    function addToGroup(uint256 groupId, address[] memory new_members) external;

    function removeFromGroup(uint256 _groupId, address[] memory _tokick_members)
        external;

    function isMember(address _addressToVerify) external view returns (bool);

    function isShareHolder(address _addressToVerify)
        external
        view
        returns (bool);

    function getGovernanceToken() external view returns (address);

    function getExchangeToken() external view returns (address);
}
