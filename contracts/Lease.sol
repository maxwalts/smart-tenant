pragma solidity ^0.6.0;
import "./SafeMath.sol";

contract Lease {
    
    /**
     * Events
    */ 
    event AgreementReached(
        address landlord,
        address tenant,
        string propertyAddress
        
    );
    event OfferMade(
        uint8 term,
        uint256 rent,
        uint256 securityDeposit,
        address sender
    );
    event Aborted();
    
    /**
     * Addresses
    */ 
    address payable public landlord;
    address payable public primaryTenant;
    
    /**
     * Structs
    */ 
    struct Property {
        string streetAddress;
        uint256 numBeds;
        uint256 sqFt;
    }
    Property public property;
    
    struct Offer {
        uint8 term; //how many months the contract lasts
        uint256 rent; //monthly rate
        uint securityDeposit; //security deposit is a multiple of the monthly rent
    }
    Offer public offer;
    
    struct CounterOffer {
        uint8 term;
        uint256 rent;
        uint256 securityDeposit;
    }
    CounterOffer public counterOffer;
    
    /*
    / Variables
    */ 
    uint8 constant internal SD_LIMIT = 2; //highest multiple allowed for security deposit
    uint256 public expiration; //time out the offer before activation if no agreement is met
    
    mapping (address => uint256) public balancesDue; //key a tenant address to a balance due value
    mapping (uint8 => bool) public monthsPaid; //key a month (1-12) to true (paid) or false (unpaid)
    uint8 public currentMonth = 1;
    
    enum State{Unsigned, AwaitingDeposit, Active, Closed}
    State public currentState; //defaults to first value
    
    /*
    / Modifiers
    */ 
    modifier offerIsValid(uint8 _term, uint256 _rent, uint256 _securityDeposit) {
        require(
            _term >= 2 && _term <= 12,
            "Review offer; a valid term is between 2 and 12, inclusive."
        );
        require(
            _rent > 100 && _rent < 10000,
            "Review offer; a valid rent value is between 100 and 10000."
        );
        require(
            _securityDeposit > 50 && _securityDeposit < 20000,
            "Review offer; a valid security deposit is between 50 and 20000."
        );
        require (
            _securityDeposit <= SafeMath.mul(_rent, SD_LIMIT), 
            "Security deposit must not exceed twice the monthly rent."
        );
        _;
    }
    
    modifier onlyLandlord() {
        require (
            msg.sender == landlord, 
            "Caller must be Landlord."
        );
        _;
    }
    modifier onlyTenant() {
        require (
            msg.sender == primaryTenant, 
            "Caller must be Primary Tenant."
        );
        _;
    }
    
    modifier inState(State _state) {
        require(
            currentState == _state,
            "Invalid state."
        );
        _;
    }
    
    /*
    / Constructor
    */ 
    constructor(address payable _primaryTenant, uint256 duration) 
        public
        payable
    {
        primaryTenant = _primaryTenant;
        landlord = msg.sender;
        expiration = SafeMath.add(block.timestamp, duration);
    }
    
    /*
    / onlyLandlord functions
    */ 
    function setProperty(string memory _streetAddress, uint256 _numBeds, uint256 _sqFt) 
        public 
        onlyLandlord
    {
        property.streetAddress = _streetAddress;
        property.numBeds = _numBeds;
        property.sqFt = _sqFt;
    }
    
    function makeOffer(uint8 _term, uint _rent, uint _securityDeposit) 
        public 
        onlyLandlord 
        offerIsValid(_term, _rent, _securityDeposit)
        inState(State.Unsigned)
    {
        offer.term = _term;
        offer.rent = _rent;
        offer.securityDeposit = _securityDeposit;

        emit OfferMade(_term, _rent, _securityDeposit, landlord);
    }

    function abort() //landlord can abort the contract before it has been signed, for example of they find another tenant.
        public
        onlyLandlord
        inState(State.Unsigned)
    {
        currentState = State.Closed;
        emit Aborted();
        selfdestruct(msg.sender);
    }
    
    function extendContract(uint256 timeToAdd) /// the sender can extend the expiration at any time
        public 
        onlyLandlord
        inState(State.Unsigned)
    {
        expiration = SafeMath.add(expiration, timeToAdd);
    }
    
    /*
    / onlyTenant functions
    */ 
    function makeCounterOffer(uint8 _term, uint _rent, uint _securityDeposit) 
        public 
        onlyTenant 
        offerIsValid(_term, _rent, _securityDeposit)
        inState(State.Unsigned)
    {
        counterOffer.term = _term;
        counterOffer.rent = _rent;
        counterOffer.securityDeposit = _securityDeposit;

        emit OfferMade(_term, _rent, _securityDeposit, primaryTenant);
    }
    
    function sign()
        public 
        onlyTenant
        inState(State.Unsigned)
    {
        require(offer.term == counterOffer.term);
        require(offer.rent == counterOffer.rent);
        require(offer.securityDeposit == counterOffer.securityDeposit);
        
        require(block.timestamp < expiration); //contract must be signed before the expiration date
        
        currentState = State.AwaitingDeposit;
        balancesDue[primaryTenant] = offer.securityDeposit;
        
        emit AgreementReached(landlord, primaryTenant, property.streetAddress);

    }

    function paySD() //activates the contract
        public
        payable
        onlyTenant
        inState(State.AwaitingDeposit)
    {
        require(
            msg.value == offer.securityDeposit, 
            "you must pay the security deposit exactly."
        );
        
        require(
            balancesDue[primaryTenant] == offer.securityDeposit, 
            "balance due does not equal security deposit."
        );
        landlord.transfer(balancesDue[primaryTenant]);
        balancesDue[primaryTenant] = offer.rent;
        
        currentState = State.Active;
    }
    
    function payRent()
        public 
        payable
        onlyTenant
        inState(State.Active)
    {
        require(
            msg.value == offer.rent, 
            "you must pay the rent exactly."
        );

        require(
            balancesDue[primaryTenant] == offer.rent, 
            "balance due does not equal rent."
        );
        landlord.transfer(balancesDue[primaryTenant]);
        balancesDue[primaryTenant] = offer.rent;
        
        monthsPaid[currentMonth] = true;
        currentMonth++;
        
        if (currentMonth > offer.term) {
            balancesDue[primaryTenant] = 0;
            currentState = State.Closed;
        }
    }
    
    
}