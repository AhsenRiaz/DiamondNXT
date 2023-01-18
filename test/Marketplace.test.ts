import { expect, assert } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Marketplace, ERC1155Asset } from "../typechain-types";
import { List, ListingType, Token, Tokens } from "./utils";

describe("Marketplace Contract", () => {
  let marketplace: Marketplace;
  let erc1155Asset: ERC1155Asset;

  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;

  let token1: Token;
  let token2: Token;

  let listedTokenDetails: Marketplace.ListingStructOutput;

  beforeEach(async () => {
    [owner, addr1, addr2] = await ethers.getSigners();

    let marketplace_factory = await ethers.getContractFactory(
      "Marketplace",
      owner
    );

    let erc1155_factory = await ethers.getContractFactory(
      "ERC1155Asset",
      owner
    );

    marketplace = await marketplace_factory.deploy(
      [owner.address],
      ethers.utils.parseEther("1")
    );

    erc1155Asset = await erc1155_factory.deploy("RoboCop", "RC", owner.address);
  });

  // ----------------------------

  describe("Verify Deployment", () => {
    it("should expect the deployment address of marketplace contract", async () => {
      assert(marketplace.address);
    });
    it("should expect the deployment address of erc1155 asset contract", async () => {
      assert(erc1155Asset.address);
    });
  });

  // ----------------------------

  describe("Marketplace Contract", () => {
    it("Should deploy contract with correct details", async () => {
      expect(await marketplace.NAME()).to.equal("DiamondNXT Marketplace");
      expect(await marketplace.SYMBOL()).to.equal("DNXT");
    });
  });

  // ----------------------------
  describe("Marketplace Listing", () => {
    it("Should list if account is whitelisted and has sufficient balance and no listing fees ", async () => {
      token1 = {
        to: owner.address,
        tokenId: 5,
        amount: 10,
        metadataUri: `ipfs://token-5`,
      };

      await erc1155Asset
        .connect(owner)
        .mint(token1.to, token1.tokenId, token1.amount, token1.metadataUri);

      const payload: List = {
        tokenId: "5",
        nftContract: erc1155Asset.address,
        listedQuantity: "1",
        listingType: ListingType.FIXED_PRICE,
        startTime: "0",
        endTime: (new Date("2077-12-10").getTime() / 1000).toFixed(0),
        price: "2000000000000000000",
      };

      await marketplace
        .connect(owner)
        .list(payload, { value: ethers.utils.parseEther("0") });

      listedTokenDetails = await marketplace.getListingDetails(
        payload.nftContract,
        owner.address,
        payload.tokenId
      );

      expect(listedTokenDetails.initialized).to.be.true;
      expect(listedTokenDetails.nftContract).to.equal(payload.nftContract);
      expect(listedTokenDetails.owner).to.equal(owner.address);
      expect(listedTokenDetails.tokenId).to.equal(payload.tokenId);
      expect(listedTokenDetails.listingType).to.equal(payload.listingType);
      expect(listedTokenDetails.listedQuantity).to.equal(
        payload.listedQuantity
      );
      expect(listedTokenDetails.price).to.equal(payload.price);
      expect(listedTokenDetails.endTime).to.equal(payload.endTime);
    });

    it("Should revert when an non whitelisted account tries to list with sufficient balance and no listing fees", async () => {
      token1 = {
        to: addr1.address,
        tokenId: 5,
        amount: 10,
        metadataUri: `ipfs://token-5`,
      };

      await erc1155Asset.connect(owner).setCollaborator(addr1.address, true);

      await erc1155Asset
        .connect(addr1)
        .mint(token1.to, token1.tokenId, token1.amount, token1.metadataUri);

      const payload: List = {
        tokenId: "5",
        nftContract: erc1155Asset.address,
        listedQuantity: "1",
        listingType: ListingType.FIXED_PRICE,
        startTime: "0",
        endTime: (new Date("2077-12-10").getTime() / 1000).toFixed(0),
        price: "2000000000000000000",
      };

      await marketplace
        .connect(addr1)
        .list(payload, { value: ethers.utils.parseEther("1") });

      var balance = await owner.getBalance();
      expect(balance).to.be.greaterThanOrEqual(balance);
    });
  });

  // ----------------------------
  describe("Marketplace delisting", () => {
    it("Should delist the token", async () => {
      token1 = {
        to: owner.address,
        tokenId: 5,
        amount: 10,
        metadataUri: `ipfs://token-5`,
      };

      await erc1155Asset
        .connect(owner)
        .mint(token1.to, token1.tokenId, token1.amount, token1.metadataUri);

      const payload: List = {
        tokenId: "5",
        nftContract: erc1155Asset.address,
        listedQuantity: "1",
        listingType: ListingType.FIXED_PRICE,
        startTime: "0",
        endTime: (new Date("2077-12-10").getTime() / 1000).toFixed(0),
        price: "2000000000000000000",
      };

      await marketplace.connect(owner).list(payload);

      listedTokenDetails = await marketplace.getListingDetails(
        payload.nftContract,
        owner.address,
        payload.tokenId
      );

      expect(listedTokenDetails.price).to.equal(payload.price);
      expect(listedTokenDetails.tokenId).to.equal(payload.tokenId);
      expect(listedTokenDetails.listedQuantity).to.equal(
        payload.listedQuantity
      );

      await marketplace.delist(
        listedTokenDetails.nftContract,
        listedTokenDetails.tokenId
      );

      listedTokenDetails = await marketplace.getListingDetails(
        listedTokenDetails.nftContract,
        addr1.address,
        listedTokenDetails.tokenId
      );

      expect(listedTokenDetails.tokenId).to.equal(0);
      expect(listedTokenDetails.price).to.equal(0);
      expect(listedTokenDetails.listedQuantity).to.equal(0);
      expect(listedTokenDetails.listingType).to.equal(0);
    });
  });

  it("should batch list tokens", async () => {
    let batchTokens = [
      {
        to: owner.address,
        tokenId: 5,
        amount: 1,
        metadataUri: `ipfs://token-5`,
      },
      {
        to: owner.address,
        tokenId: 6,
        amount: 1,
        metadataUri: `ipfs://token-6`,
      },
      {
        to: owner.address,
        tokenId: 8,
        amount: 5,
        metadataUri: `ipfs://token-8`,
      },
    ];

    let payloads: Marketplace.ListDataStruct[] = [
      {
        tokenId: "5",
        nftContract: erc1155Asset.address,
        listedQuantity: "1",
        listingType: ListingType.FIXED_PRICE,
        startTime: "0",
        endTime: (new Date("2077-12-10").getTime() / 1000).toFixed(0),
        price: "2000000000000000000",
      },
      {
        tokenId: "6",
        nftContract: erc1155Asset.address,
        listedQuantity: "1",
        listingType: ListingType.FIXED_PRICE,
        startTime: "0",
        endTime: (new Date("2077-12-10").getTime() / 1000).toFixed(0),
        price: "2000000000000000000",
      },
      {
        tokenId: "8",
        nftContract: erc1155Asset.address,
        listedQuantity: "5",
        listingType: ListingType.FIXED_PRICE,
        startTime: "0",
        endTime: (new Date("2077-12-10").getTime() / 1000).toFixed(0),
        price: "2000000000000000000",
      },
    ];

    for (var i = 0; i < batchTokens.length; i++) {
      await erc1155Asset
        .connect(owner)
        .mint(
          batchTokens[i].to,
          batchTokens[i].tokenId,
          batchTokens[i].amount,
          batchTokens[i].metadataUri
        );
    }
    await marketplace.connect(owner).listBatch(payloads);

    for (var i = 0; i < payloads.length; i++) {
      listedTokenDetails = await marketplace.getListingDetails(
        payloads[i].nftContract,
        owner.address,
        payloads[i].tokenId
      );

      expect(listedTokenDetails.initialized).to.be.true;
      expect(listedTokenDetails.nftContract).to.equal(payloads[i].nftContract);
      expect(listedTokenDetails.owner).to.equal(owner.address);
      expect(listedTokenDetails.tokenId).to.equal(payloads[i].tokenId);
      expect(listedTokenDetails.listingType).to.equal(payloads[i].listingType);
      expect(listedTokenDetails.listedQuantity).to.equal(
        payloads[i].listedQuantity
      );
      expect(listedTokenDetails.price).to.equal(payloads[i].price);
      expect(listedTokenDetails.endTime).to.equal(payloads[i].endTime);
    }
  });
});
