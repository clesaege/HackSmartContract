// You can store ETH in this contract and redeem them.
contract VaultInvariant {
    mapping(address => uint) public balances;
    uint public totalBalance;

    /// @dev Store ETH in the contract.
    function store() payable {
        balances[msg.sender]+=msg.value;
        totalBalance+=msg.value;
    }
    
    /// @dev Redeem your ETH.
    function redeem() {
        uint toTranfer = balances[msg.sender];
        msg.sender.transfer(toTranfer);
        balances[msg.sender]=0;
        totalBalance-=toTranfer;
    }
    
    /// @dev Let a user get all funds if an invariant is broken.
    function invariantBroken() {
        require(totalBalance!=this.balance);
        
        msg.sender.transfer(this.balance);
    }
    
}
