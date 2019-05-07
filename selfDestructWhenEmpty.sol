contract selfDestructWhenEmpty {
    
    bool aboutToBeSelfdestructed;
    
    // constructor
    function selfDestructWhenEmpty() payable {
        require(msg.value != 0);
    }
    
    
    function emptyContract() isAboutToBeSelfdestructed(false) public {
        msg.sender.transfer(address(this).balance);
    }
    
    function startSelfDestruct() hasNoEther isAboutToBeSelfdestructed(false) public {
        aboutToBeSelfdestructed = false;    
    }
    
    
    function selfDestructContract() hasNoEther isAboutToBeSelfdestructed(true) {
        selfdestruct(msg.sender);    
    }
    
    modifier hasNoEther() {
        require(address(this).balance == 0);
        _;
    }
    
    modifier isAboutToBeSelfdestructed(bool isIndeed) {
        if(isIndeed) {
            require(aboutToBeSelfdestructed);
        } else {
            require(!aboutToBeSelfdestructed);
        }
        _;
    }
}
