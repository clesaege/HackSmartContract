pragma solidity ^0.8.0;

/* This program is free software. It comes without any warranty, to
the extent permitted by applicable law. You can redistribute it
and/or modify it under the terms of the Do What The Fuck You Want
To Public License, Version 2, as published by Sam Hocevar. See
http://www.wtfpl.net/ for more details. */

/* These contracts are examples of contracts with bugs and vulnerabilities in order to practice your hacking skills.
DO NOT USE THEM OR GET INSPIRATION FROM THEM TO MAKE CODE USED IN PRODUCTION 
You are required to find vulnerabilities where an attacker harms someone else.
Being able to destroy your own stuff is not a vulnerability and should be dealt at the interface level.
*/


//*** Exercice 1 ***//
// Contract to store and redeem money.
contract Store {
    struct Safe {
        address owner;
        uint amount;
    }
    
    Safe[] public safes;
    
    /// @dev Store some ETH.
    function store() public payable {
        safes.push(Safe({owner: msg.sender, amount: msg.value}));
    }
    
    /// @dev Take back all the amount stored.
    function take() public {
        for (uint i; i<safes.length; ++i) {
            Safe storage safe = safes[i];
            if (safe.owner==msg.sender && safe.amount!=0) {
                payable(msg.sender).transfer(safe.amount);
                safe.amount=0;
            }
        }
        
    }
}

//*** Exercice 2 ***//
// You can buy some object.
// Further purchases are discounted.
// You need to pay basePrice / (1 + objectBought), where objectBought is the number of object you previously bought.
contract DiscountedBuy {
    uint public basePrice = 1 ether;
    mapping (address => uint) public objectBought;

    /// @dev Buy an object.
    function buy() public payable {
        require(msg.value * (1 + objectBought[msg.sender]) == basePrice);
        objectBought[msg.sender]+=1;
    }
    
    /** @dev Return the price you'll need to pay.
     *  @return price The amount you need to pay in wei.
     */
    function price() public view returns (uint) {
        return basePrice/(1 + objectBought[msg.sender]);
    }
    
}

//*** Exercice 3 ***//
// You choose Head or Tail and send 1 ETH.
// The next party send 1 ETH and try to guess what you chose.
// If it succeed it gets 2 ETH, else you get 2 ETH.
contract HeadOrTail {
    bool public chosen; // True if head/tail has been chosen.
    bool lastChoiceHead; // True if the choice is head.
    address payable public lastParty; // The last party who chose.
    
    /** @dev Must be sent 1 ETH.
     *  Choose head or tail to be guessed by the other player.
     *  @param _chooseHead True if head was chosen, false if tail was chosen.
     */
    function choose(bool _chooseHead) public payable {
        require(!chosen);
        require(msg.value == 1 ether);
        
        chosen=true;
        lastChoiceHead=_chooseHead;
        lastParty=payable(msg.sender);
    }
    
    
    function guess(bool _guessHead) public payable {
        require(chosen);
        require(msg.value == 1 ether);
        
        if (_guessHead == lastChoiceHead)
            payable(msg.sender).transfer(2 ether);
        else
            lastParty.transfer(2 ether);
            
        chosen=false;
    }
}

//*** Exercice 4 ***//
// You can store ETH in this contract and redeem them.
contract Vault {
    mapping(address => uint) public balances;

    /// @dev Store ETH in the contract.
    function store() public payable {
        balances[msg.sender]+=msg.value;
    }
    
    /// @dev Redeem your ETH.
    function redeem() public {
        msg.sender.call{ value: balances[msg.sender] }("");
        balances[msg.sender]=0;
    }
}

