pragma solidity >=0.7.0 <0.9.0;

// Contract owner and role admin class 
// can assign roles and kill contract if needed
contract ContractOwner {
    address public contractOwner;

    // Define an Event
    event TransferContractOwnership(address indexed oldOwner, address indexed newOwner);

    /// Assign the contract to an owner
    constructor () {
        contractOwner = msg.sender;
        emit TransferContractOwnership(address(0), contractOwner);
    }

    /// Define a function modifier 'onlyOwner'
    modifier onlyContractOwner() {
        require(isContractOwner());
        _;
    }

    /// Check if the calling address is the owner of the contract
    function isContractOwner() public view returns (bool) {
        return msg.sender == contractOwner;
    }

    /// Define a function to renounce ownerhip
    function renounceOwnership() public onlyContractOwner {
        emit TransferContractOwnership(contractOwner, address(0));
        contractOwner = address(0);
    }

    /// Define a public function to transfer ownership
    function transferContractOwnership(address newOwner) public onlyContractOwner {
        _transferContractOwnership(newOwner);
    }

    /// Define an internal function to transfer ownership
    function _transferContractOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit TransferContractOwnership(contractOwner, newOwner);
        contractOwner = newOwner;
    }
}
