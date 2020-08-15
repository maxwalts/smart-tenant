pragma solidity ^0.6.0;
import "./SafeMath.sol";

contract Lease {
    
    event agreementReached(
        address landlord,
        address tenant,
        address contractAddress
        
    );
    
    enum State{Unsigned, AwaitingDeposit, Active, Closed}
    State public currentState; //defaults to first value
    
    /**
     * parties
    */ 
    address payable public landlord;
    address payable public primaryTenant;
    
    mapping (address => uint256) public balances; //key a tenant address to a balance due value
    mapping (uint8 => bool) public monthsPaid; //key a month (1-12) to true (paid) or false (unpaid)
    uint8 currentMonth = 1;
    
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
        uint256 term; //how many months the contract lasts
        uint256 rent; //monthly rate
        uint securityDeposit; //security deposit is a multiple of the monthly rent
    }
    Offer public offer;
    
    struct CounterOffer {
        uint256 term;
        uint256 rent;
        uint256 securityDeposit;
    }
    CounterOffer public counterOffer;
    
    /*
    / Legal
    */ 
    //highest multiple allowed for security deposit
    uint constant internal SD_LIMIT = 2;
    
    
    modifier offerIsValid() {
        require(
            offer.rent > 100 && offer.rent < 10000,
            "Review offer; a valid rent value is between 100 and 10000."
        );
        require(
            offer.term >= 2 && offer.term <= 12,
            "Review offer; a valid term is between 2 and 12, inclusive."
        );
        require(
            offer.securityDeposit > 50 && offer.securityDeposit < 20000,
            "Review offer; a valid security deposit is between 50 and 20000."
        );
        require (
            offer.securityDeposit <= SafeMath.mul(offer.rent, SD_LIMIT), 
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
    
    modifier condition(bool _condition) { //use this in the future to cut down code length.
        require(_condition);
        _;
    }
    
    modifier inState(State _state) {
        require(
            currentState == _state,
            "Invalid state."
        );
        _;
    }
    
    function makeOffer(uint _term, uint _rent, uint _securityDeposit) 
        public 
        onlyLandlord 
        offerIsValid
        inState(State.Unsigned)
    {
        
        offer.term = _term;
        offer.rent = _rent;
        offer.securityDeposit = _securityDeposit;
    }

    function makeCounterOffer(uint _term, uint _rent, uint _securityDeposit) 
        public 
        onlyTenant 
        offerIsValid
        inState(State.Unsigned)
    {
        counterOffer.term = _term;
        counterOffer.rent = _rent;
        counterOffer.securityDeposit = _securityDeposit;
    }
    
    function sign()
        public 
        onlyTenant
        inState(State.Unsigned)
    {
        require(offer.term == counterOffer.term);
        require(offer.rent == counterOffer.rent);
        require(offer.securityDeposit == counterOffer.securityDeposit);
        currentState = State.AwaitingDeposit;
    }
    
    function paySD()
        public
        payable
        onlyTenant
        inState(State.AwaitingDeposit)
    {
        currentState = State.Active;
    }
    
    function payRent()
        public 
        payable
        onlyTenant
        inState(State.Active)
    {
        monthsPaid[currentMonth] = true;
        currentMonth++;
        
        if (currentMonth > offer.term) {
            currentState = State.Closed;
        }
    }
    

    constructor(address payable _primaryTenant) public {
        primaryTenant = _primaryTenant;
        landlord = msg.sender;
    }
    
}