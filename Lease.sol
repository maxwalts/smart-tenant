pragma solidity ^0.6.0;
import "./SafeMath.sol";

contract Lease {
    
    event agreementReached(
        address landlord,
        address tenant,
        address contractAddress
        
    );
    
    enum State{Unsigned, awaitingDeposit, Active, Closed}
    State currentState = State.Unsigned;
    
    function getState() 
        public 
        view 
        returns (uint) 
    {
        return uint(currentState);
    }
    
    /**
     * parties
    */ 
    address payable landlord;
    address primaryTenant;
    
    /**
     * Structs
    */ 
    struct Property {
        string streetAddress;
        uint256 numBeds;
        uint256 sqFt;
    }
    Property property;
    
    struct Offer {
        uint256 term; //how many months the contract lasts
        uint256 rent; //monthly rate
        uint securityDeposit; //security deposit is a multiple of the monthly rent
    }
    Offer offer;
    
    struct CounterOffer {
        uint256 term;
        uint256 rent;
        uint256 securityDeposit;
    }
    CounterOffer counterOffer;
    
    /*
    / Legal
    */ 
    //highest multiple allowed for security deposit
    uint internal sdCap;
    
    mapping (address => uint256) public balances; //key a tenant address to a balance due value
    
    modifier offerIsValid() {
        require(
            offer.rent > 100 && offer.rent < 10000,
            "Review offer; a valid rent value is between 100 and 10000."
        );
        require(
            offer.term >= 1 && offer.term <= 12,
            "Review offer; a valid term is between 1 and 12, inclusive."
        );
        require(
            offer.securityDeposit > 50 && offer.securityDeposit < 20000,
            "Review offer; a valid security deposit is between 50 and 20000."
        );
        require (
            offer.securityDeposit <= SafeMath.mul(offer.rent, 2), 
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
    modifier contractUnsigned() {
        require (
            currentState == State.Unsigned, 
            "The contract must be unsigned to do this."
        );
        _;
    }
    modifier awaitingDeposit() {
        require (
            currentState == State.awaitingDeposit, 
            "The contract must be awaiting deposit to do this."
        );
        _;
    }
    modifier contractActive() {
        require (
            currentState == State.Active, 
            "The contract must be Active to do this."
        );
        _;
    }
    modifier contractClosed() {
        require (
            currentState == State.Closed, 
            "The contract must be Closed to do this."
        );
        _;
    }
    
    function makeOffer(uint _term, uint _rent, uint _securityDeposit) 
        public 
        onlyLandlord 
        contractUnsigned
    {
        
        offer.term = _term;
        offer.rent = _rent;
        offer.securityDeposit = _securityDeposit;
    }

    function makeCounterOffer(uint _term, uint _rent, uint _securityDeposit) 
        public 
        onlyTenant 
        contractUnsigned
    {
        counterOffer.term = _term;
        counterOffer.rent = _rent;
        counterOffer.securityDeposit = _securityDeposit;
    }
    
    function sign()
        public 
        onlyTenant
        contractUnsigned
        offerIsValid
    {
        currentState = State.awaitingDeposit;
    }
    
    function paySD()
        public
        onlyTenant
        awaitingDeposit
    {
        currentState = State.Active;
    }
    
    
    constructor(address payable _landLord) public {
        landlord = _landLord;
        primaryTenant = msg.sender;
        sdCap = 2;
    }
    
}