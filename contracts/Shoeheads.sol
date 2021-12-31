//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

// REMOVE BEFORE DEPLOYMENT //
import "hardhat/console.sol"; 
// REMOVE BEFORE DEPLOYMENT //
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Shoeheads is ERC721, Ownable {
    // Minting prices
    uint256 public salePrice;

    // Supply variables
    uint256 public totalSupply;
    uint256 public maxPerTxn;
    uint256 public maxPerWallet;
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant RESERVED = 222;
    uint256 public constant PRE_SALE_SUPPLY = 2000;
    uint256 public constant WHITELIST_SUPPLY = 4000;

    // Allowlist variables
    bytes32 public presaleRoot;
    bytes32 public whitelistRoot;

    // Payout addresses
    address public _a1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address public _a2 = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address public _a3 = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    address public _a4 = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address public _a5 = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
    address public _a6 = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB; // NFTY KICKS WALLET
    address public _a7 = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;

    // State variables
    bool public regActive;
    bool public preSaleActive;
    bool public whiteListActive;

    // Metadata variable
    string public _baseURI_;

    // Track mints per wallet
    mapping(address => uint256) public walletMints;

    // Events
    event PresaleActive(bool _state);
    event WhitelistActive(bool _state);
    event RegActive(bool _state);

    constructor() ERC721("Shoeheads NFT", "shoeheads") {
        salePrice = 0.05 ether;
        totalSupply = 0;
        maxPerTxn = 2;
        maxPerWallet = 5;
        regActive = false;
        preSaleActive = false;
        whiteListActive = false;

        // Set baseURI
        _baseURI_ = "www.twitter.com";
    }

    // Modifiers
    modifier isPresaleActive() {
        require(preSaleActive, "Presale hasn't started yet");
        _;
    }

    modifier isWhitelistActive() {
        require(whiteListActive, "Whitelist hasn't started yet");
        _;
    }

    modifier isRegActive() {
        require(regActive, "GA sale hasn't started yet");
        _;
    }

    // Allowlist functions
    function isPresale(bytes32[] memory merkleProof) public view returns (bool) {

        bytes32 leaf = keccak256(abi.encodePacked((msg.sender)));
        
        return MerkleProof.verify(merkleProof, presaleRoot, leaf);
    }

    function isWhitelist(bytes32[] memory merkleProof) public view returns (bool) {

        bytes32 leaf = keccak256(abi.encodePacked((msg.sender)));
        
        return MerkleProof.verify(merkleProof, whitelistRoot, leaf);
    }

    function updatePresaleRoot(bytes32 _presaleRoot) external onlyOwner {
        presaleRoot = _presaleRoot;
    }

    function updateWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner {
        whitelistRoot = _whitelistRoot;
    }

    // Internal functions
    function isContract(address address_) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(address_)
        }
        return size > 0;
    }

    // Minting functions
    function mintTokens(uint256 quantity) private {
        for (uint256 i = 0; i < quantity; i++) {
            uint256 newTokenId = totalSupply + 1;
            _safeMint(msg.sender, newTokenId);
            totalSupply++;
        }
        walletMints[msg.sender] += quantity;
    }

    function mintingRules(uint256 value, uint256 quantity) private view {
        require(isContract(msg.sender) == false, "Only real soles can mint");
        require(value == getPrice(quantity), "Not enough cash money");
        require(totalSupply < MAX_SUPPLY, "Store's cleared out");
        require(totalSupply + quantity <= MAX_SUPPLY, "Can't buy more than we have");
        require(quantity <= maxPerTxn, "Sorry, we have a limit");
        require(walletMints[msg.sender] + quantity <= maxPerWallet, "No whales here");
    }

    function mintPresale(uint256 quantity, bytes32[] memory proof_) public payable isPresaleActive {
        require(isPresale(proof_), "You didn't make the list");
        require(walletMints[msg.sender] + quantity <= 2, "Already got your presale tokens");
        mintingRules(msg.value, quantity);
        mintTokens(quantity);
    }

    function mintWhiteList(uint256 quantity, bytes32[] memory proof_) public payable isWhitelistActive {
        require(isWhitelist(proof_), "You didn't make the list");
        mintingRules(msg.value, quantity);
        mintTokens(quantity);
    }

    function mintPublic(uint256 quantity) public payable isRegActive {
        mintingRules(msg.value, quantity);
        mintTokens(quantity);
    }

    // Utility functions
    function getPrice(uint256 quantity) internal view returns (uint256) {
        return quantity * salePrice;
    }

    function setPriceInWei(uint256 _price) external onlyOwner {
        salePrice = _price;
    }

    function setMaxPerTxn(uint256 _maxPerTxn) external onlyOwner {
        maxPerTxn = _maxPerTxn;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _baseURI_ = _newBaseURI;
    }

    function setRegActive() external onlyOwner {
        maxPerTxn = 5;
        salePrice = 0.07 ether;
        regActive = !regActive;
        emit RegActive(regActive);
    }

    function setPresaleActive() external onlyOwner {
        maxPerTxn = 2;
        preSaleActive = !preSaleActive;
        emit PresaleActive(preSaleActive);
    }

    function setWhitelistActive() external onlyOwner {
        maxPerTxn = 5;
        salePrice = 0.07 ether;
        whiteListActive = !whiteListActive;
        emit WhitelistActive(whiteListActive);
    }

    function withdraw() external onlyOwner {
        uint256 _p1 = address(this).balance * 24/100;
        uint256 _p2 = address(this).balance * 23/100;
        uint256 _p3 = address(this).balance * 23/100;
        uint256 _p4 = address(this).balance * 13/100;
        uint256 _p5 = address(this).balance * 7/100;
        uint256 _p6 = address(this).balance * 8/100;
        uint256 _p7 = address(this).balance * 2/100;

        (bool a1Success, ) = payable(_a1).call{value: _p1}("");
        require(a1Success, "Failed to send to a1");
        (bool a2Success, ) = payable(_a2).call{value: _p2}("");
        require(a2Success, "Failed to send to a2");
        (bool a3Success, ) = payable(_a3).call{value: _p3}("");
        require(a3Success, "Failed to send to a3");
        (bool a4Success, ) = payable(_a4).call{value: _p4}("");
        require(a4Success, "Failed to send to a4");
        (bool a5Success, ) = payable(_a5).call{value: _p5}("");
        require(a5Success, "Failed to send to a5");
        (bool a6Success, ) = payable(_a6).call{value: _p6}("");
        require(a6Success, "Failed to send to a6");
        (bool a7Success, ) = payable(_a7).call{value: _p7}("");
        require(a7Success, "Failed to send to a7");
    }

    // Public functions

    function _baseURI() internal view override returns (string memory) {
        return _baseURI_;
    }

    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - totalSupply;
    }

    function tokensByOwner(address address_) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(address_);
        uint256[] memory tokens = new uint256[](balance);
        uint256 index;

        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            if (address_ == ownerOf(i)) {
                tokens[index] = i;
                index++;
            }
        }

        return tokens;
    }
}