//*** Exercice 5 ***//
// You choose Head or Tail and send 1 ETH.
// The next party send 1 ETH and try to guess what you chose.
// If it succeed it gets 2 ETH, else you get 2 ETH.
contract HeadTail {
    address payable public partyA;
    address payable public partyB;
    bytes32 public commitmentA;
    bool public chooseHeadB;
    uint public timeB;
    
    
    
    /** @dev Constructor, commit head or tail.
     *  @param _commitmentA is keccak256(chooseHead,randomNumber);
     */
    constructor(bytes32 _commitmentA) payable {
        require(msg.value == 1 ether);
        
        commitmentA=_commitmentA;
        partyA=payable(msg.sender);
    }
    
    /** @dev Guess the choice of party A.
     *  @param _chooseHead True if the guess is head, false otherwize.
     */
    function guess(bool _chooseHead) public payable {
        require(msg.value == 1 ether);
        require(partyB==address(0));
        
        chooseHeadB=_chooseHead;
        timeB=block.timestamp;
        partyB=payable(msg.sender);
    }
    
    /** @dev Reveal the commited value and send ETH to the winner.
     *  @param _chooseHead True if head was chosen.
     *  @param _randomNumber The random number chosen to obfuscate the commitment.
     */
    function resolve(bool _chooseHead, uint _randomNumber) public {
        require(msg.sender == partyA);
        require(keccak256(abi.encodePacked(_chooseHead, _randomNumber)) == commitmentA);
        require(address(this).balance >= 2 ether);
        
        if (_chooseHead == chooseHeadB)
            partyB.transfer(2 ether);
        else
            partyA.transfer(2 ether);
    }
    
    /** @dev Time out party A if it takes more than 1 day to reveal.
     *  Send ETH to party B.
     * */
    function timeOut() public {
        require(block.timestamp > timeB + 1 days);
        require(address(this).balance >= 2 ether);
        partyB.transfer(2 ether);
    }
}



//*** Exercice 6 ***//
// Simple token you can buy and send.
contract SimpleToken {
    mapping(address => int) public balances;
    
    /// @dev Buy token at the price of 1ETH/token.
    constructor()  {
        balances[msg.sender]+= 1000e18;
    }
    
    /** @dev Send token.
     *  @param _recipient The recipient.
     *  @param _amount The amount to send.
     */
    function sendToken(address _recipient, int _amount) public {
        balances[msg.sender]-=_amount;
        balances[_recipient]+=_amount;
    }
    
}

//*** Exercice 7 ***//
// Simple token you can buy and send through a bonded curve.
contract LinearBondedCurve {
    mapping(address => uint) public balances;
    uint public totalSupply;
    
    /// @dev Buy token. The price is linear to the total supply.
    function buy() public payable {
        uint tokenToReceive = 1e18 * (msg.value / (1e18 + totalSupply));
        balances[msg.sender] += tokenToReceive;
        totalSupply += tokenToReceive;
    }
    
    /// @dev Sell token. The price of it is linear to the supply.
    /// @param _amount The amount of tokens to sell.
    function sell(uint _amount) public {
        uint ethToReceive = ((1e18 + totalSupply) * _amount) / 1e18;
        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        payable(msg.sender).transfer(ethToReceive);
    }
    
    /** @dev Send token.
     *  @param _recipient The recipient.
     *  @param _amount The amount to send.
     */
    function sendToken(address _recipient, uint _amount) public {
        balances[msg.sender]-=_amount;
        balances[_recipient]+=_amount;
    }
    
}

