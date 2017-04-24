

// Contract to store and redeem money.
contract Store {
    
    mapping(address => uint) public safes;

    /// @dev Store some ETH.
    function store() payable {
        
        safes[msg.sender] += msg.value;
    }

    /// @dev Take back all the amount stored.
    function take() {
        msg.sender.transfer(safes[msg.sender]);
        safes[msg.sender] = 0;
    }
}
