// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RentContract {
    address public owner;
    address payable public renter;
    uint256 public rentPrice;
    uint public contractDuration;
    uint public contractStartTimestamp;
    uint public endContract;
    uint public renovation;
    bool public contractActivated;
    
    constructor() {
        owner = msg.sender;
        contractDuration = 0;
        contractStartTimestamp = 0;
        endContract = 0;
        renovation = 0;
        contractActivated = false;
    }

    event starting(
        address owner,
        address renter,
        uint256 rentPrice,
        uint contractDuration,
        uint contractStartTimestamp,
        uint endContract,
        bool contractActivated
    );

    modifier startContractRules(address payable _renter, uint256 _contractDuration ) {
        require(msg.sender == owner, "Only the owner can start a Contract");
        require((address(this).balance) > 0, "Insufficient balance in the contract, it is necessary to deposit the agreed rent price");
        require((address(this).balance) >= rentPrice, "Deposit the agreed rent price");
        require(_renter != msg.sender,"The renter's address must be different from the owner's address");
        require(_contractDuration > 0, "The contract duration must be greater than 0");
        
        //avoid reassigning variable state, avoid the same rent contract from being issued to more than one time
        //require(renter == address(0), "contract is already active"); //commented to run the test
         _;
    }
    
    event changeSend(address, uint);
    event rentPayment(address, uint);
    
    function startContract(address payable  _renter, uint _contractDuration) 
        public startContractRules(_renter, _contractDuration) {
        renter = _renter;
        contractDuration = _contractDuration;
        contractStartTimestamp = block.timestamp;
        endContract = (contractStartTimestamp + contractDuration);
        contractActivated = true;      

        //If the renter deposits more super.startContract(renter, contractDuration);than 0.001 SepoliaETH, the change will be returned to their wallet
        change();

        //Execute payment to the contract owner
        paymentToOwner();

        emit starting(
            owner,
            renter,
            rentPrice,
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
            rentPrice,
            contractDuration,
            contractStartTimestamp,
            endContract
        );
    }

    modifier renovationRules(uint _renovation) {
        require(contractActivated == true, "The contract is not active");
        require((address(this).balance) >= rentPrice, "Deposit the agreed amount to renew the contract");
        require(msg.sender == renter, "Only the renter can renew the rent contract");
        require(_renovation > 0, "The renovation must be greater than 0");
        require(block.timestamp > endContract, "The contract has not yet expired");
        _;
    }

    event renovationTime(uint);

    function renovationContract(address payable  _renter, uint _renovation) public renovationRules(_renovation) {
        renter = _renter;
        renovation = _renovation;
        endContract = block.timestamp;
        endContract += renovation;
        contractDuration += renovation;    

        //If the renter deposits more than 0.001 SepoliaETH, the change will be returned to their wallet
        change();
        
        //Execute payment to the contract owner
        paymentToOwner();

        emit renovationTime(renovation);
    }

    function getRenovationContract() public view returns (address, uint) {
        return (renter, renovation);
    }

    modifier revoke() {
        require(msg.sender == owner, "Only owner can to revoke the contract");
        require(contractActivated == true, "Contract is not active");
        _;
    }

    event revoked(string);

    function revokeContract() public revoke {
        contractActivated = false;
        string memory _revoked = "Contract Revoked";
        emit revoked(_revoked);
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
        rentPrice = msg.value;
        emit amountReceive_(msg.sender, msg.value);
    }   

    //Execute payment to the contract owner
    function paymentToOwner() internal {
        uint payment = (address(this).balance); 
        payable(owner).transfer(address(this).balance);
        emit rentPayment(owner, payment);
    }
    
    //If the renter deposits more than rent price, the change will be returned to their wallet
    function change() internal {
        if((address(this).balance) > rentPrice) {
            uint totalBalance;
            uint _change;

            totalBalance = (address(this).balance);
            _change = (address(this).balance) - rentPrice;
            payable(renter).transfer(_change);

            emit changeSend(renter, _change);
        }
    }

    modifier ChangeOwnerRules() {
        require(msg.sender == owner, "Only the owner can transfer ownership of the contract");
        _;
    }
    function changeOwner(address newOwner) ChangeOwnerRules public {
        owner = newOwner;
    }
}
