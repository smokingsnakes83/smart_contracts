const RentContract = artifacts.require("RentContract");

contract("RentContract", accounts => {
  let instance;
  const duration = 84600;
  const price = web3.utils.toWei("1", "ether");

  beforeEach(async () => {
    instance = await RentContract.new();
  })

  describe("When start contract", () => {
    it("Only contract's owner must call this function", async () => {
      const expectedOwnerAddress = accounts[0];
      await instance.startContract(duration);
      const actualOwnerAddress = await instance.owner.call();

      assert.equal(actualOwnerAddress, expectedOwnerAddress, "The account that made the call is not the owner's account");
    })

    it("The rent price should be price set in setPrice function ", async () => {
      await instance.setPrice(price);
      const rentPrice = await instance.rentPrice.call()

      assert.equal(price, rentPrice, "The rent price is not correct");
    })

    it("Contract duration must be greater than 0", async () => {
      await instance.startContract(duration);
      const contractDuration = await instance.contractDuration.call()

      assert.ok(contractDuration > 0, "contract duration must be greater than 0");
    })

    it("Should send change to renter", async () => {
      const renter = accounts[1];
      const renterDeposit = web3.utils.toWei("2", "ether");
      await instance.setPrice(price);
      await instance.sendTransaction({ from: renter, value: renterDeposit });
      const renterReceipt = await instance.startContract(84600);
      const change = renterReceipt.logs[0].args._change;

      assert.equal(renterReceipt.logs[0].event, "changeSend", "Event should be triggered");
      assert.equal(change, renterDeposit - price, "Change is not correct");
    })

    it("Should send rent payment to owner", async () => {
      await instance.setPrice(price);
      await instance.sendTransaction({ from: accounts[1], value: price });
      const ownerReceipt = await instance.startContract(84600);
      const payment = ownerReceipt.logs[0].args.payment;

      assert.equal(ownerReceipt.logs[0].event, "rentPayment", "Event should be triggered");
      assert.equal(payment, price, "Payment is not correct");
    })
  })

  describe("When renew contract", () => {
    it("Only renter can call this function", async () => {
      const expectedAddress = accounts[1];
      await instance.sendTransaction({ from: expectedAddress, value: web3.utils.toWei("1", "ether") });
      const actualAddress = await instance.renter.call()
      await instance.renewContract(duration);
      assert.equal(actualAddress, expectedAddress, "The account that made the call is not the renter's account")
    })

    it("The renovation must be greater than 0", async () => {
      const renter = accounts[1];
      await instance.renewContract(duration, { from: renter });
      const renovation = await instance.renovation.call()

      assert.ok(renovation > 0, "The renovation is not correct");
    })

    it("Should send change to renter", async () => {
      const renter = accounts[1];
      const renterDeposit = web3.utils.toWei("2", "ether");
      await instance.setPrice(price);
      await instance.sendTransaction({ from: renter, value: renterDeposit });
      const renterReceipt = await instance.renewContract(duration, { from: renter });
      const change = renterReceipt.logs[0].args._change;

      assert.equal(renterReceipt.logs[0].event, "changeSend", "Event should be triggered");
      assert.equal(change, renterDeposit - price, "Change is not correct");
    })

    it("Should send rent payment to owner", async () => {
      const renter = accounts[1];
      await instance.setPrice(price);
      await instance.sendTransaction({ from: accounts[1], value: price });
      const ownerReceipt = await instance.renewContract(duration, { from: renter });
      const payment = ownerReceipt.logs[0].args.payment;

      assert.equal(ownerReceipt.logs[0].event, "rentPayment", "Event should be triggered");
      assert.equal(payment, price, "Payment is not correct");
    })
  })
})
