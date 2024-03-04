// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RentalContract {
    address public owner;
    address payable public renter;
    uint public priceInWei;
    uint public contractDuration;
    uint public contractStartTimestamp;
    uint public endContract;
    uint public renovation;
    bool public contractActivated;
    
    constructor() {
        owner = msg.sender;
        priceInWei = 10**15;
        contractDuration = 0;
        contractStartTimestamp = 0;
        endContract = 0;
        renovation = 0;
        contractActivated = false;
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
        require((address(this).balance) >= priceInWei, "deposit amount 0.001 SepoliaETH");
        require(_renter != address(owner),"The renter's address must be different from the owner's address");
        require(_renter != address(0), "Renter address invalid");
        require(_contractDuration > 0, "The contract duration must be greater than 0");
        
        //avoid reassigning variable state, avoid the same rental contract from being issued to more than one time
        //require(renter == address(0), "contract is already active"); //comment to run the test
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
        Change();

        //Execute payment to the contract owner
        paymentToOwner();

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
        require((address(this).balance) >= priceInWei, "deposit amount 0.001 SepoliaETH");   
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
        Change();
        
        //Execute payment to the contract owner
        paymentToOwner();
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

    //Execute payment to the contract owner
    function paymentToOwner() internal {
        uint payment = (address(this).balance); 
        payable(owner).transfer(address(this).balance);
        emit paymentRental(owner, payment);
    }
    
    //If the renter deposits more than 0.001 SepoliaETH, the change will be returned to their wallet
    function Change() internal {
        if((address(this).balance) > priceInWei) {
            uint totalBalance;
            uint change;

            totalBalance = (address(this).balance);
            change = (address(this).balance) - priceInWei;
            payable(renter).transfer(change);

            emit sendChange(renter, change);
        }
    }

    modifier ChangeOwnerRules() {
        require(msg.sender == owner, "Only the owner can transfer ownership of the contract");
        _;
    }
    function changeOwner(address newOwner) ChangeOwnerRules public {
        owner = newOwner;
    }

    //  modifier whitdrawRules() {
    //     require((address(this).balance > 0),"Insufficient amount to withdraw");
    //     require(msg.sender == owner, "Only owner can make a withdrawal");
    //     require(contractActivated == true, "The contract must be in active status to make a withdrawal");
    //     _;
    // }

    // function withdraw() external whitdrawRules {
    //     payable(owner).transfer(address(this).balance);
    // }

    
}