//*** Exercice 7 ***//
// You can create coffers, deposit money and withdraw from them.
contract Coffers {
    struct Coffer {uint nbSlots; mapping(uint => uint) slots;}
    mapping(address => Coffer) coffers;
    
    /** @dev Create coffers.
     *  @param _slots The amount of slots the coffer will have.
     * */
    function createCoffer(uint _slots) external {
        Coffer storage coffer = coffers[msg.sender];
        require(coffer.nbSlots == 0, "Coffer already created");
        coffer.nbSlots = _slots;
    }
    
    /** @dev Deposit money in one's coffer slot.
     *  @param _owner The coffer to deposit money on.
     *  @param _slot The slot to deposit money.
     * */
    function deposit(address _owner, uint _slot) payable external {
        Coffer storage coffer = coffers[_owner];
        require(_slot < coffer.nbSlots);
        coffer.slots[_slot] += msg.value;
    }
    
    /** @dev Withdraw all of the money of one's coffer slot.
     *  @param _slot The slot to withdraw money from.
     * */
    function withdraw(uint _slot) external {
        Coffer storage coffer = coffers[msg.sender];
        require(_slot < coffer.nbSlots);
        payable(msg.sender).transfer(coffer.slots[_slot]);
        coffer.slots[_slot] = 0;
    }
    
    /** @dev Close an account withdrawing all the money.
     * */
    function closeAccount() external {
        Coffer storage coffer = coffers[msg.sender];
        uint amountToSend;
        for (uint i=0; i<coffer.nbSlots; ++i)
            amountToSend += coffer.slots[i];
        coffer.nbSlots = 0;
        payable(msg.sender).transfer(amountToSend);
    }
}

//*** Exercice 8 ***//
// Simple coffer you deposit to and withdraw from.
contract CommonCoffers {
    mapping(address => uint) public coffers;
    uint public scalingFactor;
    
    /** @dev Deposit money in one's coffer slot.
     *  @param _owner The coffer to deposit money on.
     * */
    function deposit(address _owner) payable external {
        if (scalingFactor != 0) {
            uint toAdd = (scalingFactor * msg.value) / (address(this).balance - msg.value);
            coffers[_owner] += toAdd;
            scalingFactor += toAdd;
        }
        else {
            scalingFactor = 100;
            coffers[_owner] = 100;
        }
    }
    
    /** @dev Withdraw all of the money of one's coffer slot.
     *  @param _amount The slot to withdraw money from.
     * */
    function withdraw(uint _amount) external {
        uint toRemove = (scalingFactor * _amount) / address(this).balance;
        coffers[msg.sender] -= toRemove;
        scalingFactor -= toRemove;
        payable(msg.sender).transfer(_amount);
    }
    
}


//*** Exercice 9 ***//
// Two parties make a deposit for a particular side and the owner decides which side is correct.
// Owner's decision is based on some external factors irrelevant to this contract.
contract Resolver {
    enum Side {A, B}

    address public owner = msg.sender;
    address payable[2] public sides;

    uint256 public baseDeposit;
    uint256 public reward;
    Side public winner;
    bool public declared;

    uint256[2] public partyDeposits;

    /** @dev Constructor.
     *  @param _baseDeposit The deposit a party has to pay.
     */
    constructor(uint256 _baseDeposit) payable {
        reward = msg.value;
        baseDeposit = _baseDeposit;
    }

    /** @dev Make a deposit as one of the parties.
     *  @param _side A party to make a deposit as.
     */
    function deposit(Side _side) public payable {
        require(!declared, "The winner is already declared");
        require(sides[uint(_side)] == address(0), "Side already paid");
        require(msg.value > baseDeposit, "Should cover the base deposit");
        sides[uint(_side)] = payable(msg.sender);
        partyDeposits[uint(_side)] = msg.value;
    }

    /** @dev Declare the winner as an owner.
     *  @param _winner The party that is eligible to a reward according to owner.
     */
    function declareWinner(Side _winner) public {
        require(msg.sender == owner, "Only owner allowed");
        require(!declared, "Winner already declared");
        declared = true;
        winner = _winner;
    }

    /** @dev Pay the reward to the winner. Reimburse the surplus deposit for both parties if there was one.
     */
    function payReward() public {
        require(declared, "The winner is not declared");
        uint depositA = partyDeposits[0];
        uint depositB = partyDeposits[1];

        partyDeposits[0] = 0;
        partyDeposits[1] = 0;

        // Pay the winner. Note that if no one put a deposit for the winning side, the reward will be burnt.
        require(sides[uint(winner)].send(reward), "Unsuccessful send");

        // Reimburse the surplus deposit if there was one.
        if (depositA > baseDeposit && sides[0]!=address(0)) {
            require(sides[0].send(depositA - baseDeposit), "Unsuccessful send");    
        }

        if (depositB > baseDeposit && sides[1]!=address(0)) {
            require(sides[1].send(depositB - baseDeposit), "Unsuccessful send");    
        }

        reward = 0;
    }
    
}


