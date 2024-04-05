const RentContract = artifacts.require("RentContract");

contract("RentContract", accounts => {
  before(async () => {
    const instance = await RentContract.new();
  })

  describe("When start contract", () => {
    
    it("The rent price should be price set in setPrice function ", async () => {
      const instance = await RentContract.new();
      const price = 1000000000000000;
      
      await instance.setPrice(price);
      const rentPrice = await instance.rentPrice.call()

      assert.equal(price, rentPrice, "The rent price is not correct");
      
    })

    it("Contract duration must be greater than 0", async () => {
      const instance = await RentContract.new();
      const duration = 84600;
      
      await instance.startContract(duration);
      const contractDuration = await instance.contractDuration.call()

      assert.ok(contractDuration > 0, "contract duration must be greater than 2");
    })

    it("Should send change to renter", async() => {
      const instance = await RentContract.new();
      const renter = accounts[1];
      const price = "1000000000000000000";
      const renterDeposit = "2000000000000000000"

      await instance.setPrice(price);
      await instance.sendTransaction({from: renter, value: renterDeposit});
      
      const renterReceipt = await instance.startContract(84600);
      const change = renterReceipt.logs[0].args._change;

      assert.equal(renterReceipt.logs[0].event, "changeSend", "Event should be triggered");
      assert.equal(change, renterDeposit - price, "Change is not correct");
    })

    it("Should send rent payment to owner", async () => {
      const instance = await RentContract.new();
      const price = "1000000000000000000";

      await instance.setPrice(price);
      await instance.sendTransaction({from: accounts[1], value: price});
      
      const ownerReceipt = await instance.startContract(84600);
      const payment = ownerReceipt.logs[0].args.payment;

      assert.equal(ownerReceipt.logs[0].event, "rentPayment", "Event should be triggered");
      assert.equal(payment, price, "Payment is not correct");
    })
  })

  describe("When renew contract", () => {
    it ("The renovation must be greater than 0", async () => {
      const instance = await RentContract.new();
      const renter = accounts[1];
      const price = "1000000000000000000";
      const renterDeposit = "1000000000000000000"

      await instance.setPrice(price);
      await instance.sendTransaction({from: renter, value: renterDeposit});
      await instance.startContract(1);
      await instance.sendTransaction({from: renter, value: renterDeposit});
      await instance.renewContract(86400, {from:renter});
      
      const renovation = await instance.renovation.call()

      assert.ok(renovation > 0, "The renovation is not correct");
    })

    it("Should send change to renter", async() => {
      const instance = await RentContract.new();
      const renter = accounts[1];
      const price = "1000000000000000000";
      const renterDeposit = "2000000000000000000"

      await instance.setPrice(price);
      await instance.sendTransaction({from: renter, value: renterDeposit});
      await instance.startContract(86400);
      await instance.setPrice(price);
      await instance.sendTransaction({from: renter, value: renterDeposit});
      
      const renterReceipt = await instance.renewContract(84600, {from:renter});
      const change = renterReceipt.logs[0].args._change;

      assert.equal(renterReceipt.logs[0].event, "changeSend", "Event should be triggered");
      assert.equal(change, renterDeposit - price, "Change is not correct");
    })

    it("Should send rent payment to owner", async () => {
      const instance = await RentContract.new();
      const price = "1000000000000000000";
      const renter = accounts[1];

      await instance.setPrice(price);
      await instance.sendTransaction({from: accounts[1], value: price});
      await instance.startContract(86400);
      await instance.setPrice(price);
      await instance.sendTransaction({from: accounts[1], value: price});
      
      const ownerReceipt = await instance.renewContract(84600, {from:renter});
      const payment = ownerReceipt.logs[0].args.payment;

      assert.equal(ownerReceipt.logs[0].event, "rentPayment", "Event should be triggered");
      assert.equal(payment, price, "Payment is not correct");
    })
  })
})
