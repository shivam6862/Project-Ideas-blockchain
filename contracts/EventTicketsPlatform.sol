// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract EventTicketsPlatform {
    address public owner;

    struct Event {
        uint256 eventId;
        string eventName;
        string location;
        uint256 date;
        address organizer;
    }

    struct Ticket {
        uint256 ticketId;
        uint256 eventId;
        string ticketType;
        uint256 price;
        address owner;
        string status;
        string ticketPassword;
    }

    struct Transaction {
        uint256 transactionId;
        uint256 ticketId;
        address buyer;
        address seller;
        uint256 amount;
        uint256 transactionDate;
    }

    mapping(uint256 => Event) public events;
    mapping(uint256 => Ticket) public tickets;
    mapping(uint256 => Transaction) public transactions;

    address[] public requestForEventOrganizerForApproval;
    address[] public requestForTicketManagerForApproval;
    address[] public eventOrganizers;
    address[] public ticketManagers;

    uint256 public eventCount;
    uint256 public ticketCount;
    uint256 public transactionCount;

    constructor() {
        owner = msg.sender;
    }

    // Getters
    function getEventCount() external view returns (uint256) {
        return eventCount;
    }

    function getTicketCount() external view returns (uint256) {
        return ticketCount;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactionCount;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function isEventOrganizer(address _address) public view returns (bool) {
        for (uint256 i = 0; i < eventOrganizers.length; i++) {
            if (eventOrganizers[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function isTicketManager(address _address) public view returns (bool) {
        for (uint256 i = 0; i < ticketManagers.length; i++) {
            if (ticketManagers[i] == _address) {
                return true;
            }
        }
        return false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyEventOrganizer() {
        require(isEventOrganizer(msg.sender), "Not an event organizer");
        _;
    }

    modifier onlyTicketManager() {
        require(isTicketManager(msg.sender), "Not a ticket manager");
        _;
    }

    // Event Organizer and Ticket Manager requests
    function requestForEventOrganizer() external {
        require(!isEventOrganizer(msg.sender), "Already an event organizer");
        requestForEventOrganizerForApproval.push(msg.sender);
    }

    function getAllRequestForEventOrganizer()
        external
        view
        returns (address[] memory)
    {
        return requestForEventOrganizerForApproval;
    }

    function requestForTicketManager() external {
        require(!isTicketManager(msg.sender), "Already a ticket manager");
        requestForTicketManagerForApproval.push(msg.sender);
    }

    function getAllRequestForTicketManager()
        external
        view
        returns (address[] memory)
    {
        return requestForTicketManagerForApproval;
    }

    // Approval functions
    function approveEventOrganizer(address _eventOrganizer) external onlyOwner {
        require(!isEventOrganizer(_eventOrganizer), "Already approved");
        eventOrganizers.push(_eventOrganizer);
        removeRequest(requestForEventOrganizerForApproval, _eventOrganizer);
    }

    function approveTicketManager(address _ticketManager) external onlyOwner {
        require(!isTicketManager(_ticketManager), "Already approved");
        ticketManagers.push(_ticketManager);
        removeRequest(requestForTicketManagerForApproval, _ticketManager);
    }

    function removeRequest(
        address[] storage requestList,
        address target
    ) internal {
        for (uint256 i = 0; i < requestList.length; i++) {
            if (requestList[i] == target) {
                requestList[i] = requestList[requestList.length - 1];
                requestList.pop();
                break;
            }
        }
    }

    // Event and Ticket creation
    function createEvent(
        string memory _eventName,
        string memory _location,
        uint256 _date
    ) external onlyEventOrganizer {
        eventCount++;
        events[eventCount] = Event(
            eventCount,
            _eventName,
            _location,
            _date,
            msg.sender
        );
    }

    function getLast10Events()
        external
        view
        returns (Event[] memory last10Events, uint256 count)
    {
        count = eventCount > 10 ? 10 : eventCount;
        last10Events = new Event[](count);
        for (uint256 i = eventCount; i > eventCount - count; i--) {
            last10Events[eventCount - i] = events[i];
        }
    }

    function get10EventsFrom(
        uint256 _eventCount
    ) external view returns (Event[] memory last10Events, uint256 count) {
        count = _eventCount > 10 ? 10 : _eventCount;
        last10Events = new Event[](count);
        for (uint256 i = _eventCount; i > _eventCount - count; i--) {
            last10Events[_eventCount - i] = events[i];
        }
    }

    function createTicket(
        uint256 _eventId,
        string memory _ticketType,
        uint256 _price,
        string memory _ticketPassword
    ) external onlyTicketManager {
        require(_eventId <= eventCount && _eventId > 0, "Invalid Event ID");
        ticketCount++;
        tickets[ticketCount] = Ticket(
            ticketCount,
            _eventId,
            _ticketType,
            _price,
            msg.sender,
            "Available",
            _ticketPassword
        );
    }

    // Ticket purchase
    function buyTicket(
        uint256 _ticketId,
        string memory _hashedString
    ) external payable {
        require(_ticketId <= ticketCount && _ticketId > 0, "Invalid Ticket ID");
        Ticket storage ticket = tickets[_ticketId];
        require(msg.value == ticket.price, "Incorrect amount sent");

        require(
            keccak256(abi.encodePacked(ticket.status)) ==
                keccak256(abi.encodePacked("Available")),
            "Ticket not available"
        );

        require(
            keccak256(abi.encodePacked(_hashedString)) ==
                keccak256(abi.encodePacked(ticket.ticketPassword)),
            "Incorrect password"
        );

        transactionCount++;
        transactions[transactionCount] = Transaction(
            transactionCount,
            _ticketId,
            msg.sender,
            ticket.owner,
            msg.value,
            block.timestamp
        );

        ticket.owner = msg.sender;
        ticket.status = "Sold";
    }

    // Ticket details
    function showTicketDetails(
        string memory _hashedString
    )
        external
        view
        returns (
            uint256,
            uint256,
            string memory,
            uint256,
            address,
            string memory,
            string memory
        )
    {
        for (uint256 i = 1; i <= ticketCount; i++) {
            Ticket memory ticket = tickets[i];
            if (
                keccak256(abi.encodePacked(ticket.ticketPassword)) ==
                keccak256(abi.encodePacked(_hashedString))
            ) {
                return (
                    ticket.ticketId,
                    ticket.eventId,
                    ticket.ticketType,
                    ticket.price,
                    ticket.owner,
                    ticket.status,
                    ticket.ticketPassword
                );
            }
        }
        return (0, 0, "", 0, address(0), "", "");
    }
}
