/* This program is free software. It comes without any warranty, to
the extent permitted by applicable law. You can redistribute it
and/or modify it under the terms of the Do What The Fuck You Want
To Public License, Version 2, as published by Sam Hocevar. See
http://www.wtfpl.net/ for more details. */

/// WIP: Adding new exercises to update the workshop on potential v0.8 bugs and vulnerabilities.

/* These contracts are examples of contracts with bugs and vulnerabilities in order to practice your hacking skills.
DO NOT USE THEM OR GET INSPIRATION FROM THEM TO MAKE CODE USED IN PRODUCTION 
You are required to find vulnerabilities where an attacker harms someone else.
Being able to destroy your own stuff is not a vulnerability and should be dealt at the interface level.
*/

pragma solidity ^0.8.2;


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
// A simple contract that allows to store some ETH and withdraw it at any time.
contract DepositBox {
    
    mapping(address => uint) public deposits;
    
    /** @dev Put some ETH in the contract.
     */
    function makeDeposit() public payable {
        require(msg.value > 0, "Can't deposit 0");
        deposits[msg.sender] = msg.value;
    }
    
    /** @dev Withdraw the deposited amount.
     */
    function withdrawDeposit() public {
        uint deposit = deposits[msg.sender];
        deposits[msg.sender] = 0;
        payable(msg.sender).transfer(deposit);
    }
}

//*** Exercice 7 ***//
// You can make a request which is granted if you raised specific crowdfunding amount.
// Crowdfunders can get a proportional reward for the granted request.
contract Requests {
    enum Status {None, Open, Granted}
    
    struct Request {
        Status status;
        address requester;
        mapping(address => uint) contributions; // contributror -> contributed amount.
        uint fundsRaised;
    }
    
    uint public initialDeposit;
    uint public crowdfundingDeposit;

    Request[] public requests;
    
    /** @dev Constructor.
     *  @param _inititalDeposit The deposit a requester has to pay in order to make a request.
     *  @param _crowdfundingDeposit  The amount crowdfunders have to raise in order to grant the request.
     */
    constructor(uint _inititalDeposit, uint _crowdfundingDeposit) {
        initialDeposit = _inititalDeposit;
        crowdfundingDeposit = _crowdfundingDeposit;
    }
    
    /** @dev Make a request. Requires the initial deposit to be paid.
     */
    function makeRequest() public payable {
        require(msg.value == initialDeposit, "Unexpected deposit value");
        Request storage request = requests.push();
        request.requester = msg.sender;
        request.status = Status.Open;
    }
    
    /** @dev Fund a specific request.
     *  @param _requestID  The ID of the request.
     */
    function fund(uint _requestID) public payable {
        Request storage request = requests[_requestID];
        require(request.status == Status.Open, "The request should be open");
        require(msg.sender != request.requester, "Can't fund own request");
        
        uint totalRequired = crowdfundingDeposit - request.fundsRaised;
        require(msg.value <= totalRequired, "Should not overpay");

        request.contributions[msg.sender] += msg.value;
        request.fundsRaised += msg.value;
        
        // Grant the request when the specific amount has been raised.
        if (request.fundsRaised == crowdfundingDeposit) {
            request.status = Status.Granted;
        }
    }
    
    /** @dev Get your reward as a crowdfunder.
     *  @param _requestID  The ID of the request.
     */
    function withdraw(uint _requestID) public {
        Request storage request = requests[_requestID];
        require(request.status == Status.Granted, "The request should be granted");
        
        // Reward the funders proportionally.
        uint rewardPool = crowdfundingDeposit + initialDeposit;
        uint reward = request.contributions[msg.sender] / crowdfundingDeposit * rewardPool;
        payable(msg.sender).transfer(reward);
        request.contributions[msg.sender] = 0;
    }
}

