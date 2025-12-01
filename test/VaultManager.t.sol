// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {VaultManager} from "../src/VaultManager.sol";

contract VaultManagerTest is Test {
    VaultManager public vaultManager;
    
    address public user1;
    address public user2;
    address public user3;
    
    // Events to test
    event VaultAdded(uint256 indexed vaultId, address indexed owner);
    event VaultDeposit(uint256 indexed vaultId, address indexed owner, uint256 amount);
    event VaultWithdraw(uint256 indexed vaultId, address indexed owner, uint256 amount);
    
    function setUp() public {
        vaultManager = new VaultManager();
        
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        
        // Fund test users with ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
    }
    
    // --- addVault Tests ---
    
    function test_AddVault() public {
        vm.startPrank(user1);
        
        vm.expectEmit(true, true, false, false);
        emit VaultAdded(0, user1);
        
        uint256 vaultId = vaultManager.addVault();
        
        assertEq(vaultId, 0, "First vault ID should be 0");
        assertEq(vaultManager.getVaultsLength(), 1, "Should have 1 vault");
        
        (address owner, uint256 balance) = vaultManager.getVault(0);
        assertEq(owner, user1, "Owner should be user1");
        assertEq(balance, 0, "Initial balance should be 0");
        
        vm.stopPrank();
    }
    
    function test_AddMultipleVaults() public {
        vm.startPrank(user1);
        
        uint256 vaultId1 = vaultManager.addVault();
        uint256 vaultId2 = vaultManager.addVault();
        uint256 vaultId3 = vaultManager.addVault();
        
        assertEq(vaultId1, 0, "First vault ID should be 0");
        assertEq(vaultId2, 1, "Second vault ID should be 1");
        assertEq(vaultId3, 2, "Third vault ID should be 2");
        assertEq(vaultManager.getVaultsLength(), 3, "Should have 3 vaults");
        
        vm.stopPrank();
    }
    
    function test_AddVaultsByDifferentUsers() public {
        vm.prank(user1);
        uint256 vaultId1 = vaultManager.addVault();
        
        vm.prank(user2);
        uint256 vaultId2 = vaultManager.addVault();
        
        vm.prank(user3);
        uint256 vaultId3 = vaultManager.addVault();
        
        assertEq(vaultId1, 0);
        assertEq(vaultId2, 1);
        assertEq(vaultId3, 2);
        assertEq(vaultManager.getVaultsLength(), 3);
        
        (address owner1, ) = vaultManager.getVault(0);
        (address owner2, ) = vaultManager.getVault(1);
        (address owner3, ) = vaultManager.getVault(2);
        
        assertEq(owner1, user1);
        assertEq(owner2, user2);
        assertEq(owner3, user3);
    }
    
    // --- deposit Tests ---
    
    function test_Deposit() public {
        vm.startPrank(user1);
        
        uint256 vaultId = vaultManager.addVault();
        
        vm.expectEmit(true, true, false, true);
        emit VaultDeposit(vaultId, user1, 10 ether);
        
        vaultManager.deposit{value: 10 ether}(vaultId);
        
        (, uint256 balance) = vaultManager.getVault(vaultId);
        assertEq(balance, 10 ether, "Balance should be 10 ether");
        
        vm.stopPrank();
    }
    
    function test_DepositMultipleTimes() public {
        vm.startPrank(user1);
        
        uint256 vaultId = vaultManager.addVault();
        
        vaultManager.deposit{value: 5 ether}(vaultId);
        vaultManager.deposit{value: 3 ether}(vaultId);
        vaultManager.deposit{value: 2 ether}(vaultId);
        
        (, uint256 balance) = vaultManager.getVault(vaultId);
        assertEq(balance, 10 ether, "Balance should be 10 ether");
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_DepositZero() public {
        vm.startPrank(user1);
        
        uint256 vaultId = vaultManager.addVault();
        
        vm.expectRevert("No ETH sent");
        vaultManager.deposit{value: 0}(vaultId);
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_DepositToNonExistentVault() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Vault does not exist");
        vaultManager.deposit{value: 1 ether}(999);
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_DepositToOthersVault() public {
        vm.prank(user1);
        uint256 vaultId = vaultManager.addVault();
        
        vm.startPrank(user2);
        
        vm.expectRevert("Not vault owner");
        vaultManager.deposit{value: 1 ether}(vaultId);
        
        vm.stopPrank();
    }
    
    // --- withdraw Tests ---
    
    function test_Withdraw() public {
        vm.startPrank(user1);
        
        uint256 vaultId = vaultManager.addVault();
        vaultManager.deposit{value: 10 ether}(vaultId);
        
        uint256 balanceBefore = user1.balance;
        
        vm.expectEmit(true, true, false, true);
        emit VaultWithdraw(vaultId, user1, 5 ether);
        
        vaultManager.withdraw(vaultId, 5 ether);
        
        uint256 balanceAfter = user1.balance;
        (, uint256 vaultBalance) = vaultManager.getVault(vaultId);
        
        assertEq(vaultBalance, 5 ether, "Vault balance should be 5 ether");
        assertEq(balanceAfter - balanceBefore, 5 ether, "User should receive 5 ether");
        
        vm.stopPrank();
    }
    
    function test_WithdrawAll() public {
        vm.startPrank(user1);
        
        uint256 vaultId = vaultManager.addVault();
        vaultManager.deposit{value: 10 ether}(vaultId);
        
        vaultManager.withdraw(vaultId, 10 ether);
        
        (, uint256 vaultBalance) = vaultManager.getVault(vaultId);
        assertEq(vaultBalance, 0, "Vault balance should be 0");
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_WithdrawZero() public {
        vm.startPrank(user1);
        
        uint256 vaultId = vaultManager.addVault();
        vaultManager.deposit{value: 10 ether}(vaultId);
        
        vm.expectRevert("Amount must be > 0");
        vaultManager.withdraw(vaultId, 0);
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_WithdrawMoreThanBalance() public {
        vm.startPrank(user1);
        
        uint256 vaultId = vaultManager.addVault();
        vaultManager.deposit{value: 10 ether}(vaultId);
        
        vm.expectRevert("Insufficient vault balance");
        vaultManager.withdraw(vaultId, 11 ether);
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_WithdrawFromEmptyVault() public {
        vm.startPrank(user1);
        
        uint256 vaultId = vaultManager.addVault();
        
        vm.expectRevert("Insufficient vault balance");
        vaultManager.withdraw(vaultId, 1 ether);
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_WithdrawFromNonExistentVault() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Vault does not exist");
        vaultManager.withdraw(999, 1 ether);
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_WithdrawFromOthersVault() public {
        vm.prank(user1);
        uint256 vaultId = vaultManager.addVault();
        
        vm.prank(user1);
        vaultManager.deposit{value: 10 ether}(vaultId);
        
        vm.startPrank(user2);
        
        vm.expectRevert("Not vault owner");
        vaultManager.withdraw(vaultId, 5 ether);
        
        vm.stopPrank();
    }
    
    // --- getVault Tests ---
    
    function test_GetVault() public {
        vm.prank(user1);
        uint256 vaultId = vaultManager.addVault();
        
        vm.prank(user1);
        vaultManager.deposit{value: 5 ether}(vaultId);
        
        (address owner, uint256 balance) = vaultManager.getVault(vaultId);
        
        assertEq(owner, user1);
        assertEq(balance, 5 ether);
    }
    
    function test_RevertWhen_GetNonExistentVault() public {
        vm.expectRevert("Vault does not exist");
        vaultManager.getVault(999);
    }
    
    // --- getMyVaults Tests ---
    
    function test_GetMyVaults() public {
        vm.startPrank(user1);
        
        uint256 vaultId1 = vaultManager.addVault();
        uint256 vaultId2 = vaultManager.addVault();
        uint256 vaultId3 = vaultManager.addVault();
        
        uint256[] memory myVaults = vaultManager.getMyVaults();
        
        assertEq(myVaults.length, 3);
        assertEq(myVaults[0], vaultId1);
        assertEq(myVaults[1], vaultId2);
        assertEq(myVaults[2], vaultId3);
        
        vm.stopPrank();
    }
    
    function test_GetMyVaults_WhenNoVaults() public {
        vm.prank(user1);
        uint256[] memory myVaults = vaultManager.getMyVaults();
        
        assertEq(myVaults.length, 0);
    }
    
    function test_GetMyVaults_IsolatedPerUser() public {
        vm.prank(user1);
        vaultManager.addVault();
        
        vm.prank(user2);
        vaultManager.addVault();
        
        vm.prank(user1);
        vaultManager.addVault();
        
        vm.prank(user1);
        uint256[] memory user1Vaults = vaultManager.getMyVaults();
        
        vm.prank(user2);
        uint256[] memory user2Vaults = vaultManager.getMyVaults();
        
        assertEq(user1Vaults.length, 2);
        assertEq(user1Vaults[0], 0);
        assertEq(user1Vaults[1], 2);
        
        assertEq(user2Vaults.length, 1);
        assertEq(user2Vaults[0], 1);
    }
    
    // --- getVaultsLength Tests ---
    
    function test_GetVaultsLength() public {
        assertEq(vaultManager.getVaultsLength(), 0);
        
        vm.prank(user1);
        vaultManager.addVault();
        assertEq(vaultManager.getVaultsLength(), 1);
        
        vm.prank(user2);
        vaultManager.addVault();
        assertEq(vaultManager.getVaultsLength(), 2);
        
        vm.prank(user1);
        vaultManager.addVault();
        assertEq(vaultManager.getVaultsLength(), 3);
    }
    
    // --- Integration Tests ---
    
    function test_CompleteVaultLifecycle() public {
        vm.startPrank(user1);
        
        // Create vault
        uint256 vaultId = vaultManager.addVault();
        assertEq(vaultId, 0);
        
        // Deposit
        vaultManager.deposit{value: 20 ether}(vaultId);
        (, uint256 balance1) = vaultManager.getVault(vaultId);
        assertEq(balance1, 20 ether);
        
        // Deposit more
        vaultManager.deposit{value: 10 ether}(vaultId);
        (, uint256 balance2) = vaultManager.getVault(vaultId);
        assertEq(balance2, 30 ether);
        
        // Partial withdrawal
        vaultManager.withdraw(vaultId, 15 ether);
        (, uint256 balance3) = vaultManager.getVault(vaultId);
        assertEq(balance3, 15 ether);
        
        // Withdraw all
        vaultManager.withdraw(vaultId, 15 ether);
        (, uint256 balance4) = vaultManager.getVault(vaultId);
        assertEq(balance4, 0);
        
        vm.stopPrank();
    }
    
    function test_MultipleUsersMultipleVaults() public {
        // User1 creates 2 vaults
        vm.startPrank(user1);
        uint256 user1Vault1 = vaultManager.addVault();
        uint256 user1Vault2 = vaultManager.addVault();
        vaultManager.deposit{value: 10 ether}(user1Vault1);
        vaultManager.deposit{value: 20 ether}(user1Vault2);
        vm.stopPrank();
        
        // User2 creates 1 vault
        vm.startPrank(user2);
        uint256 user2Vault1 = vaultManager.addVault();
        vaultManager.deposit{value: 15 ether}(user2Vault1);
        vm.stopPrank();
        
        // Verify isolation
        assertEq(user1Vault1, 0);
        assertEq(user1Vault2, 1);
        assertEq(user2Vault1, 2);
        
        // Verify balances
        (, uint256 balance1) = vaultManager.getVault(user1Vault1);
        (, uint256 balance2) = vaultManager.getVault(user1Vault2);
        (, uint256 balance3) = vaultManager.getVault(user2Vault1);
        
        assertEq(balance1, 10 ether);
        assertEq(balance2, 20 ether);
        assertEq(balance3, 15 ether);
        
        // Verify getMyVaults
        vm.prank(user1);
        uint256[] memory user1Vaults = vaultManager.getMyVaults();
        assertEq(user1Vaults.length, 2);
        
        vm.prank(user2);
        uint256[] memory user2Vaults = vaultManager.getMyVaults();
        assertEq(user2Vaults.length, 1);
    }
    
    // --- Fuzz Tests ---
    
    function testFuzz_Deposit(uint96 amount) public {
        vm.assume(amount > 0);
        
        vm.startPrank(user1);
        vm.deal(user1, amount);
        
        uint256 vaultId = vaultManager.addVault();
        vaultManager.deposit{value: amount}(vaultId);
        
        (, uint256 balance) = vaultManager.getVault(vaultId);
        assertEq(balance, amount);
        
        vm.stopPrank();
    }
    
    function testFuzz_WithdrawAfterDeposit(uint96 depositAmount, uint96 withdrawAmount) public {
        vm.assume(depositAmount > 0);
        vm.assume(withdrawAmount > 0);
        vm.assume(withdrawAmount <= depositAmount);
        
        vm.startPrank(user1);
        vm.deal(user1, depositAmount);
        
        uint256 vaultId = vaultManager.addVault();
        vaultManager.deposit{value: depositAmount}(vaultId);
        vaultManager.withdraw(vaultId, withdrawAmount);
        
        (, uint256 balance) = vaultManager.getVault(vaultId);
        assertEq(balance, depositAmount - withdrawAmount);
        
        vm.stopPrank();
    }
    
    function testFuzz_AddMultipleVaults(uint8 numVaults) public {
        vm.assume(numVaults > 0 && numVaults <= 50); // Reasonable limit
        
        vm.startPrank(user1);
        
        for (uint256 i = 0; i < numVaults; i++) {
            uint256 vaultId = vaultManager.addVault();
            assertEq(vaultId, i);
        }
        
        assertEq(vaultManager.getVaultsLength(), numVaults);
        
        uint256[] memory myVaults = vaultManager.getMyVaults();
        assertEq(myVaults.length, numVaults);
        
        vm.stopPrank();
    }
}
