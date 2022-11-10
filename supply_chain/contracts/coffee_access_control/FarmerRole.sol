pragma solidity >=0.7.0 <0.9.0;

// Import the library 'Roles'
import "./Roles.sol";
import "./ContractOwner.sol";

// Define a contract 'FarmerRole' to manage this role - add, remove, check
contract FarmerRole is ContractOwner {
  using Roles for Roles.Role;

  // Define 2 events, one for Adding, and other for Removing
  event FarmerAdded(address indexed account);
  event FarmerRemoved(address indexed account);

  // Define a struct 'farmers' by inheriting from 'Roles' library, struct Role
  Roles.Role private farmers;

  // Define a modifier that checks to see if msg.sender has the appropriate role
  modifier onlyFarmer() {
    require(isFarmer(msg.sender));
    _;
  }

  // Define a function 'isFarmer' to check this role
  function isFarmer(address account) public view returns (bool) {
    return farmers.has(account);
  }

  // Define a function 'addFarmer' that adds this role
  // In my opinion it is ridiculous that other farmers can add a new farmer
  // Permissions should be granted by trusted party at each level 
  // such as local administration for farmers, international board for regulators etc 
  // Here I adjust it so that only owner of the contract can add new farmers 
  function addFarmer(address account) public onlyContractOwner {
    _addFarmer(account);
  }

  // Define a function 'renounceFarmer' to renounce this role
  function renounceFarmer() public {
    _removeFarmer(msg.sender);
  }

  // Define an internal function '_addFarmer' to add this role, called by 'addFarmer'
  function _addFarmer(address account) internal {
    farmers.add(account);
    emit FarmerAdded(account);
  }

  // Define an internal function '_removeFarmer' to remove this role, called by 'removeFarmer'
  function _removeFarmer(address account) internal {
    farmers.remove(account);
    emit FarmerRemoved(account);
  }
}