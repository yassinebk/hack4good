// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IDOM.sol";

contract DecentralizedOrganisationManager is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER");
    bytes32 public constant SHAREHOLDER_ROLE = keccak256("SHAREHOLDER");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER");

    uint256 public constant GOV_BASE_AMOUNT = 1;
    uint256 public constant EXC_BASE_AMOUNT = 1;
    uint256 public constant AIRDROP_DELAY = 4 weeks;

    struct Group {
        address[] members;
        string name;
        uint16 shareValue;
    }

    event GroupCreated(string name, uint16 shareValue);
    event MemberAddedToGroup(string name, address member);
    event MemberRemovedFromGroup(string name, address member);
    event ExchangeTokenUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );
    event GovernanceTokenUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    event Airdropped(
        address indexed to,
        uint256 indexed amount,
        uint256 indexed time
    );

    address[] private _shareholders;
    address[] public members;
    uint256 private lastGroupId;

    address public governanceTokenAddress;
    address public exchangeTokenAddress;

    mapping(address => uint256) private lastAirdrop;

    mapping(uint256 => Group) groups;

    modifier onlyOwningShareholders(string memory message) {
        require(hasRole(SHAREHOLDER_ROLE, msg.sender), message);

        _;
    }

    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, msg.sender), "Caller is not an owner");
        _;
    }

    modifier onlyMember(string memory message) {
        require(hasRole(MEMBER_ROLE, msg.sender), message);
        _;
    }

    ///@dev no constructor in upgradable contracts. Instead we have initializers
    function initialize(
        address _governanceTokenAddress,
        address[] memory _owningParties
    ) public initializer {
        ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
        __AccessControl_init();
        _grantRole(OWNER_ROLE, msg.sender);
        for (uint256 i = 0; i < _owningParties.length; i++) {
            _grantRole(SHAREHOLDER_ROLE, _owningParties[i]);
        }
        updateGovernanceToken(_governanceTokenAddress);
    }

    function isShareHolder(address _addressToVerify)
        public
        view
        returns (bool)
    {
        return hasRole(SHAREHOLDER_ROLE, _addressToVerify);
    }

    function isMember(address _addressToVerify) public view returns (bool) {
        return hasRole(MEMBER_ROLE, _addressToVerify);
    }

    function getGovernanceToken() public view returns (address) {
        return governanceTokenAddress;
    }

    function getExchangeToken() public view returns (address) {
        return exchangeTokenAddress;
    }

    function updateGovernanceToken(address _governanceTokenAddress)
        public
        onlyOwningShareholders(
            "Only owning shareholders can update the governance token"
        )
    {
        address oldAddress = governanceTokenAddress;
        governanceTokenAddress = _governanceTokenAddress;

        emit GovernanceTokenUpdated(oldAddress, _governanceTokenAddress);
    }

    function updateExchangeToken(address _exchangeTokenAddress)
        public
        onlyOwningShareholders(
            "Only owning shareholders can update the governance token"
        )
    {
        address oldAddress = exchangeTokenAddress;
        exchangeTokenAddress = _exchangeTokenAddress;
        emit ExchangeTokenUpdated(oldAddress, _exchangeTokenAddress);
    }

    function _setGroups() public {}

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function createGroup(string memory _name, uint16 _shareValue)
        public
        onlyOwningShareholders("Only owning shareholders can create groups")
    {
        groups[lastGroupId] = Group({
            members: new address[](0),
            name: _name,
            shareValue: _shareValue
        });
        lastGroupId++;
        emit GroupCreated(_name, _shareValue);
    }

    function addToGroup(uint256 groupId, address[] memory new_members)
        public
        onlyOwningShareholders(
            "Only owning shareholders can add members to groups"
        )
    {
        for (uint256 index; index < new_members.length; index++) {
            require(
                !checkGroupMembership(groupId, new_members[index]),
                "Member already in group"
            );
            groups[groupId].members.push(new_members[index]);

            emit MemberAddedToGroup(groups[groupId].name, new_members[index]);
        }
    }

    function checkGroupMembership(uint256 _groupId, address _member)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < groups[_groupId].members.length; i++) {
            if (groups[_groupId].members[i] == _member) {
                return true;
            }
        }
        return false;
    }

    function removeFromGroup(uint256 _groupId, address[] memory _tokick_members)
        public
        onlyOwningShareholders(
            "Only owning shareholders can remove members from groups"
        )
    {
        for (uint256 index; index < _tokick_members.length; index++) {
            removeMemberFromGroup(_groupId, _tokick_members[index]);
        }
    }

    function removeMemberFromGroup(uint256 _groupId, address _tockick_member)
        internal
    {
        address[] storage _members = groups[_groupId].members;

        for (uint256 index = 0; index < _members.length; index++) {
            if (_members[index] == _tockick_member) {
                _members[index] = _members[_members.length - 1];
                _members.pop();
                break;
            }
        }
        groups[_groupId].members = members;
        emit MemberRemovedFromGroup(groups[_groupId].name, _tockick_member);
    }

    function airdrop() public onlyMember("Only members can airdrop") {
        require(
            lastAirdrop[msg.sender] + AIRDROP_DELAY > block.timestamp,
            "Airdrop is not available yet"
        );
        for (uint256 i = 1; i < lastGroupId; i++) {
            if (checkGroupMembership(i, msg.sender)) {
                IERC20 exchangeToken = IERC20(exchangeTokenAddress);
                exchangeToken.transfer(
                    msg.sender,
                    groups[i].shareValue * EXC_BASE_AMOUNT
                );
                IERC20 governanceToken = IERC20(governanceTokenAddress);
                governanceToken.transfer(
                    msg.sender,
                    groups[i].shareValue * GOV_BASE_AMOUNT
                );
                lastAirdrop[msg.sender] = block.timestamp;
                emit Airdropped(
                    msg.sender,
                    groups[i].shareValue * (GOV_BASE_AMOUNT + EXC_BASE_AMOUNT),
                    block.timestamp
                );
                break;
            }
        }
    }
}