//*** Exercice 10 ***//
// Contract for users to register. It will be used by other contracts to attach rights to those users (rights will be linked to user IDs).
contract Registry {

    struct User {
        address payable regAddress;
        uint64 timestamp;
        bool registered;
        string name;
        string surname;
        uint nonce;
    }

    // Nonce is used so the contract can add multiple profiles with the same first name and last name.
    mapping(string => mapping(string => mapping(uint => bool))) public isRegistered; // name -> surname -> nonce -> registered/not registered. 
    mapping(bytes32 => User) public users; // User isn't identified by address but by his ID, since the same person can have multiple addresses.

    /** @dev Add yourself to the registry.
     *  @param _name The first name of the user.
     *  @param _surname The last name of the user.
     *  @param _nonce An arbitrary number to allow multiple users with the same first and last name.
     */
    function register(string calldata _name, string calldata _surname, uint _nonce) public {
        require(!isRegistered[_name][_surname][_nonce], "This profile is already registered");
        isRegistered[_name][_surname][_nonce] = true;
        bytes32 ID = keccak256(abi.encodePacked(_name, _surname, _nonce));
        User storage user = users[ID];
        user.regAddress = payable(msg.sender);
        user.timestamp = uint64(block.timestamp);
        user.registered = true;
        user.name = _name;
        user.surname = _surname;
        user.nonce = _nonce;
    }

    /** @dev Remove yourself from the registry for whatever reason.
     *  @param _ID The ID of the user.
     */
    function unregister(bytes32 _ID) public {
        User storage user = users[_ID];
        require(user.registered, "Should be registered");
        require(msg.sender == user.regAddress, "Only the user who registered this profile is allowed to unregister it");
        user.registered = false;
        isRegistered[user.name][user.surname][user.nonce] = false;
    }

}

//*** Exercice 11 ***//
// A Token contract that keeps a record of the users past balances.
contract SnapShotToken {
    mapping(address => uint) public balances;
    mapping(address => mapping(uint => uint)) public balanceAt;

    event BalanceUpdated(address indexed user, uint oldBalance, uint newBalance);
    
    /// @dev Buy token at the price of 1ETH/token.
    function buyToken() public payable {
        uint _balance = balances[msg.sender];
        uint _newBalance = _balance + msg.value / 1 ether;
        balances[msg.sender] = _newBalance;

        _updateCheckpoint(msg.sender, _balance, _newBalance);
    }
    
    /** @dev Transfer tokens.
     *  @param _to The recipient.
     *  @param _value The amount to send.
     */
    function transfer(address _to, uint _value) public {
        uint _balancesFrom = balances[msg.sender];
        uint _balancesTo = balances[_to];

        uint _balancesFromNew = _balancesFrom - _value;
        balances[msg.sender] = _balancesFromNew;

        uint _balancesToNew = _balancesTo + _value;
        balances[_to] = _balancesToNew;

        _updateCheckpoint(msg.sender, _balancesFrom, _balancesFromNew);
        _updateCheckpoint(_to, _balancesTo, _balancesToNew);
    }
    
    /**
     * @dev Record the users balance at this blocknumber
     *
     * @param _user The address who's balance is updated.
     * @param _oldBalance The previous balance.
     * @param _newBalance The updated balance.
     */
    function _updateCheckpoint(address _user, uint _oldBalance, uint _newBalance) internal {
        balanceAt[_user][block.timestamp] = _newBalance;
        emit BalanceUpdated(_user, _oldBalance, _newBalance);
    }
}

//*** Exercise Bonus ***//
// One of the previous contracts has 2 vulnerabilities.
// Find which one and describe the second vulnerability.