//*** Exercice 8 ***//
// A token contract that reimburses the sender small amount based on the amount transferred.
contract ReimbursableToken {
    uint public constant ratio = 10000; // Set the ratio to 0.01% of the transferred amount.

    string public name;
    mapping(address => uint) public balances;
    mapping (address => mapping (address => uint256)) public allowances;
    
    /** @dev Constructor.
     *  @param _name A name of the token.
     *  @param _supply  Total supply of the token.
     */
    constructor(string memory _name, uint _supply) {
        balances[msg.sender] = _supply;
        name = _name;
    }

    /** @dev Transfer some tokens to another address.
     *  @param _to Address of the recipient.
     *  @param _amount  The amount to transfer.
     */
    function transfer(address _to, uint _amount) public {
        require(_to != address(0), "Can't transfer to 0 address");
        balances[msg.sender] = sub(balances[msg.sender], _amount);
        balances[_to] = add(balances[_to], _amount);

        // Reimburse 0.01% of the tranferred amount.
        uint amountReimbursed = _amount / ratio;
        balances[msg.sender] += amountReimbursed;
    }

    /** @dev Transfer tokens on behalf of the someone else.
     *  @param _from Address to transfer from.
     *  @param _to Address of the recipient.
     *  @param _amount  The amount to transfer.
     */
    function transferFrom(address _from, address _to, uint256 _amount) public {
        require(_to != address(0), "Can't transfer to 0 address");
        balances[_from] = sub(balances[_from], _amount);
        balances[_to] = add(balances[_to], _amount);
        allowances[_from][msg.sender] = sub(allowances[_from][msg.sender], _amount);

        uint amountReimbursed = _amount / ratio;
        balances[_from] += amountReimbursed;
        allowances[_from][msg.sender] += amountReimbursed;
    }

    /** @dev Increase the allowance of the spender.
     *  @param _spender Address of the spender.
     *  @param _value  The amount to increase.
     */
    function increaseAllowance(address _spender, uint256 _value) public {
        require(_spender != address(0), "Spender can't be 0 address");
        allowances[msg.sender][_spender] = add(allowances[msg.sender][_spender], _value);
    }

    /** @dev Decrease the allowance of the spender.
     *  @param _spender Address of the spender.
     *  @param _value  The amount to decrease.
     */
    function decreaseAllowance(address _spender, uint256 _value) public {
        require(_spender != address(0), "Spender can't be 0 address");
        allowances[msg.sender][_spender] = sub(allowances[msg.sender][_spender], _value);
    }

    /**
     * @dev Helper functions to ensure safe math operations.
     */
    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

//*** Exercice 9 ***//
// Two parties make a deposit and the owner decides who will get the reward.
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
        require(sides[0]!=address(0) && sides[1]!=address(0), "Both parties should pay");
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
        
        // Pay the winner.
        require(sides[uint(winner)].send(reward), "Unsuccessful send");

        // Reimburse the surplus deposit if there was one.
        if (depositA > baseDeposit) {
            require(sides[0].send(depositA - baseDeposit), "Unsuccessful send");    
        }
        
        if (depositB > baseDeposit) {
            require(sides[1].send(depositB - baseDeposit), "Unsuccessful send");    
        }
        
        reward = 0;
    }
}

//*** Exercice 10 ***//
// A contract that adds people to the registry. Every registered user is eligible to a reward once per period.
contract Registry {
    
    struct User {
        address payable regAddress;
        uint64 timestamp;
        bool registered;
        string name;
        string surname;
        uint nonce;
    }
    
    address public owner = msg.sender;
    uint public rewardTimeout;
    uint public rewardPool;
    
    uint public count;
    
    // Nonce is used so the contract can add multiple profiles with the same first name and last name.
    mapping(string => mapping(string => mapping(uint => bool))) public isRegistered; // name -> surname -> nonce -> registered/not registered. 
    mapping(bytes32 => User) public users; // User isn't identified by address but by his ID, since the same person can have multiple addresses.
    
    event NewUser(bytes32 _ID);
    
    /** @dev Constructor.
     *  @param _rewardTimeout The timeout after which the reward can be claimed. User's timestamp gets refreshed each time after.
     */
    constructor(uint _rewardTimeout) payable {
        rewardTimeout = _rewardTimeout;
        rewardPool = msg.value;
    }
    
    /** @dev Pay ETH to increase reward pool.
     */
    receive() external payable {
        rewardPool += msg.value;
    }
    
    /** @dev Add yourself to the registry and become eligible to a reward.
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
        emit NewUser(ID);

        count++;
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
        
        count--;
    }
    
    /** @dev Get the reward once per period as a registered user.
     *  @param _ID The ID of the user.
     */
    function getReward(bytes32 _ID) public {
        User storage user = users[_ID];
        require(user.registered, "Should be registered");
        require(block.timestamp - user.timestamp > rewardTimeout, "Can't claim reward yet");
        uint share = rewardPool / count;
        rewardPool -= share;
        user.regAddress.transfer(share);
        user.timestamp = uint64(block.timestamp);
    }
}

//*** Exercise Bonus ***//
// One of the previous contracts has 2 vulnerabilities.
// Find which one and describe the second vulnerability.

