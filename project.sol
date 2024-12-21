// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function mint(address account, uint256 amount) external;
}

contract StudyGuideIncentives {

    // ERC-20 token interface for the reward system
    IERC20 public rewardToken;

    // Mapping to store information about study guides
    struct StudyGuide {
        uint id;
        address creator;
        string topic;
        string content;  // Content of the guide (could be a URL or text)
        uint voteCount;
        uint rewardAmount;
        bool isApproved;
    }

    uint public guideCount;
    mapping(uint => StudyGuide) public studyGuides;
    mapping(address => mapping(uint => bool)) public userVotes;

    address public admin;  // Admin address for managing the contract

    // Event declarations
    event StudyGuideSubmitted(uint guideId, address creator, string topic);
    event StudyGuideVoted(uint guideId, address voter, uint voteCount);
    event RewardDistributed(uint guideId, address creator, uint rewardAmount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not an admin");
        _;
    }

    modifier onlyCreator(uint guideId) {
        require(msg.sender == studyGuides[guideId].creator, "Not the creator");
        _;
    }

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
        admin = msg.sender;
        guideCount = 0;
    }

    // Function to submit a new study guide
    function submitStudyGuide(string memory topic, string memory content) public {
        uint guideId = guideCount++;
        studyGuides[guideId] = StudyGuide({
            id: guideId,
            creator: msg.sender,
            topic: topic,
            content: content,
            voteCount: 0,
            rewardAmount: 0,
            isApproved: false
        });

        emit StudyGuideSubmitted(guideId, msg.sender, topic);
    }

    // Function for voting on a study guide
    function voteOnGuide(uint guideId) public {
        require(guideId < guideCount, "Study guide does not exist");
        require(!userVotes[msg.sender][guideId], "You have already voted on this guide");

        userVotes[msg.sender][guideId] = true;
        studyGuides[guideId].voteCount++;

        emit StudyGuideVoted(guideId, msg.sender, studyGuides[guideId].voteCount);
    }

    // Function to approve a study guide and determine its reward amount
    function approveStudyGuide(uint guideId, uint rewardAmount) public onlyAdmin {
        require(guideId < guideCount, "Study guide does not exist");
        require(!studyGuides[guideId].isApproved, "Guide already approved");

        studyGuides[guideId].isApproved = true;
        studyGuides[guideId].rewardAmount = rewardAmount;

        emit RewardDistributed(guideId, studyGuides[guideId].creator, rewardAmount);
    }

    // Function to distribute rewards to the creator of an approved guide
    function distributeReward(uint guideId) public {
        require(guideId < guideCount, "Study guide does not exist");
        require(studyGuides[guideId].isApproved, "Guide not approved");
        require(studyGuides[guideId].rewardAmount > 0, "No reward to distribute");

        uint reward = studyGuides[guideId].rewardAmount;
        address creator = studyGuides[guideId].creator;

        // Transfer reward tokens to the creator
        rewardToken.transfer(creator, reward);

        // Reset the reward amount after distribution
        studyGuides[guideId].rewardAmount = 0;
    }

    // Function to mint reward tokens (only accessible by admin)
    function mintRewardTokens(address recipient, uint256 amount) public onlyAdmin {
        rewardToken.mint(recipient, amount);
    }

    // Function to check balance of a creator
    function getCreatorBalance(uint guideId) public view returns (uint) {
        require(guideId < guideCount, "Study guide does not exist");
        return studyGuides[guideId].rewardAmount;
    }
}
