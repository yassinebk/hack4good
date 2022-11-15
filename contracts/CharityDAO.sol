// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IDOM.sol";

contract CharityDAO is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeMath for uint256;

    uint32 constant minimumVotingPeriod = 1 weeks;

    address public governanceContractAddress;
    IDOM private _DOM;

    uint256 numOfProposals;

    mapping(address => uint256) balances;

    function initialize(address _governanceContractAddress) public initializer {
        governanceContractAddress = _governanceContractAddress;
        _DOM = IDOM(governanceContractAddress);
        numOfProposals = 1;
        __Ownable_init();
    }

    mapping(uint256 => mapping(address => uint256)) contributions;

    struct CharityProposal {
        uint256 id;
        uint256 amount;
        uint256 livePeriod;
        uint256 votesFor;
        uint256 votesAgainst;
        string description;
        bool votingPassed;
        bool paid;
        address payable charityAddress;
        address proposer;
        address paidBy;
    }

    mapping(uint256 => CharityProposal) private charityProposals;
    mapping(address => uint256[]) private MemberVotes;
    mapping(address => uint256) private contributors;
    mapping(address => uint256) private Members;

    event ContributionReceived(address indexed fromAddress, uint256 amount);
    event NewCharityProposal(address indexed proposer, uint256 amount);
    event PaymentTransfered(
        address indexed Member,
        address indexed charityAddress,
        uint256 amount
    );

    modifier onlyMember(string memory message) {
        require(_DOM.isMember(msg.sender), message);
        _;
    }

    function createProposal(
        string calldata description,
        address charityAddress,
        uint256 amount
    ) external onlyMember("Only Members are allowed to create proposals") {
        CharityProposal storage proposal = charityProposals[numOfProposals];
        proposal.id = numOfProposals;
        proposal.proposer = payable(msg.sender);
        proposal.description = description;
        proposal.charityAddress = payable(charityAddress);
        proposal.amount = amount;
        proposal.livePeriod = block.timestamp + minimumVotingPeriod;

        numOfProposals++;

        IERC20 token = IERC20(_DOM.getGovernanceToken());

        token.transferFrom(address(this), msg.sender, getProposalPrice());

        emit NewCharityProposal(msg.sender, amount);
    }

    function vote(uint256 proposalId, bool supportProposal)
        external
        onlyMember("Only Members are allowed to vote")
    {
        CharityProposal storage charityProposal = charityProposals[proposalId];

        votable(charityProposal);

        if (supportProposal) charityProposal.votesFor++;
        else charityProposal.votesAgainst++;

        MemberVotes[msg.sender].push(charityProposal.id);
    }

    function votable(CharityProposal storage charityProposal) private {
        if (
            charityProposal.votingPassed ||
            charityProposal.livePeriod <= block.timestamp
        ) {
            charityProposal.votingPassed = true;
            revert("Voting period has passed on this proposal");
        }

        uint256[] memory tempVotes = MemberVotes[msg.sender];
        for (uint256 votes = 0; votes < tempVotes.length; votes++) {
            if (charityProposal.id == tempVotes[votes])
                revert("This Member already voted on this proposal");
        }
    }

    function payCharity(uint256 proposalId)
        external
        onlyMember("Only Members are allowed to make payments")
    {
        CharityProposal storage charityProposal = charityProposals[proposalId];

        if (charityProposal.paid)
            revert("Payment has been made to this charity");

        if (charityProposal.votesFor <= charityProposal.votesAgainst)
            revert(
                "The proposal does not have the required amount of votes to pass"
            );

        charityProposal.paid = true;
        charityProposal.paidBy = msg.sender;

        emit PaymentTransfered(
            msg.sender,
            charityProposal.charityAddress,
            charityProposal.amount
        );

        return charityProposal.charityAddress.transfer(charityProposal.amount);
    }

    function getProposals()
        public
        view
        returns (CharityProposal[] memory props)
    {
        props = new CharityProposal[](numOfProposals);

        for (uint256 index = 0; index < numOfProposals; index++) {
            props[index] = charityProposals[index];
        }
    }

    function getProposal(uint256 proposalId)
        public
        view
        returns (CharityProposal memory)
    {
        return charityProposals[proposalId];
    }

    function getMemberVotes()
        public
        view
        onlyMember("User is not a Member")
        returns (uint256[] memory)
    {
        return MemberVotes[msg.sender];
    }

    function getMemberBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function isContributor(uint256 proposalId) public view returns (bool) {
        if (contributions[proposalId][msg.sender] > 0) return true;
        return false;
    }

    function contributeTo(uint256 amount, uint256 proposalId) public payable {
        require(
            amount <= contributors[msg.sender],
            "User does not have enough funds to contribute"
        );

        contributions[proposalId][msg.sender] = contributions[proposalId][
            msg.sender
        ].add(amount);

        balances[msg.sender] = balances[msg.sender].sub(amount);

        IERC20 DAOToken = IERC20(_DOM.getGovernanceToken());
        DAOToken.transfer(msg.sender, getReward(amount));
        // TODO emit event
    }

    function getReward(uint256 contribution) public pure returns (uint256) {
        return contribution.div(100);
    }

    function getProposalPrice() internal view returns (uint256) {
        return 1;
    }
}
