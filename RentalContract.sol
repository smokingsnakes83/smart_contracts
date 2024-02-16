// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract RentalContract {
    address public owner;
    address payable public renter;
    uint public priceInWei = 0;
    uint public contractDuration = 0;
    uint public contractStartTimestamp = 0;
    uint public endContract = 0;
    uint public renovation = 0;
    bool public contractActivated = false;
    
    constructor() {
        owner = msg.sender;
        priceInWei = 10**15;
    }

    event starting_(
        address owner,
        address renter,
        uint priceInWei,
        uint contractDuration,
        uint contractStartTimestamp,
        uint endContract,
        bool contractActivated
    );

    modifier startContractRules(address _renter, uint _contractDuration) {
        require(msg.sender == owner, "Only the owner can start a Contract");
        require((address(this).balance) > 0, "Deposit 0.001 SepoliaETH to start contract");
        require((address(this).balance) >= 10**15, "deposit amount 0.001 SepoliaETH");
        require(_renter != address(owner),"The renter's address must be different from the owner's address");
        require(_renter != address(0), "Renter address invalid");
        require(_contractDuration > 0, "The contract duration must be greater than 0");
        
        //avoid reassigning variable state, avoid the same rental contract from being issued to more than one
        require(renter == address(0), "contract is already active");
         _;
    }
    
    event sendChange(address, uint);
    event paymentRental(address, uint);
    
    function startContract(address payable  _renter,/*string memory _propertyAddress,*/ uint _contractDuration) 
        public startContractRules(_renter, _contractDuration) {
        renter = _renter;
        contractDuration = _contractDuration;
        contractStartTimestamp = block.timestamp;
        endContract = (contractStartTimestamp + contractDuration);
        contractActivated = true;      

        //If the renter deposits more than 0.001 SepoliaETH, the change will be returned to their wallet
        if((address(this).balance) > 10**15) {
            uint totalBalance;
            uint change;

            totalBalance = (address(this).balance);
            change = (address(this).balance) - 10**15;
            payable(renter).transfer(change);

            emit sendChange(renter, change);
        }

        uint payment = (address(this).balance); 
        payable(owner).transfer(address(this).balance);
        emit paymentRental(owner, payment);

        emit starting_(
            owner,
            renter,
            priceInWei,
            contractDuration,
            contractStartTimestamp,
            endContract,
            contractActivated
        );
    }

    function getStarContract()
        public
        view
        returns (
            address,
            uint,
            uint,
            uint,
            uint
        )
    {
        return (
            renter,
            priceInWei,
            contractDuration,
            contractStartTimestamp,
            endContract
        );
    }

    modifier renovationRules(address payable  _renter, uint _renovation) {
        require(contractActivated == true, "The contract is not active");
        require(_renter == renter, "Only the renter can renew the rental contract");
        require(_renovation > 0, "The renovation must be greater than 0");
        require(_renter != address(0));
        require(block.timestamp > endContract, "The renewal day must be greater than end day contract");
        require((address(this).balance) > 0, "Deposit 0.001 SepoliaETH to renew contract");
        require((address(this).balance) >= 10**15, "deposit amount 0.001 SepoliaETH");   
        _;
    }

    event paymentRenovationRental_(address, uint);
    event renovationChange_(address, uint, uint);
    event renovationTime_(address, uint);

    function renovationContract(address payable  _renter, uint _renovation) public renovationRules(_renter, _renovation) {
        renter = _renter;
        renovation = _renovation;
        endContract = block.timestamp;
        endContract += renovation;
        contractDuration += renovation;    

        //If the renter deposits more than 0.001 SepoliaETH, the change will be returned to their wallet
        if((address(this).balance) > 10**15) {
            uint totalBalanceInRenovation;
            uint renovationChange;

            totalBalanceInRenovation = (address(this).balance);
            renovationChange = totalBalanceInRenovation - 10**15;
            payable(renter).transfer(renovationChange);

            emit renovationChange_(renter, renovation, renovationChange);
        }  
        else if((address(this).balance) == 10**15) {
            emit renovationTime_(renter, renovation);
        }

        uint paymentRenovation = (address(this).balance);
        payable(owner).transfer(address(this).balance);
        emit paymentRenovationRental_(owner, paymentRenovation);
    }

    function getRenovationContract() public view returns (address, uint) {
        return (renter, renovation);
    }

    modifier revoke() {
        require(msg.sender == owner, "Only owner can to revoke the contract");
        require(contractActivated == true, "Contract is not active");
        _;
    }

    event revoked_(string);

    function revokeContract() public revoke {
        contractActivated = false;
        string memory revoked = "Contract Revoked";
        emit revoked_(revoked);
    }

    function statusCheck() public view returns (string memory, uint) {
        string memory expired = "Expired";
        string memory activated = "Active";
        string memory waiting = "Waiting for renter data";
        string memory revokedMsg = "Revoked";

        if (contractActivated == true && block.timestamp < endContract) {
            return (activated, block.timestamp);
        } else if (contractActivated == false && renter != address(0)) {
            return (revokedMsg, block.timestamp);
        } else if (block.timestamp > endContract && contractActivated == true) {
            return (expired, block.timestamp);
        } else {
            return (waiting, block.timestamp);
        }
    }
    
    event amountReceive_(address _renter, uint value);

    receive() external payable { 
        emit amountReceive_(msg.sender, msg.value);
    }   

    modifier whitdrawRules() {
        require((address(this).balance > 0),"Insufficient amount to withdraw");
        require(msg.sender == owner, "Only owner can make a withdrawal");
        require(contractActivated == true, "The contract must be in active status to make a withdrawal");
        _;
    }

    function withdraw() external whitdrawRules {
        payable(owner).transfer(address(this).balance);
    }

    /*modifier ChangeOwnerRules() {
        require((address(this).balance) >= 10**17, "Deposit 0.01 SepoliaETH to become the owner of the contract ");
        require(contractActivated == false, "The contract is already active");
        require(renter != address(0), "The Contract has been revoked");
        _;
    }
    function changeOwner(address newOwner) ChangeOwnerRules public {
        owner = newOwner;
    }*/
}
