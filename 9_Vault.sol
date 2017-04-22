
// You can store ETH in this contract and redeem them.
contract Vault {
    mapping(address => uint) public balances;

    /// @dev Store ETH in the contract.
    function store() payable {
        balances[msg.sender]+=msg.value;
    }

    /// @dev Redeem your ETH.
    function redeem() {
        msg.sender.send(balances[msg.sender]);
        balances[msg.sender]=0;
    }
}
