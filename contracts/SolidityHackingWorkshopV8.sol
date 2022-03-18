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
    
    /// @dev Creator starts with all the tokens.
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
// Simple token you can buy and send through a bonded curve. We assume that order frontrunning is fine.
contract LinearBondedCurve {
    mapping(address => uint) public balances;
    uint public totalSupply;
    
    /// @dev Buy token. The price is linear to the total supply.
    function buy() public payable {
        uint tokenToReceive =  (1e18 * msg.value) / (1e18 + totalSupply);
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

//*** Exercice 8 ***//
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

//*** Exercice 9 ***//
// Simple coffer you deposit to and withdraw from.
contract CommonCoffers {
    mapping(address => uint) public coffers;
    uint public scalingFactor;
    
    /** @dev Deposit money in one's coffer slot.
     *  @param _owner The coffer to deposit money on.
     * */
    function deposit(address _owner) payable external {
        require(msg.value > 0);
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


//*** Exercice 10 ***//
// Two parties make a deposit for a particular side and the owner decides which side is correct.
// Owner's decision is based on some external factors irrelevant to this contract.
contract Resolver {
    enum Side {A, B}

    address payable public owner = msg.sender;
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
        require(msg.value >= baseDeposit, "Should cover the base deposit");
        sides[uint(_side)] = payable(msg.sender);
        partyDeposits[uint(_side)] = msg.value;
        owner.send(baseDeposit);
    }

    /** @dev Declare the winner as an owner.
     *  Note that in case no one funded for the winner when the owner makes its transaction, having someone else deposit to get the reward is fine and doesn't affect the mecanism.
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


//*** Exercice 11 ***//
// Contract for users to register. It will be used by other contracts to attach rights to those users (rights will be linked to user IDs).
// Note that simply being registered does not confer any right.
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

}

//*** Exercice 12 ***//
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

//*** Exercice 13 ***//
// Each player tries to guess the average of all the player's revealed answers combined.
// They must pay 1 ETH to play.
// The winners are those who are the nearest from the average.
// Note that some players may not reveal and use multiple accounts, this is part of the game and can be used tactically.
// Also note that waiting the last minute to reveal is also part of the game and can be used tactically (but it would probably cost a lot of gas).
contract GuessTheAverage {

    uint256 immutable public start; // Beginning of the game.
    uint256 immutable public commitDuration; // Duration of the Commit Period.
    uint256 immutable public revealDuration; // Duration of the Reveal Period.
    uint256 public cursorWinner; // Cursor of the last winner.
    uint256 public cursorDistribute; // Cursor of the last distribution of rewards.
    uint256 public lastDifference; // Last best difference between a guess and the average.
    uint256 public average; // Average to guess.
    uint256 public totalBalance; // Total balance of the contract.
    uint256 public numberOfLosers; // Number of losers in the winners list.
    Stage public currentStage; // Current Stage.

    enum Stage {
        CommitAndRevealPeriod,
        AverageCalculated,
        WinnersFound,
        Distributed
    }

    struct Player {
        uint playerIndex; // Index of the player in the guesses list.
        bool hasGuessed; // Whether the player has guessed or not.
        bool hasReveal; // Whether the player has revealed or not.
        bytes32 commitment; // commitment of the player.
    }

    uint[] public guesses; // List of player's guesses.
    address[] public winners; // List of winners to reward.

    mapping(address => Player) public players; // Maps an address to its respective Player status.
    mapping(uint => address) public indexToPlayer; // Maps a guess index to the player who made the guess.

    constructor(uint32 _commitDuration, uint32 _revealDuration) {
        start = block.timestamp;
        commitDuration = _commitDuration;
        revealDuration = _revealDuration;
    }

    /** @dev Adds the guess for the user.
     *  @param _commitment The commitment of the user under the form of keccak256(abi.encodePacked(msg.sender, _number, _blindingFactor) where the blinding factor is a bytes32.
     */
    function guess(bytes32 _commitment) public payable {
        Player storage player = players[msg.sender];
        require(!player.hasGuessed, "Player has already guessed");
        require(msg.value == 1 ether, "Player must send exactly 1 ETH");
        require(block.timestamp >= start && block.timestamp <= start + commitDuration, "Commit period must have begun and not ended");

        // Store the commitment.
        player.hasGuessed = true;
        player.commitment = _commitment;
    }

    /** @dev Reveals the guess for the user.
     *  @param _number The number guessed.
     *  @param _blindingFactor What has been used for the commitment to blind the guess.
     */
    function reveal(uint _number, bytes32 _blindingFactor) public {
        require(block.timestamp >= start + commitDuration && block.timestamp < start + commitDuration + revealDuration, "Reveal period must have begun and not ended");
        Player storage player = players[msg.sender];
        require(!player.hasReveal, "Player has already revealed");
        require(player.hasGuessed, "Player must have guessed");
        // Check the hash to prove the player's honesty
        require(keccak256(abi.encodePacked(msg.sender, _number, _blindingFactor)) == player.commitment, "Invalid hash");

        // Update player and guesses.
        player.hasReveal = true;
        average += _number;
        indexToPlayer[guesses.length] = msg.sender;
        guesses.push(_number);
        player.playerIndex = guesses.length;
    }

    /** @dev Finds winners among players who have revealed their guess.
     *  @param _count The number of transactions to execute. Executes until the end if set to "0" or number higher than number of transactions in the list.
     */
    function findWinners(uint256 _count) public {
        require(block.timestamp >= start + commitDuration + revealDuration, "Reveal period must have ended");
        require(currentStage < Stage.WinnersFound);
        // If we don't have calculated the average yet, we calculate it.
        if (currentStage < Stage.AverageCalculated) {
            average /= guesses.length;
            currentStage = Stage.AverageCalculated;
            totalBalance = address(this).balance;
            cursorWinner += 1;
        }
        // If there is no winner we push the first player into the winners list to initialize it.
        if (winners.length == 0) {
            winners.push(indexToPlayer[0]);
            // Avoid overflow.
            if (guesses[0] > average) lastDifference = guesses[0] - average;
            else lastDifference = average - guesses[0];
        }
        uint256 i = cursorWinner;
        for (; i < guesses.length && (_count == 0 || i < cursorWinner + _count); i++) {
            uint256 difference;
            // Avoid overflow.
            if (guesses[i] > average) difference = guesses[i] - average;
            else difference = average - guesses[i];
            // Compare difference with the latest lowest difference.
            if (difference < lastDifference) {
                // Add winner and update lastDifference.
                cursorDistribute = numberOfLosers = winners.length;
                winners.push(indexToPlayer[i]);
                lastDifference = difference;
            } else if (difference == lastDifference) winners.push(indexToPlayer[i]);
            // If we have passed through the entire array, update currentStage.
            
        }
        if (i == guesses.length) currentStage = Stage.WinnersFound;
        // Update the cursor in case we haven't finished going through the list.
        cursorWinner += _count;
    }

    /** @dev Distributes rewards to winners.
     *  @param _count The number of transactions to execute. Executes until the end if set to "0" or number higher than number of winners in the list.
     */
    function distribute(uint256 _count) public {
        require(currentStage == Stage.WinnersFound, "Winners must have been found");
        for (uint256 i = cursorDistribute; i < winners.length && (_count == 0 || i < cursorDistribute + _count); i++) {
            // Send ether to the winners, use send not to block.
            payable(winners[i]).send(totalBalance / (winners.length - numberOfLosers));
            if (i == winners.length -1) currentStage = Stage.Distributed;
        }
        // Update the cursor in case we haven't finished going through the list.
        cursorDistribute += _count;
    }
}

//*** Exercice 14 ***//
// This is a piggy bank.
// The owner can deposit 1 ETH whenever he wants.
// He can only withdraw when the deposited amount reaches 10 ETH.
contract PiggyBank {

    address owner;

    /// @dev Set msg.sender as owner
    constructor() {
        owner = msg.sender;
    }

    /// @dev Deposit 1 ETH in the smart contract
    function deposit() public payable {
        require(msg.sender == owner && msg.value == 1 ether && address(this).balance <= 10 ether);
    }

    /// @dev Withdraw the entire smart contract balance
    function withdrawAll() public {
        require(msg.sender == owner && address(this).balance == 10 ether);
        payable(owner).send(address(this).balance);
    }
}

//*** Exercice 15 ***//.
// This is a game where an Owner considered as TRUSTED can set rounds with rewards.
// The Owner allows several users to compete for the rewards. The fastest user gets all the rewards.
// The users can propose new rounds but it's up to the Owner to fund them.
// The Owner can clear the rounds to create fresh new ones.
contract WinnerTakesAll {

    struct Round {
        uint rewards;
        mapping(address => bool) isAllowed;
    }

    address owner;
    Round[] rounds;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function createNewRounds(uint _numberOfRounds) external {
        for (uint i = 0; i < _numberOfRounds; i++) {
            rounds.push();
        }
    }

    function setRewardsAtRound(uint _roundIndex) external payable onlyOwner() {
        require(rounds[_roundIndex].rewards == 0);
        rounds[_roundIndex].rewards = msg.value;
    }

    function setRewardsAtRoundfor(uint _roundIndex, address[] calldata _recipients) external onlyOwner() {
        for (uint i; i < _recipients.length; i++) {
            rounds[_roundIndex].isAllowed[_recipients[i]] = true;
        }
    }

    function isAllowedAt(uint _roundIndex, address _recipient) external view returns (bool) {
        return rounds[_roundIndex].isAllowed[_recipient];
    }

    function withdrawRewards(uint _roundIndex) external {
        require(rounds[_roundIndex].isAllowed[msg.sender]);
        uint amount = rounds[_roundIndex].rewards;
        rounds[_roundIndex].rewards = 0;
        payable(msg.sender).transfer(amount);
    }

    function clearRounds() external onlyOwner {
        delete rounds;
    }

    function withrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}


//*** Exercise Bonus ***//
// One of the previous contracts has 2 vulnerabilities.
// Find which one and describe the second vulnerability.

