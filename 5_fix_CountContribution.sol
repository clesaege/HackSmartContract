

// Count the total contribution of each user.
// Assume that the one creating the contract contributed 1ETH.
contract CountContribution{
    mapping(address => uint) public contribution;
    uint public totalContributions;
    address owner=msg.sender;

    /// @dev Constructor, count a contribution of 1 ETH to the creator.
    function CountContribution() public {
        recordContribution(owner, 1 ether);
    }

    /// @dev Contribute and record the contribution.
    function contribute() public payable {
        recordContribution(msg.sender, msg.value);
    }

    /** @dev Record a contribution. To be called by CountContribution and contribute.
     *  @param _user The user who contributed.
     *  @param _amount The amount of the contribution.
     */
    function recordContribution(address _user, uint _amount) {
        contribution[_user]+=_amount;
        totalContributions+=_amount;
    }

}
