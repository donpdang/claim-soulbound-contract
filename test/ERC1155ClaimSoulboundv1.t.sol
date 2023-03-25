// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC1155ClaimSoulbound.sol";
import {Utils} from "./utils/Utils.sol";
import "./ERC1155SetUpv1.t.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract ERC1155ClaimSoulboundTest is Test, ERC1155SetUp {
    uint256 private constant DEV_FEE = 0.00069 ether;

    function testTippingMint() public {
        this.initalizeWithMockClaim();
        bytes32[] memory merkleProof = new bytes32[](1);
        uint beforeBalanceCreator = creator.balance;
        uint beforeBalanceContract = address(lazyClaim).balance;
        vm.startPrank(minter);
        // no tip
        lazyClaim.mint{value: 1e17 + DEV_FEE}(address(creatorContract), 1, 0, merkleProof, address(minter));
        // transfer full amount to the creator wallet
        uint afterBalanceCreator = creator.balance;
        uint afterBalanceContract = address(lazyClaim).balance;
        assertEq(1e17, afterBalanceCreator - beforeBalanceCreator);
        // transfer DEV_FEE to the dev wallet
        assertEq(DEV_FEE, afterBalanceContract - beforeBalanceContract);

        beforeBalanceCreator = creator.balance;
        beforeBalanceContract = address(lazyClaim).balance;
        // with tip
        lazyClaim.mint{value: 2e17}(address(creatorContract), 1, 0, merkleProof, address(minter));
        afterBalanceCreator = creator.balance;
        afterBalanceContract = address(lazyClaim).balance;
        assertEq(2e17 - DEV_FEE, afterBalanceCreator - beforeBalanceCreator);
        assertEq(DEV_FEE, afterBalanceContract - beforeBalanceContract);
        vm.stopPrank();
    }

    function testTippingMintBatch() public {
        this.initalizeWithMockClaim();

        uint beforeBalanceCreator = creator.balance;
        uint beforeBalanceContract = address(lazyClaim).balance;
        vm.startPrank(minter);
        // able to pay the right price
        uint32[] memory randomArray = new uint32[](1);
        bytes32[][] memory anotherRandomArray = new bytes32[][](1);
        // no tip
        lazyClaim.mintBatch{value: 2e17 + DEV_FEE*2}(address(creatorContract), 1, 2, randomArray, anotherRandomArray, address(minter));
        // transfer full amount to the creator wallet
        uint afterBalanceCreator = creator.balance;
        uint afterBalanceContract = address(lazyClaim).balance;
        assertEq(2e17, afterBalanceCreator - beforeBalanceCreator);
         // transfer DEV_FEE to the dev wallet
        assertEq(DEV_FEE * 2, afterBalanceContract - beforeBalanceContract);
        beforeBalanceCreator = creator.balance;
        beforeBalanceContract = address(lazyClaim).balance;
        // with tip
        lazyClaim.mintBatch{value: 3e17}(address(creatorContract), 1, 2, randomArray, anotherRandomArray, address(minter));
        afterBalanceCreator = creator.balance;
        afterBalanceContract = address(lazyClaim).balance;
        assertEq(3e17 - DEV_FEE * 2, afterBalanceCreator - beforeBalanceCreator);
        assertEq(DEV_FEE * 2, afterBalanceContract - beforeBalanceContract);
        vm.stopPrank();
    }


    function testNotEnoughEthMintBatch() public {
        this.initalizeWithMockClaim();
        vm.stopPrank();
        vm.startPrank(minter);
        // able to pay the right price
        uint32[] memory randomArray = new uint32[](1);
        bytes32[][] memory anotherRandomArray = new bytes32[][](1);
        vm.expectRevert('Must pay more.');
        lazyClaim.mintBatch{value: 2e17}(address(creatorContract), 1, 2, randomArray, anotherRandomArray, address(minter));
        vm.stopPrank();
    }

    function testNotEnoughEthMint() public {
        this.initalizeWithMockClaim();

        bytes32[] memory merkleProof = new bytes32[](1);
        vm.startPrank(minter);
        vm.expectRevert('Must pay more.');
        // able to pay the right price
        lazyClaim.mint{value: 1e17}(address(creatorContract), 1, 0, merkleProof, address(minter));
        vm.stopPrank();
    }

    function testWithdraw() public {
        // test if the owner of the extension will receive the fund
        this.initalizeWithMockClaim();

        bytes32[] memory merkleProof = new bytes32[](1);

        vm.startPrank(minter);
        uint beforeBalanceCreator = creator.balance;
        uint beforeBalanceContract = address(lazyClaim).balance;
        // able to pay more
        lazyClaim.mint{value: 2e17}(address(creatorContract), 1, 0, merkleProof, address(minter));
        uint afterBalanceCreator = creator.balance;
        uint afterBalanceContract = address(lazyClaim).balance;
        // transfer full price + 98% of tip amount to the creator wallet
        assertEq(2e17 - DEV_FEE, afterBalanceCreator - beforeBalanceCreator);
        assertEq(DEV_FEE, afterBalanceContract - beforeBalanceContract);
        vm.stopPrank();

        vm.startPrank(owner);      
        lazyClaim.withdraw(payable(owner), DEV_FEE);
        assertEq(DEV_FEE, owner.balance);
        vm.stopPrank();

        // mintBatch
        vm.startPrank(minter);
        uint32[] memory randomArray = new uint32[](1);
        bytes32[][] memory anotherRandomArray = new bytes32[][](1);
        lazyClaim.mintBatch{value: 2e17 + DEV_FEE*2}(address(creatorContract), 1, 2, randomArray, anotherRandomArray, address(minter));
        vm.stopPrank();
        
        uint ownerBeforeBalance = owner.balance;
        vm.startPrank(owner);      
        lazyClaim.withdraw(payable(owner), DEV_FEE*2);
        assertEq(DEV_FEE*2, owner.balance - ownerBeforeBalance);
        vm.stopPrank();
    }

    function testCannotWithdrawIfNotOwner() public {
        vm.expectRevert('AdminControl: Must be owner or admin');
        vm.startPrank(creator);
        lazyClaim.withdraw(payable(owner), DEV_FEE);
        vm.stopPrank();
        
        vm.expectRevert('AdminControl: Must be owner or admin');
        vm.startPrank(minter);
        lazyClaim.withdraw(payable(owner), DEV_FEE);
        vm.stopPrank();
    }

    function testCannotTransferToken() public {
        this.initalizeWithMockClaim();
        vm.startPrank(minter);
        bytes32[] memory merkleProof = new bytes32[](1);
        lazyClaim.mint{value: 1e17 + DEV_FEE}(address(creatorContract), 1, 0, merkleProof, address(minter));
        // should not be able to transfer minted token
        bytes memory data = new bytes(1);
        vm.expectRevert('Extension approval failure');
        creatorContract.safeTransferFrom(address(minter), address(minter2), 1, 1, data);
    }

    function testCanBurnToken() public {
        this.initalizeWithMockClaim();
        vm.startPrank(minter);
        bytes32[] memory merkleProof = new bytes32[](1);
        lazyClaim.mint{value: 1e17 + DEV_FEE}(address(creatorContract), 1, 0, merkleProof, address(minter));
        uint256[] memory tempArray = new uint256[](1);
        tempArray[0] = 1;
        creatorContract.burn(address(minter), tempArray, tempArray);
    }
}
