// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract RideSharing {
    address public owner;

    struct User {
        uint userId;
        string username;
        address walletaddress;
        uint walletBalance;
    }

    struct Driver {
        uint driverId;
        uint userId;
        string licenseNumber;
        string carModel;
        uint rating;
    }

    struct Ride {
        uint rideId;
        uint driverId;
        uint riderId;
        string startLocation;
        string endLocation;
        uint startTime;
        uint endTime;
        uint fare;
        string status;
    }

    struct Transaction {
        uint transactionId;
        uint rideId;
        uint payerId;
        uint payeeId;
        uint amount;
        uint timestamp;
    }

    struct Rating {
        uint ratingId;
        uint rideId;
        uint ratingValue;
        string comment;
        uint ratedByUserId;
        uint ratedDriverId;
    }

    constructor() {
        owner = msg.sender;
    }

    mapping(uint => User) public users;
    mapping(uint => Driver) public drivers;
    mapping(uint => Ride) public rides;
    mapping(uint => Transaction) public transactions;
    mapping(uint => Rating) public ratings;

    uint public userCount;
    uint public driverCount;
    uint public rideCount;
    uint public transactionCount;
    uint public ratingCount;

    address[] public requestForDriverForApproval;
    address[] public driversApproved;

    function getUserCount() external view returns (uint) {
        return userCount;
    }

    function getDriverCount() external view returns (uint) {
        return driverCount;
    }

    function getRideCount() external view returns (uint) {
        return rideCount;
    }

    function getTransactionCount() external view returns (uint) {
        return transactionCount;
    }

    function getRatingCount() external view returns (uint) {
        return ratingCount;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getUser(uint _userId) external view returns (User memory) {
        return users[_userId];
    }

    function getDriver(uint _driverId) external view returns (Driver memory) {
        return drivers[_driverId];
    }

    function getRide(uint _rideId) external view returns (Ride memory) {
        return rides[_rideId];
    }

    function getTransaction(
        uint _transactionId
    ) external view returns (Transaction memory) {
        return transactions[_transactionId];
    }

    function getRating(uint _ratingId) external view returns (Rating memory) {
        return ratings[_ratingId];
    }

    function isDriverApproved(address _address) public view returns (bool) {
        for (uint i = 0; i < driversApproved.length; i++) {
            if (driversApproved[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function isDriverRequestPending(
        address _address
    ) public view returns (bool) {
        for (uint i = 0; i < requestForDriverForApproval.length; i++) {
            if (requestForDriverForApproval[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function requestForDriverApproval() external {
        require(
            !isDriverRequestPending(msg.sender),
            "Driver request is already pending"
        );
        requestForDriverForApproval.push(msg.sender);
    }

    function approveDriver(address _address) external {
        require(msg.sender == owner, "Only owner can approve driver requests");
        require(
            isDriverRequestPending(_address),
            "Driver request is not pending"
        );
        driversApproved.push(_address);
    }

    function getAllRequestForDriverApproval()
        external
        view
        returns (address[] memory)
    {
        return requestForDriverForApproval;
    }

    function getAllApprovedDrivers() external view returns (address[] memory) {
        return driversApproved;
    }

    function registerUser(string memory _username) external {
        // NOTE:- Make user at the time of wallet connection
        for (uint i = 1; i <= userCount; i++) {
            if (
                keccak256(abi.encodePacked(users[i].walletaddress)) ==
                keccak256(abi.encodePacked(msg.sender))
            ) {
                revert("User is already registered with this wallet address");
            }
        }
        userCount++;
        users[userCount] = User(userCount, _username, msg.sender, 0);
    }

    function registerDriver(
        uint _userId,
        string memory _licenseNumber,
        string memory _carModel
    ) external {
        require(
            isDriverApproved(msg.sender),
            "Driver is not approved by the owner"
        );
        driverCount++;
        drivers[driverCount] = Driver(
            driverCount,
            _userId,
            _licenseNumber,
            _carModel,
            0
        );
    }

    function createRide(
        uint _driverId,
        uint _riderId,
        string memory _startLocation,
        string memory _endLocation,
        uint _startTime,
        uint _fare
    ) external {
        rideCount++;
        rides[rideCount] = Ride(
            rideCount,
            _driverId,
            _riderId,
            _startLocation,
            _endLocation,
            _startTime,
            0,
            _fare,
            "booked"
        );
    }

    function startRide(uint _rideId, uint _startTime) external {
        Ride storage ride = rides[_rideId];
        require(
            keccak256(abi.encodePacked(ride.status)) ==
                keccak256(abi.encodePacked("booked")),
            "Ride is not booked"
        );

        require(
            msg.sender == users[ride.riderId].walletaddress,
            "Only rider can start the ride"
        );

        ride.startTime = _startTime;
        ride.status = "ongoing";
    }

    function completeRide(uint _rideId, uint _endTime) external {
        Ride storage ride = rides[_rideId];
        require(
            keccak256(abi.encodePacked(ride.status)) ==
                keccak256(abi.encodePacked("ongoing")),
            "Ride is not ongoing"
        );

        require(
            msg.sender == users[ride.riderId].walletaddress,
            "Only rider can complete the ride"
        );

        ride.endTime = _endTime;
        ride.status = "completed";
    }

    function recordTransaction(
        uint _rideId,
        uint _payerId,
        uint _payeeId,
        uint _amount,
        uint _timestamp
    ) external {
        transactionCount++;
        transactions[transactionCount] = Transaction(
            transactionCount,
            _rideId,
            _payerId,
            _payeeId,
            _amount,
            _timestamp
        );
    }

    function recordRating(
        uint _rideId,
        uint _ratingValue,
        string memory _comment,
        uint _ratedByUserId,
        uint _ratedDriverId
    ) external {
        ratingCount++;
        ratings[ratingCount] = Rating(
            ratingCount,
            _rideId,
            _ratingValue,
            _comment,
            _ratedByUserId,
            _ratedDriverId
        );
        // CODE IS LEFT
    }

    function getUserDetails(
        uint _userId
    ) external view returns (uint, string memory, address, uint) {
        User memory user = users[_userId];
        return (
            user.userId,
            user.username,
            user.walletaddress,
            user.walletBalance
        );
    }

    function getDriverDetails(
        uint _driverId
    ) external view returns (uint, uint, string memory, string memory, uint) {
        Driver memory driver = drivers[_driverId];
        return (
            driver.driverId,
            driver.userId,
            driver.licenseNumber,
            driver.carModel,
            driver.rating
        );
    }

    function getRideDetails(
        uint _rideId
    )
        external
        view
        returns (
            uint,
            uint,
            uint,
            string memory,
            string memory,
            uint,
            uint,
            uint,
            string memory
        )
    {
        Ride memory ride = rides[_rideId];
        return (
            ride.rideId,
            ride.driverId,
            ride.riderId,
            ride.startLocation,
            ride.endLocation,
            ride.startTime,
            ride.endTime,
            ride.fare,
            ride.status
        );
    }

    function getTransactionDetails(
        uint _transactionId
    ) external view returns (uint, uint, uint, uint, uint, uint) {
        Transaction memory transaction = transactions[_transactionId];
        return (
            transaction.transactionId,
            transaction.rideId,
            transaction.payerId,
            transaction.payeeId,
            transaction.amount,
            transaction.timestamp
        );
    }

    function getRatingDetails(
        uint _ratingId
    ) external view returns (uint, uint, uint, string memory, uint, uint) {
        Rating memory rating = ratings[_ratingId];
        return (
            rating.ratingId,
            rating.rideId,
            rating.ratingValue,
            rating.comment,
            rating.ratedByUserId,
            rating.ratedDriverId
        );
    }

    function isRideCompleted(uint _rideId) external view returns (bool) {
        Ride memory ride = rides[_rideId];
        if (
            keccak256(abi.encodePacked(ride.status)) ==
            keccak256(abi.encodePacked("completed"))
        ) {
            return true;
        }
        return false;
    }
}
