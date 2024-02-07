// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract RentalContract {
    address public owner;
    address public renter;
    /*string public propertyAddress;*/
    uint public priceInWei;
    uint public contractDuration;
    uint public contractStartTimestamp;
    uint public endContract;
    uint public renovation;
    bool public contractActivated;
    

    
    constructor() {
        owner = msg.sender;
        contractStartTimestamp = block.timestamp;
        priceInWei = 10**15;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can start a Contract");
        _;
    }

    event starting(
        address owner,
        address renter,
        /*string propertyAddress,*/
        uint priceInWei,
        uint contractDuration,
        uint contractStartTimestamp,
        uint endContract,
        uint renovation,
        bool contractActivated
    );

    modifier startContractRules(address _renter, uint _contractDuration) {
        require((address(this).balance) > 0, "You need to deposit 0.001 ETH to start contract");
        require((address(this).balance) == 10**15, "deposit amount 0.001 ETH");
        require(_renter != address(owner),"The renter's address must be different from the owner's address");
        require(_renter != address(0), "Renter address invalid");
        require(_contractDuration > 0, "The contract duration must be greater than 0");
        
        //avoid reassigning variable state, avoid the same rental contract from being issued to more than one
        //require(renter == address(0), "The contract has already initiate");
         _;
    }

    function startContract(address payable  _renter,/*string memory _propertyAddress,*/ uint _contractDuration) 
        public startContractRules(_renter, _contractDuration) {
        renter = _renter;
        /*propertyAddress = _propertyAddress;*/
        contractDuration = _contractDuration;
        contractStartTimestamp = block.timestamp;
        endContract = (contractStartTimestamp + contractDuration);
        contractActivated = true;

        emit starting(
            owner,
            renter,
            /*propertyAddress,*/
            priceInWei,
            contractDuration,
            contractStartTimestamp,
            endContract,
            renovation,
            contractActivated
        );
    }

    function getStarContract()
        public
        view
        returns (
            address,
            /*string memory,*/
            uint,
            uint,
            uint,
            uint
        )
    {
        return (
            renter,
            /*propertyAddress,*/
            priceInWei,
            contractDuration,
            contractStartTimestamp,
            endContract
        );
    }

    modifier renovationRules(address _renter, uint _renovation) {
        require(contractActivated == true, "The contract is not activated");
        require(_renter == renter, "Only the renter can renew the rental contract");
        require(_renovation > 0, "The renovation must be greater than 0");
        require(_renter != address(0));
        require((address(this).balance) > 0, "You need to deposit 0.001 ETH to renew contract");
        require((address(this).balance) == 10**15, "deposit amount 0.001 ETH");
        _;
    }

    function renovationContract(address  _renter, uint _renovation) public renovationRules(_renter, _renovation) {
        renter = _renter;
        renovation = _renovation;
        endContract += renovation;
        contractDuration += renovation;
        
    }

    function getRenovationContract() public view returns (address, uint) {
        return (renter, renovation);
    }

    modifier revoke() {
        require(msg.sender == owner, "Only owner can to revoke the contract");
        require(contractActivated == true, "Contract not activate");
        _;
    }

    event revoked(bool contractActivated, address owner);

    function revokeContract() public revoke {
        contractActivated = false;
        emit revoked(contractActivated, owner);
    }

    function statusCheck() public view returns (string memory) {
        uint currentDay = block.timestamp;
        string memory expired = "Expired";
        string memory activated = "Activated";
        string memory waiting = "Waiting renter data";
        string memory revokedMsg = "Revoked";

        if (contractActivated == true) {
            return activated;
        } else if (contractActivated == false) {
            return revokedMsg;
        } else if (currentDay > endContract) {
            return expired;
        } else if (renter == address(0)){
            return waiting;
        }
        else {
            return waiting;
        }
    }
    
    event amountReceive(address _renter, uint value);

    receive() external payable { 
        emit amountReceive(msg.sender, msg.value);
    }   

    modifier whitdrawRules() {
        require((address(this).balance > 0),"Insufficient amount to withdraw");
        require(msg.sender == owner, "Only owner can make a withdrawal");
        _;
    }

    function withdraw() external whitdrawRules {
        payable(owner).transfer(address(this).balance);
    }
}