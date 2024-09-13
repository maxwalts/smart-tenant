# smart-tenant 
A smart contract to handle a lease agreement between two parties. 

### Rules
- Parties can only negotiate the contract before it has been signed
- Rent is paid at the very end of a month.
- Contract closes after last rent payment or upon abort()

### Organization
- One __tenant__ payable address
- One __landlord__ payable address
- __Property__ struct
- __Offer__ struct
- __CounterOffer__ struct
- mapping __balances__ to keep track of amount due

### Functions
- __onlyTenant:__
	- makeCounterOffer()
	- sign() - initializes the contract
	- paySD()
	- payRent()

- __onlyLandlord:__
	- *Constructor()*
	- setProperty()
	- makeOffer()
	- abort()
	- extendContract()

- __Open:__
	- view contract attributes with inherent getter functions

### States
- enum State{Unsigned, AwaitingDeposit, Active, Closed}
	- State.Unsigned: contract is awaiting an agreement between Offer and CounterOffer
	- State.AwaitingDeposit: tenant has signed but has not submitted a deposit
	- State.Active: the lease is active, rent is due at the end of every month
	- State.Closed: contract term has completed, or contract has been voided by the landlord.

### Testing

### Future
pull requests welcome!
