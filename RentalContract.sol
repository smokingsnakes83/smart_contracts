// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract RentalContract {
    address public owner;
    address payable public renter;
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
        require(msg.sender == owner, "Only the owner can start a Contract");
        /*require((address(this).balance) > 0, "Deposit 0.001 ETH to start contract");
        require((address(this).balance) == 10**15, "deposit amount 0.001 ETH");*/
        require(_renter != address(owner),"The renter's address must be different from the owner's address");
        require(_renter != address(0), "Renter address invalid");
        require(_contractDuration > 0, "The contract duration must be greater than 0");
        
        /*avoid reassigning variable state, avoid the same rental contract from being issued to more than one
        require(renter == address(0), "The contract has already initiate");*/
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

        payable(owner).transfer(address(this).balance);

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

    modifier renovationRules(address payable  _renter, uint _renovation) {
        require(contractActivated == true, "The contract is not activated");
        require(_renter == renter, "Only the renter can renew the rental contract");
        require(_renovation > 0, "The renovation must be greater than 0");
        require(_renter != address(0));
        require(block.timestamp > endContract, "The renewal day must be greater than end day contract");
        /*require((address(this).balance) > 0, "Deposit 0.001 ETH to renew contract");
        require((address(this).balance) == 10**15, "deposit amount 0.001 ETH"); */   
        _;
    }

    function renovationContract(address payable  _renter, uint _renovation) public renovationRules(_renter, _renovation) {
        renter = _renter;
        renovation = _renovation;
        endContract = block.timestamp;
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

    function statusCheck() public view returns (string memory, uint) {
        string memory expired = "Expired";
        string memory activated = "Activated";
        string memory waiting = "The contract is not started";
        string memory revokedMsg = "Revoked";

        if (contractActivated == true && block.timestamp < endContract) {
            return (activated, block.timestamp);
        } else if (contractActivated == false && renter != address(0)) {
            return (revokedMsg, block.timestamp);
        } else if (block.timestamp > endContract && contractActivated == true) {
            return (expired, block.timestamp);
        } else if (renter == address(0)){
            return (waiting, block.timestamp);
        }
        else {
            return ("", block.timestamp);
        }
    }
    
    event amountReceive(address _renter, uint value);

    receive() external payable { 
        emit amountReceive(msg.sender, msg.value);
    }   

    modifier whitdrawRules() {
        require((address(this).balance > 0),"Insufficient amount to withdraw");
        require(msg.sender == owner, "Only owner can make a withdrawal");
        require(contractActivated == true);
        _;
    }

    function withdraw() external whitdrawRules {
        payable(owner).transfer(address(this).balance);
    }

    
}