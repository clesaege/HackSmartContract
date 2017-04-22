

// You can buy tokens.
// The owner can set the price.
contract BuyToken {
    mapping(address => uint) public balances;
    uint public price=1;
    address public owner=msg.sender;

    /** @dev Buy tokens.
     *  @param _amount The amount to buy.
     *  @param _price  The maximum price to buy those in ETH.
     */
    function buyVotes(uint _amount, uint _price) payable {
        require(_price>=price); // The price is at least the current price.
        
        require(_amount > 0);
        require(_price * _amount / _amount == _price);
        require(_price * _amount * 1 ether /  1 ether == _price * _amount);
        
        require(_price * _amount * 1 ether <= msg.value); // You have paid at least the total price.
        balances[msg.sender]+=_amount;
    }

    /** @dev Set the price, only the owner can do it.
     *  @param _price The new price.
     */
    function setPrice(uint _price) {
        require(msg.sender==owner);

        price=_price;
    }
}
