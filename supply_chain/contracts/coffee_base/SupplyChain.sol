pragma solidity >=0.7.0 <0.9.0;

import "../coffee_access_control/FarmerRole.sol";
import "../coffee_access_control/DistributorRole.sol";
import "../coffee_access_control/RetailerRole.sol";
import "../coffee_access_control/ConsumerRole.sol";

// Define a contract 'Supplychain'
contract SupplyChain is FarmerRole, DistributorRole, RetailerRole, ConsumerRole {

  // Define a variable called 'sku' for Stock Keeping Unit (SKU)
  uint sku;

  // Define a public mapping 'items' that maps the UPC to an Item.
  mapping (uint => Item) items;
  
  // Define enum 'State' with the following values:
  enum State 
  { 
    Harvested,  // 0
    Processed,  // 1
    Packed,     // 2
    ForSale,    // 3
    Sold,       // 4
    Shipped,    // 5
    Received,   // 6
    Purchased   // 7
    }


  // Define a struct 'Item' with the following fields:
  struct Item {
    uint    sku;  // Stock Keeping Unit (SKU) (sku just count how many units were created) 
    uint    upc; // UPC is unique to brand of product e.g. Nescaffe Arabica, not individual unit (https://quickbooks.intuit.com/global/resources/starting-a-business/the-difference-between-product-sku-upc-barcode/)
    address ownerID;  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
    address payable originFarmerID; // Metamask-Ethereum address of the Farmer
    string  originFarmName; // Farmer Name
    string  originFarmInformation;  // Farmer Information
    string  originFarmLatitude; // Farm Latitude
    string  originFarmLongitude;  // Farm Longitude
    uint    itemID;  // Product ID potentially a combination of upc + sku - this should be used to identify specific item, not upc
    string  productNotes; // Product Notes
    uint    productPrice; // Product Price
    State   itemState;  // Product State as represented in the enum above
    address payable distributorID;  // Metamask-Ethereum address of the Distributor
    address retailerID; // Metamask-Ethereum address of the Retailer
    address consumerID; // Metamask-Ethereum address of the Consumer
  }

  // Define 8 events with the same 8 state values and accept 'itemID' as input argument
  event Harvested(uint itemID);
  event Processed(uint itemID);
  event Packed(uint itemID);
  event ForSale(uint itemID);
  event Sold(uint itemID);
  event Shipped(uint itemID);
  event Received(uint itemID);
  event Purchased(uint itemID);

  // Define a modifer that verifies the Caller
  modifier verifyCaller (address _address) {
    require(msg.sender == _address); 
    _;
  }

  // Define a modifier that checks if the paid amount is sufficient to cover the price
  modifier paidEnough(uint _upc) {
    uint _price = items[_upc].productPrice; 
    require(msg.value >= _price); 
    _;
  }
  
  // Define a modifier that checks the price and refunds the remaining balance
  modifier checkValue(uint _upc) {
    _;
    uint _price = items[_upc].productPrice;
    uint amountToReturn = msg.value - _price;
    items[_upc].distributorID.transfer(amountToReturn);
  }

  modifier onlyItemOwner(uint _upc) {
    require(items[_upc].ownerID == msg.sender);
    _;
  }

  // Define a modifier that checks if an item.state of a itemID is Harvested
  modifier harvested(uint _upc) {
    require(items[_upc].itemState == State.Harvested);
    _;
  }

  // Define a modifier that checks if an item.state of a itemID is Processed
  modifier processed(uint _upc) {
    require(items[_upc].itemState == State.Processed);
    _;
  }
  
  // Define a modifier that checks if an item.state of a itemID is Packed
  modifier packed(uint _upc) {
    require(items[_upc].itemState == State.Packed);
    _;
  }

  // Define a modifier that checks if an item.state of a itemID is ForSale
  modifier forSale(uint _upc) {
    require(items[_upc].itemState == State.ForSale);
    _;
  }

  // Define a modifier that checks if an item.state of a itemID is Sold
  modifier sold(uint _upc) {
    require(items[_upc].itemState == State.Sold);
    _;
  }
  
  // Define a modifier that checks if an item.state of a itemID is Shipped
  modifier shipped(uint _upc) {
    require(items[_upc].itemState == State.Shipped);
    _;
  }

  // Define a modifier that checks if an item.state of a itemID is Received
  modifier received(uint _upc) {
    require(items[_upc].itemState == State.Received);
    _;
  }

  // Define a modifier that checks if an item.state of a itemID is Purchased
  modifier purchased(uint _upc) {
    require(items[_upc].itemState == State.Purchased);    
    _;
  }

  // In the constructor set 'owner' to the address that instantiated the contract
  // and set 'sku' to 1
  // and set 'upc' to 1
  constructor() public {
    sku = 1;
  }

  // Define a function 'kill' if required
  function kill() public onlyContractOwner {
      selfdestruct(payable(msg.sender));
  }

  // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
  // That's also quite dumb to provide FarmerID as it's supposed that the farmer is a msg.sender
  function harvestItem(uint _upc, string memory _originFarmName, string memory _originFarmInformation, string  memory _originFarmLatitude, string memory _originFarmLongitude, string memory _productNotes) onlyFarmer public 
  {
    require(items[_upc].upc == 0, "This item UPC has already been registered. Item overwriting is not supported.");
    
    // Add the new item as part of Harvest
    items[_upc].upc = _upc;
    items[_upc].sku = sku;
    items[_upc].ownerID = msg.sender;
    items[_upc].originFarmerID = payable(msg.sender);
    items[_upc].originFarmName = _originFarmName;
    items[_upc].originFarmInformation = _originFarmInformation;
    items[_upc].originFarmLatitude = _originFarmLatitude;
    items[_upc].originFarmLongitude = _originFarmLongitude;
    items[_upc].itemID = _upc + sku; 
    items[_upc].productNotes = _productNotes;
    items[_upc].itemState = State.Harvested;
    // Add new item to the list of items
    items[_upc] = items[_upc];
    // Increment sku because a new bushel of coffee was created 
    sku = sku + 1;
    // Emit the appropriate event
    emit Harvested(items[_upc].itemID);
  }

  // Define a function 'processtItem' that allows a farmer to mark an item 'Processed'
  function processItem(uint _upc) harvested(_upc) onlyFarmer onlyItemOwner(_upc) public 
  // Call modifier to check if upc has passed previous supply chain stage
  // Call modifier to verify caller of this function
  {
    // Update the appropriate fields
    items[_upc].itemState = State.Processed;
    
    // Emit the appropriate event
    emit Processed(_upc);
  }

  // Define a function 'packItem' that allows a farmer to mark an item 'Packed'
  function packItem(uint _upc) processed(_upc) onlyFarmer onlyItemOwner(_upc) public 
  {
    // Update the appropriate fields
    items[_upc].itemState = State.Packed;
    // Emit the appropriate event
    emit Packed(_upc);
  }

  // Define a function 'sellItem' that allows a farmer to mark an item 'ForSale'
  function sellItem(uint _upc, uint _price) packed(_upc) onlyFarmer onlyItemOwner(_upc) public 
  {
    // Update the appropriate fields
    items[_upc].itemState = State.ForSale;
    items[_upc].productPrice = _price;
    // Emit the appropriate event
    emit ForSale(_upc);
  }

  // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
  // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough, 
  // and any excess ether sent is refunded back to the buyer
  function buyItem(uint _upc) checkValue(_upc) paidEnough(_upc) forSale(_upc) onlyDistributor public payable 
    // Call modifier to check if upc has passed previous supply chain stage
    // Call modifer to check if buyer has paid enough    
    // Call modifer to send any excess ether back to buyer
    {
    
    // Update the appropriate fields - ownerID, distributorID, itemStat   
    items[_upc].ownerID = msg.sender;
    items[_upc].distributorID = payable(msg.sender);
    items[_upc].itemState = State.Sold;
    // Transfer money to farmer
    items[_upc].originFarmerID.transfer(items[_upc].productPrice);
    // emit the appropriate event
    emit Sold(_upc);
  }

  // Define a function 'shipItem' that allows the distributor to mark an item 'Shipped'
  // Use the above modifers to check if the item is sold
  function shipItem(uint _upc) sold(_upc) onlyDistributor onlyItemOwner(_upc) public 
    // Call modifier to check if upc has passed previous supply chain stage
    // Call modifier to verify caller of this function
    {
    // Update the appropriate fields
    items[_upc].itemState = State.Shipped;
    // Emit the appropriate event
    emit Shipped(_upc);
  }

  // Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
  // Use the above modifiers to check if the item is shipped
  function receiveItem(uint _upc) shipped(_upc) onlyRetailer public 
    // Call modifier to check if upc has passed previous supply chain stage
    // Access Control List enforced by calling Smart Contract / DApp
    {
    // Update the appropriate fields - ownerID, retailerID, itemState
    items[_upc].ownerID = msg.sender;
    items[_upc].retailerID = msg.sender;
    items[_upc].itemState = State.Received;
    // Emit the appropriate event
    emit Received(_upc);
  }

  // Define a function 'purchaseItem' that allows the consumer to mark an item 'Purchased'
  // Use the above modifiers to check if the item is received
  function purchaseItem(uint _upc) received(_upc) onlyConsumer public 
    // Call modifier to check if upc has passed previous supply chain stage
    // Access Control List enforced by calling Smart Contract / DApp
    {
    // Update the appropriate fields - ownerID, consumerID, itemState
    items[_upc].ownerID = msg.sender;
    items[_upc].consumerID = msg.sender;
    items[_upc].itemState = State.Purchased;
    // Emit the appropriate event
    emit Purchased(_upc);
  }

  // Define a function 'fetchItemBufferOne' that fetches the data
  function fetchItemBufferOne(uint _upc) public view returns 
  (
  uint    itemSKU,
  uint    itemUPC,
  address ownerID,
  address originFarmerID,
  string memory originFarmName,
  string memory originFarmInformation,
  string memory originFarmLatitude,
  string memory originFarmLongitude
  ) 
  {
  // Assign values to the 8 parameters
  return (
    items[_upc].sku,
    items[_upc].upc,
    items[_upc].ownerID,
    items[_upc].originFarmerID,
    items[_upc].originFarmName,
    items[_upc].originFarmInformation,
    items[_upc].originFarmLatitude,
    items[_upc].originFarmLongitude
  );
  } 


  // Define a function 'fetchItemBufferTwo' that fetches the data
  function fetchItemBufferTwo(uint _upc) public view returns 
  (
  uint    itemSKU,
  uint    itemUPC,
  uint    productID,
  string memory productNotes,
  uint    productPrice,
  uint    itemState,
  address payable distributorID,
  address retailerID,
  address consumerID
  ) 
  {
    // Assign values to the 9 parameters
  
    
  return 
  (
  items[_upc].sku,
  items[_upc].upc,
  items[_upc].itemID,
  items[_upc].productNotes,
  items[_upc].productPrice,
  uint(items[_upc].itemState),
  items[_upc].distributorID,
  items[_upc].retailerID,
  items[_upc].consumerID
  );
  }  
}
