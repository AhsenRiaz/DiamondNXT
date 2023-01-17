import { expect, assert } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ERC1155Asset } from "../typechain-types";
import { Token, Tokens } from "./utils";

describe("Marketplace Contract", () => {
  let erc1155Contract: ERC1155Asset;

  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;

  let token1: Token;
  let token2: Token;

  let batchTokens: Tokens;

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

    erc1155Contract = await erc1155_factory.deploy(
      "RoboCop",
      "RC",
      owner.address
    );
  });

  // ----------------------------

  describe("Verify Deployment", () => {
    it("should expect the deployment address of erc1155 contract", async () => {
      assert(erc1155Contract);
    });
  });

  // ----------------------------

  describe("ERC1155 Contract ", () => {
    it("Should deploy contract with correct details", async () => {
      expect(await erc1155Contract.name()).to.equal("RoboCop");
      expect(await erc1155Contract.symbol()).to.equal("RC");
      expect(await erc1155Contract.owner()).to.equal(owner.address);
      expect(await erc1155Contract.totalMinted()).to.equal(0);
    });
  });

  // ----------------------------

  describe("ERC1155 Minting", () => {
    token1 = {
      to: "",
      tokenId: 5,
      amount: 10,
      metadataUri: `ipfs://token-5`,
    };

    it("Should mint token with id 5 for amount 10", async () => {
      token1.to = owner.address;

      expect(await erc1155Contract.exists(token1.tokenId)).to.be.false;

      await erc1155Contract
        .connect(owner)
        .mint(token1.to, token1.tokenId, token1.amount, token1.metadataUri);

      expect(await erc1155Contract.exists(token1.tokenId)).to.be.true;
      expect(await erc1155Contract.totalMinted()).to.equal("1");
      expect(await erc1155Contract.totalSupply(token1.tokenId)).to.equal(
        token1.amount
      );
      expect(await erc1155Contract.minterOf(token1.tokenId)).to.equal(
        owner.address
      );
      expect(await erc1155Contract.uri(token1.tokenId)).to.equal(
        token1.metadataUri
      );
      expect(
        await erc1155Contract.balanceOf(owner.address, token1.tokenId)
      ).to.equal(token1.amount);
    });

    it("Should allow collaborator to mint token", async () => {
      token2 = { ...token1 };

      token2.tokenId = 52;
      token2.metadataUri = `ipfs://token-52`;
      token2.amount = 5;
      token2.to = addr2.address;

      expect(await erc1155Contract.exists(token2.tokenId)).to.be.false;

      await expect(
        erc1155Contract
          .connect(addr2)
          .mint(token2.to, token2.tokenId, token2.amount, token2.metadataUri)
      ).to.be.revertedWith(
        "OwnableAndCollab: caller is not the owner or a collaborator"
      );

      expect(
        erc1155Contract.connect(addr2).setCollaborator(addr2.address, true)
      ).to.be.revertedWith("OwnableAndCollab: caller is not the owner");

      await erc1155Contract.connect(owner).setCollaborator(addr2.address, true);

      await erc1155Contract
        .connect(addr2)
        .mint(token2.to, token2.tokenId, token2.amount, token2.metadataUri);

      expect(await erc1155Contract.totalSupply(token2.tokenId)).to.equal(
        token2.amount
      );
      expect(await erc1155Contract.minterOf(token2.tokenId)).to.equal(
        token2.to
      );
      expect(await erc1155Contract.uri(token2.tokenId)).to.equal(
        token2.metadataUri
      );
      expect(await erc1155Contract.totalMinted()).to.equal(1);
    });
  });

  // ----------------------------

  describe("ERC1155 Batch Minting", () => {
    batchTokens = {
      to: "",
      tokenIds: [1, 2, 3],
      amounts: [5, 10, 15],
      metadataUris: ["ipfs://token-1", "ipfs://token-2", "ipfs://token-3"],
    };

    it("Should mint batch tokens", async () => {
      batchTokens.to = owner.address;

      await erc1155Contract
        .connect(owner)
        .mintBatch(
          batchTokens.to,
          batchTokens.tokenIds,
          batchTokens.amounts,
          batchTokens.metadataUris
        );

      expect(await erc1155Contract.totalMinted()).to.eq(
        batchTokens.tokenIds.length
      );

      for (var i = 0; i < batchTokens.tokenIds.length; i++) {
        expect(await erc1155Contract.exists(batchTokens.tokenIds[i])).to.be
          .true;
        expect(await erc1155Contract.totalMinted()).to.equal("3");
        expect(
          await erc1155Contract.totalSupply(batchTokens.tokenIds[i])
        ).to.equal(batchTokens.amounts[i]);
        expect(
          await erc1155Contract.minterOf(batchTokens.tokenIds[i])
        ).to.equal(owner.address);
        expect(await erc1155Contract.uri(batchTokens.tokenIds[i])).to.equal(
          batchTokens.metadataUris[i]
        );
        expect(
          await erc1155Contract.balanceOf(
            owner.address,
            batchTokens.tokenIds[i]
          )
        ).to.equal(batchTokens.amounts[i]);
      }
    });
  });
});
