// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract VaultManager {
    struct Vault {
        address owner;
        uint256 balance;
    }

    // Array of all vaults
    Vault[] private vaults;

    // Mapping from owner to the list of their vault IDs
    mapping(address => uint256[]) private vaultsByOwner;

    // Events
    event VaultAdded(uint256 indexed vaultId, address indexed owner);
    event VaultDeposit(uint256 indexed vaultId, address indexed owner, uint256 amount);
    event VaultWithdraw(uint256 indexed vaultId, address indexed owner, uint256 amount);

    // --- Modifiers ---

    modifier onlyVaultOwner(uint256 _vaultId) {
        require(_vaultId < vaults.length, "Vault does not exist");
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        _;
    }

    // --- Core functions ---

    /**
     * @notice Create a new vault owned by msg.sender.
     * @return vaultId ID of the newly created vault.
     */
    function addVault() external returns (uint256 vaultId) {
        vaultId = vaults.length;

        vaults.push(
            Vault({
                owner: msg.sender,
                balance: 0
            })
        );

        vaultsByOwner[msg.sender].push(vaultId);

        emit VaultAdded(vaultId, msg.sender);
    }

    /**
     * @notice Deposit ETH into a specific vault.
     * @dev Only the owner of the vault can deposit.
     * @param _vaultId ID of the vault to deposit into.
     */
    function deposit(uint256 _vaultId) external payable onlyVaultOwner(_vaultId) {
        require(msg.value > 0, "No ETH sent");

        vaults[_vaultId].balance += msg.value;

        emit VaultDeposit(_vaultId, msg.sender, msg.value);
    }

    /**
     * @notice Withdraw ETH from a specific vault.
     * @dev Only the owner of the vault can withdraw.
     * @param _vaultId ID of the vault to withdraw from.
     * @param _amount Amount of ETH (in wei) to withdraw.
     */
    function withdraw(uint256 _vaultId, uint256 _amount) external onlyVaultOwner(_vaultId)
    {
        Vault storage v = vaults[_vaultId];

        require(_amount > 0, "Amount must be > 0");
        require(_amount <= v.balance, "Insufficient vault balance");

        v.balance -= _amount;

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "ETH transfer failed");

        emit VaultWithdraw(_vaultId, msg.sender, _amount);
    }

    /**
     * @notice Get information about a vault.
     * @param _vaultId ID of the vault.
     * @return owner Owner of the vault.
     * @return balance Current balance of the vault in wei.
     */
    function getVault(uint256 _vaultId)
        external
        view
        returns (address owner, uint256 balance)
    {
        require(_vaultId < vaults.length, "Vault does not exist");
        Vault memory v = vaults[_vaultId];
        return (v.owner, v.balance);
    }

    /**
     * @notice Get the total number of vaults created.
     */
    function getVaultsLength() external view returns (uint256) {
        return vaults.length;
    }

    /**
     * @notice Get all vault IDs owned by the caller.
     */
    function getMyVaults() external view returns (uint256[] memory) {
        return vaultsByOwner[msg.sender];
    }
    
}
