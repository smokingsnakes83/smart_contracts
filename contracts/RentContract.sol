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
    uint8 public statusWaiting;
    uint8 public statusActivated;
    uint8 public statusExpired;
    uint8 public statusRevoked;
    bool public revoked;
    bool public contractActivated;

    constructor() {
        owner = msg.sender;
        contractActivated = false;
        statusWaiting = 0;
        statusActivated = 1;
        statusExpired = 2;
        statusRevoked = 3;
        revoked = false;
    }

    event _starting( address owner, address renter, uint256 rentPrice, uint contractDuration,
        uint contractStartTimestamp, uint endContract, bool contractActivated
    );
    event amountReceive(address renter, uint value);
    event renovationTime(uint renovation);
    event changeSend(address renter, uint _change);
    event rentPayment(address owner, uint payment);
    event _revoked(uint8 statusRevoked);
    event status(uint8);

    receive() external payable {
        renter = payable(msg.sender);
        emit amountReceive(msg.sender, msg.value);
    }

    modifier setPriceRules() {
        require(msg.sender == owner, "Only the owner can set the rental price");
        _;
    }

    function setPrice(uint256 _rentPrice) public setPriceRules {
        rentPrice = _rentPrice;
    }

    modifier startContractRules(uint256 _contractDuration) {
        require(msg.sender == owner, "Only the owner can start a Contract");
        require(contractActivated == false, "Contract is already activated");
        require(revoked == false, "The contract was revoked");
        require((address(this).balance) >= rentPrice, "Insufficient balance in the contract, it is necessary to deposit the agreed rent price");
        require((address(this).balance) >= rentPrice, "Deposit the agreed rent price");
        require(_contractDuration > 0,"The contract duration must be greater than 0");
        
        _;
    }

    function startContract(uint _contractDuration) public startContractRules(_contractDuration) {
        contractDuration = _contractDuration;
        contractStartTimestamp = block.timestamp;
        endContract = (contractStartTimestamp + contractDuration);
        contractActivated = true;

        //If the renter deposits more super.startContract(renter, contractDuration);than 0.001 SepoliaETH, the change will be returned to their wallet
        change();

        //Execute payment to the contract owner
        paymentToOwner();

        emit _starting(
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
        returns (address, uint, uint, uint, uint)
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

    function renewContract(uint _renovation) public renovationRules(_renovation) {
        renovation = _renovation;
        endContract = block.timestamp;
        endContract += renovation;
        contractDuration += renovation;

        //If the renter deposits more than the agreed rent price, the change will be returned to their wallet
        change();

        //Execute payment to the contract owner
        paymentToOwner();

        emit renovationTime(renovation);
    }

    function getRenewContract() public view returns (address, uint) {
        return (renter, renovation);
    }

    modifier revocationRules() {
        require(msg.sender == owner, "Only owner can to revoke the contract");
        require(contractActivated == true, "Contract is not active");
        _;
    }

    function revokeContract() public revocationRules() {
        contractActivated = false;
        revoked = true;
        emit _revoked(statusRevoked);
    }

    function statusCheck() public returns (uint8) {
        if (contractActivated == true && block.timestamp < endContract) {
            emit status(statusActivated);
            return statusActivated;
        } else if (revoked == true) {
            emit status(statusRevoked);
            return statusRevoked;
        } else if (block.timestamp > endContract && contractActivated == true) {
            emit status(statusExpired);
            return statusExpired;
        } else {
            emit status(statusWaiting);
            return statusWaiting;
        }
    }

    //Execute payment to the contract owner
    function paymentToOwner() internal {
        uint payment = (address(this).balance);
        payable(owner).transfer(address(this).balance);
        emit rentPayment(owner, payment);
    }

    //If the renter deposits more than rent price, the change will be returned to their wallet
    function change() internal {
        if ((address(this).balance) > rentPrice) {
            uint totalBalance;
            uint _change;

            totalBalance = (address(this).balance);
            _change = (address(this).balance) - rentPrice;
            payable(renter).transfer(_change);

            emit changeSend(renter, _change);
        }
    }

    modifier ChangeOwnerRules() {
        require(
            msg.sender == owner, "Only the owner can transfer ownership of the contract");
        _;
    }
    function changeOwner(address newOwner) public ChangeOwnerRules {
        owner = newOwner;
    }
}
