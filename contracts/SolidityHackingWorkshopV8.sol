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
// Each player tries to guess the average of all the player's answer combined.
// They must pay 1 ETH to play.
// The winners are those who are the nearest from the average.
contract GuessTheAverage {

    uint256 immutable public start; // Beginning of the game.
    uint256 immutable public commitDuration; // Duration of the Commit Period.
    uint256 immutable public revealDuration; // Duration of the Reveal Period.
    uint256 public cursorWinner; // Cursor of the last winner.
    uint256 public cursorDistribute; // Cursor of the last distribution of rewards.
    uint256 public lastDifference; // Last best difference between a guess and the average.
    uint256 public average; // Average to guess.
    uint256 public totalBalance; // Total balance of the contract.
    Stage public currenStage; // Current Stage.

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
        require(block.timestamp >= start + commitDuration && block.timestamp <= start + commitDuration + revealDuration, "Reveal period must have begun and not ended");
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
        require(currenStage < Stage.WinnersFound);
        // If we don't have calculated the average yet, we calculate it.
        if (currenStage < Stage.AverageCalculated) {
            average /= guesses.length;
            currenStage = Stage.AverageCalculated;
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
        for (uint256 i = cursorWinner; i < guesses.length && (_count == 0 || i < cursorWinner + _count); i++) {
            uint256 difference;
            // Avoid overflow.
            if (guesses[i] > average) difference = guesses[i] - average;
            else difference = average - guesses[i];
            // Compare difference with the latest lowest difference.
            if (difference < lastDifference) {
                // Remove all losers.
                for (uint256 j = 0; j < winners.length; j++) {
                    winners.pop();
                }
                // Add winner and update lastDifference.
                winners.push(indexToPlayer[i]);
                lastDifference = difference;
            } else if (difference == lastDifference) winners.push(indexToPlayer[i]);
            // If we have passed through the entire array, update currenStage.
            if (i == guesses.length - 1) currenStage = Stage.WinnersFound;
        }
        // Update the cursor in case we haven't finished going through the list.
        cursorWinner += _count;
    }

    /** @dev Distributes rewards to winners.
     *  @param _count The number of transactions to execute. Executes until the end if set to "0" or number higher than number of winners in the list.
     */
    function distribute(uint256 _count) public {
        require(currenStage == Stage.WinnersFound, "Winners must have been found");
        for (uint256 i = cursorDistribute; i < winners.length && (_count == 0 || i < cursorDistribute + _count); i++) {
            // Send ether to the winners, use send not to block.
            payable(winners[i]).send(totalBalance / winners.length);
            if (i == winners.length -1) currenStage = Stage.Distributed;
        }
        // Update the cursor in case we haven't finished going through the list.
        cursorDistribute += _count;
    }
}


//*** Exercise Bonus ***//
// One of the previous contracts has 2 vulnerabilities.
// Find which one and describe the second vulnerability.
