// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract RentalContract {
    address public owner;
    address public renter;
    string public propertyAddress;
    uint256 public rentalPrice;
    uint256 public contractDuration;
    uint256 public contractStartTimestamp;
    uint256 public endContract;
    uint256 public renewDuration;
    uint256 public renovation;
    string  message;

    event StartRentalContract(
        address owner,
        address renter,
        string propertyAddress,
        uint256 rentalPrice,
        uint256 contractDuration,
        uint256 contractStartTimestamp
    );

    constructor() {
        owner = msg.sender;
        contractStartTimestamp = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Only the owner can initiate a Rental Contract");
        _;
    }

    modifier RulesForStartingRentalContract() {
        require(renter != address(owner),"The renter's address must be different from the owner's address");
        require(renter != address(0), "Renter address invalid");
        require(rentalPrice > 0, "The rental price must be greater than 0");
        require(contractDuration > 0,"The contract duration must be greater than 0");

        //avoid reassigning variable state, avoid the same rental contract from being issued to more than one
        //require(renter == address(0), "The contract has already initiate");
        _;
    }

    function setStartRentalContract(
        address _renter,
        string memory _propertyAddress,
        uint256 _rentalPrice,
        uint256 _contractDuration
    ) public {
        

        renter = _renter;
        propertyAddress = _propertyAddress;
        rentalPrice = _rentalPrice;
        contractDuration = _contractDuration;
        endContract = (contractStartTimestamp + contractDuration);

        emit StartRentalContract(
            owner,
            renter,
            propertyAddress,
            rentalPrice,
            contractDuration,
            contractStartTimestamp
        );
    }

    function getStartRentalContract()
        public
        view
        returns (
            address,
            string memory,
            uint256,
            uint256,
            uint256,
            uint256,
            string memory
        )
    {
        return (
            renter,
            propertyAddress,
            rentalPrice,
            contractDuration,
            contractStartTimestamp,
            endContract,
            message
        );
    }

    function setRenewContract(address _renter, uint256 _renewDuration) public {
        require(_renter == renter,"Only the renter can renew the rental contract");
        require(_renewDuration > 0,"The renew duration must be greater than 0");
        require(_renter != address(0));
        renter = _renter;
        renewDuration = _renewDuration;
        renovation = endContract += renewDuration;
    }

    function getRenewContract()
        public
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        return (renter, renewDuration, renovation);
    }

    function RevokeRentalContract() public {
        renter = address(0);
        propertyAddress = "";
        rentalPrice = 0;
        contractDuration = 0;
        contractStartTimestamp = 0;
        endContract = 0;
        message = "This rental contract has been revoked";
    }

    function expirationCheck() public view returns (string memory) {
        uint256 currentDay = block.timestamp;
        string memory expired = "The contract has expired";
        string memory notExpired = "The contract has not yet expired";

        if (currentDay > endContract && currentDay > renovation) {
            return expired;
        } else {
            return notExpired;
        }
    }
}