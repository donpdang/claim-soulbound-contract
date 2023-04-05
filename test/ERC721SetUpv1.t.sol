// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC721ClaimSoulbound.sol";
import {Utils} from "./utils/Utils.sol";
import {ERC721Creator} from "@manifoldxyz/creator-core-solidity-v1/contracts/ERC721Creator.sol";

contract ERC721SetUp is Test{
  Utils internal utils;
  address payable[] internal users;
  ERC721ClaimSoulbound public lazyClaim;
  address internal owner;
  address internal creator;
  address internal minter;
  address internal minter2;
  ERC721Creator public creatorContract;
  uint256 public constant cost = 1e17;

    function setUp() public {
      utils = new Utils();
      users = utils.createUsers(4);
      owner = 0xCD56df7B4705A99eBEBE2216e350638a1582bEC4;
      vm.label(owner, "Owner");
      creator = users[1];
      vm.label(creator, "Creator");
      minter = users[2];
      vm.label(minter, "Minter");
      minter2 = users[3];
      vm.label(minter2, "Minter 2");

      // dev deploy the clip extension contract
      vm.startPrank(owner);
      lazyClaim = new ERC721ClaimSoulbound(0x00000000000076A84feF008CDAbe6409d2FE638B);
      vm.stopPrank();

      // creator deploying the creator contract
      vm.startPrank(creator);
      creatorContract = new ERC721Creator("test","TEST");
      creatorContract.registerExtension(address(lazyClaim), "");
      lazyClaim.setApproveTransfer(address(creatorContract), true);
      vm.stopPrank();
  }

  function mockClaim() public view returns (IERC721ClaimSoulbound.ClaimParameters memory) {
    return IERC721ClaimSoulbound.ClaimParameters( {
      merkleRoot: bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
      location: "arweaveHash2",
      totalMax: 0,
      walletMax: 0,
      startDate: 0,
      endDate: 0,
      storageProtocol: IERC721ClaimSoulbound.StorageProtocol.ARWEAVE,
      cost: cost,
      paymentReceiver: payable(creator),
      identical: true
    }); 
  }

  function initalizeWithMockClaim() public {
    vm.startPrank(creator);
    IERC721ClaimSoulbound.ClaimParameters memory claimParameters = this.mockClaim();
    // initialize claim
    lazyClaim.initializeClaim(address(creatorContract), 1 ,claimParameters);
    vm.stopPrank();
  }

}