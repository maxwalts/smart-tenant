const Lease = artifacts.require('./Lease.sol') //reference of the contract

contract('Lease', (accounts) => {
	before(async () => {
		this.lease = await Lease.deployed()
	})

	it('deploys!', async () => {
		const address = await this.lease.address
		assert.notEqual(address, 0x0)
		assert.notEqual(address, '')
		assert.notEqual(address, null)
		assert.notEqual(address, undefined)
	})
})