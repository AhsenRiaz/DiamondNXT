import { expect, assert } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Marketplace, ERC1155Asset } from "../typechain-types";

describe("Marketplace Contract", () => {
  let marketplace: Marketplace;
  let erc1155Contract: ERC1155Asset;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;

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

    marketplace = await marketplace_factory.deploy();

    erc1155Contract = await erc1155_factory.deploy(
      "Robocop",
      "RC",
      owner.address
    );
  });

  describe("Verify Deployment", () => {
    it("should expect the deployment address of marketplace contract", async () => {
      assert(marketplace);
    });

    it("should expect the deployment address of erc1155 contract", async () => {
      assert(erc1155Contract);
    });
  });
});
