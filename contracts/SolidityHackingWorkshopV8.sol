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

//*** Exercise Bonus ***//
// One of the previous contracts has 2 vulnerabilities.
// Find which one and describe the second vulnerability.

