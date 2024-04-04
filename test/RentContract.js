const RentContract = artifacts.require("RentContract");

contract("RentContract", accounts => {
  before(async () => {
    instance = await RentContract.new({ from: accounts[0] })
  });

  describe("When start contract", () => {
    
    it("Only the owner should set the rental price", async () => {
      instance = await RentContract.new({ from: accounts[0] });
      const owner = accounts[0];
      const price = 1000000000000000;
      await instance.setPrice(price, {from:accounts[0]});
      assert.equal(owner, accounts[0], "only owner can call this function");
      
    })

    it("only owner can call this function", async () => {
      instance = await RentContract.new({ from: accounts[0] });
      const owner = accounts[0];
      await instance.startContract(84600, { from: accounts[0] });
      assert.equal(owner, accounts[0], "only owner should call this function");
    })

    it("Contract duration must be greater than 0", async () => {
      instance = await RentContract.new({ from: accounts[0] });
      const duration = 84600;
      const owner = accounts[0];
      await instance.startContract(duration);

      assert(duration > 0, "contract duration must be greater than 2");
    })

    it("Should send change to renter", async() => {
      instance = await RentContract.new({from: accounts[0]});
      
      const renter = accounts[1];
      const price = "1000000000000000000";
      const renterDeposit = "2000000000000000000"

      await instance.setPrice(price);
      await instance.sendTransaction({from: accounts[1], value: renterDeposit});
      
      const renterReceipt = await instance.startContract(84600);
      const change = renterReceipt.logs[0].args._change;

      assert.equal(renterReceipt.logs[0].event, "changeSend", "Event should be triggered");
      assert.equal(change, renterDeposit - price, "Change is not correct");
    })

    it("Should send rent payment to owner", async () => {
      instance = await RentContract.new({from: accounts[0]});

      const price = "10000000000000000000";

      await instance.setPrice(price, {from: accounts[0]});
      await instance.sendTransaction({from: accounts[1], value: price});
      
      const ownerReceipt = await instance.startContract(84600);
      const payment = ownerReceipt.logs[0].args.payment;

      assert.equal(ownerReceipt.logs[0].event, "rentPayment", "Event should be triggered");
      assert.equal(payment, price, "Payment is not correct");
    })
  })
})
