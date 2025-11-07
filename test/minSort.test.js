const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EvmSort - Min Sorting Tests", function () {
  let evmSort;
  let owner;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();

    // Deploy libraries
    const MaxHeap = await ethers.getContractFactory("MaxHeap");
    const maxHeap = await MaxHeap.deploy();
    await maxHeap.waitForDeployment();

    const MinHeap = await ethers.getContractFactory("MinHeap");
    const minHeap = await MinHeap.deploy();
    await minHeap.waitForDeployment();

    // Deploy contract with linked libraries
    const EvmSort = await ethers.getContractFactory("EvmSort", {
      libraries: {
        MaxHeap: await maxHeap.getAddress(),
        MinHeap: await minHeap.getAddress(),
      },
    });
    evmSort = await EvmSort.deploy();
    await evmSort.waitForDeployment();
  });

  describe("setValue - Min Set", function () {
    it("Should add a single element to min set", async function () {
      await evmSort.setValue(100, true, false);
      expect(await evmSort.hasElement(100, false)).to.equal(true);
    });

    it("Should add multiple elements to min set", async function () {
      await evmSort.setValue(100, true, false);
      await evmSort.setValue(200, true, false);
      await evmSort.setValue(300, true, false);

      expect(await evmSort.hasElement(100, false)).to.equal(true);
      expect(await evmSort.hasElement(200, false)).to.equal(true);
      expect(await evmSort.hasElement(300, false)).to.equal(true);
    });

    it("Should remove an element from min set", async function () {
      await evmSort.setValue(100, true, false);
      expect(await evmSort.hasElement(100, false)).to.equal(true);

      await evmSort.setValue(100, false, false);
      expect(await evmSort.hasElement(100, false)).to.equal(false);
    });
  });

  describe("getMin", function () {
    it("Should return 0 for empty min set", async function () {
      expect(await evmSort.getMin()).to.equal(0);
    });

    it("Should return the minimum element", async function () {
      await evmSort.setValue(100, true, false);
      await evmSort.setValue(200, true, false);
      await evmSort.setValue(300, true, false);

      expect(await evmSort.getMin()).to.equal(100);
    });

    it("Should return correct min after adding smaller element", async function () {
      await evmSort.setValue(500, true, false);
      expect(await evmSort.getMin()).to.equal(500);

      await evmSort.setValue(100, true, false);
      expect(await evmSort.getMin()).to.equal(100);
    });

    it("Should not remove element when calling getMin", async function () {
      await evmSort.setValue(100, true, false);
      await evmSort.getMin();

      expect(await evmSort.hasElement(100, false)).to.equal(true);
    });
  });

  describe("popMin", function () {
    it("Should revert when popping from empty min set", async function () {
      await expect(evmSort.popMin()).to.be.revertedWith("No elements available");
    });

    it("Should pop and return the minimum element", async function () {
      await evmSort.setValue(100, true, false);
      await evmSort.setValue(200, true, false);
      await evmSort.setValue(300, true, false);

      const minValue = await evmSort.popMin.staticCall();
      expect(minValue).to.equal(100);
    });

    it("Should remove element after popping", async function () {
      await evmSort.setValue(100, true, false);
      await evmSort.setValue(200, true, false);

      await evmSort.popMin();
      expect(await evmSort.hasElement(100, false)).to.equal(false);
      expect(await evmSort.getMin()).to.equal(200);
    });

    it("Should pop elements in ascending order", async function () {
      await evmSort.setValue(50, true, false);
      await evmSort.setValue(150, true, false);
      await evmSort.setValue(100, true, false);
      await evmSort.setValue(200, true, false);

      expect(await evmSort.popMin.staticCall()).to.equal(50);
      await evmSort.popMin();
      expect(await evmSort.popMin.staticCall()).to.equal(100);
      await evmSort.popMin();
      expect(await evmSort.popMin.staticCall()).to.equal(150);
      await evmSort.popMin();
      expect(await evmSort.popMin.staticCall()).to.equal(200);
    });

    it("Should emit MinValuePopped event", async function () {
      await evmSort.setValue(100, true, false);

      await expect(evmSort.popMin())
        .to.emit(evmSort, "MinValuePopped")
        .withArgs(100);
    });
  });

  describe("removeSpecificMin", function () {
    it("Should revert when removing non-existent element", async function () {
      await expect(evmSort.removeSpecificMin(100)).to.be.revertedWith("Element not found");
    });

    it("Should remove specific element from min set", async function () {
      await evmSort.setValue(100, true, false);
      await evmSort.setValue(200, true, false);
      await evmSort.setValue(300, true, false);

      await evmSort.removeSpecificMin(200);

      expect(await evmSort.hasElement(200, false)).to.equal(false);
      expect(await evmSort.hasElement(100, false)).to.equal(true);
      expect(await evmSort.hasElement(300, false)).to.equal(true);
    });

    it("Should update min after removing current min", async function () {
      await evmSort.setValue(100, true, false);
      await evmSort.setValue(200, true, false);
      await evmSort.setValue(300, true, false);

      await evmSort.removeSpecificMin(100);
      expect(await evmSort.getMin()).to.equal(200);
    });
  });

  describe("Edge Cases - Min Set", function () {
    it("Should handle single element", async function () {
      await evmSort.setValue(42, true, false);
      expect(await evmSort.getMin()).to.equal(42);
      expect(await evmSort.popMin.staticCall()).to.equal(42);
      await evmSort.popMin();
      expect(await evmSort.getMin()).to.equal(0);
    });

    it("Should handle large numbers", async function () {
      const largeNum = ethers.toBigInt("1000000000000");
      await evmSort.setValue(largeNum, true, false);
      expect(await evmSort.getMin()).to.equal(largeNum);
    });

    it("Should handle adding same element twice", async function () {
      await evmSort.setValue(100, true, false);
      await evmSort.setValue(100, true, false);

      expect(await evmSort.hasElement(100, false)).to.equal(true);
      await evmSort.popMin();

      // Element should be removed after one pop
      expect(await evmSort.getMin()).to.equal(0);
    });

    it("Should handle consecutive values", async function () {
      await evmSort.setValue(1, true, false);
      await evmSort.setValue(2, true, false);
      await evmSort.setValue(3, true, false);

      expect(await evmSort.getMin()).to.equal(1);
      await evmSort.popMin();
      expect(await evmSort.getMin()).to.equal(2);
    });

    it("Should handle zero value", async function () {
      await evmSort.setValue(0, true, false);
      await evmSort.setValue(100, true, false);

      expect(await evmSort.getMin()).to.equal(0);
      await evmSort.popMin();
      expect(await evmSort.getMin()).to.equal(100);
    });
  });

  describe("Min and Max Sets Independence", function () {
    it("Should keep min and max sets separate", async function () {
      await evmSort.setValue(100, true, true);  // Add to max
      await evmSort.setValue(200, true, false); // Add to min

      expect(await evmSort.hasElement(100, true)).to.equal(true);
      expect(await evmSort.hasElement(100, false)).to.equal(false);
      expect(await evmSort.hasElement(200, false)).to.equal(true);
      expect(await evmSort.hasElement(200, true)).to.equal(false);
    });

    it("Should not affect max set when modifying min set", async function () {
      await evmSort.setValue(100, true, true);
      await evmSort.setValue(100, true, false);

      await evmSort.setValue(100, false, false);

      expect(await evmSort.hasElement(100, true)).to.equal(true);
      expect(await evmSort.hasElement(100, false)).to.equal(false);
    });
  });
});
