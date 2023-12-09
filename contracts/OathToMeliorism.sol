    // To integrate:
// 1. ownerOnly and/or internal (for security)
// 2. Royalties, max supply and mint price
// 3. Ability to change the above
// 4. Ability to change URI

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OathToMeliorism is ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeMath for uint8;
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenID;
    Counters.Counter private taskCounter;
    string public collectionInfoURI; // Assigns the JSON containing the collection's metadata

    // Whitelist
    mapping(uint16 => uint256) public mint_prices;
    mapping(uint16 => uint16) public mint_limits;
    mapping(address => uint16) public whitelist_tiers;
    event WhitelistAssigned(address user_address, uint16 whitelist_tier);

    // Max Supply
    uint256 public _maxSupply;
    
    // Primary NFT Assignment
    Counters.Counter private primaryTokenHolderCounter;
    mapping(address => uint256) public holderPrimaryTokens;
    mapping(uint256 => address) public primaryTokenHolderIndex;
    event PrimaryTokenAssigned(uint256 token_ID, address user_address);

    // Character Structure
    struct Character {
        string metadata_URI;
        uint256 tasks_completed;
        uint256[] task_IDs;
        string[] task_tags;
        bytes32[] task_hashes;
        uint256[] task_timestamps;
        address[] user_addresses;        
    }
    mapping (uint256 => Character) public characters;

    // Task Structure
    struct Task {
        string metadata_URI;
        uint256 task_ID;
        string task_tags;
        bytes32 task_hash;
        address[] task_completers;
        uint256 task_creation_timestamp;
        address task_creator_address;
    }
    mapping (uint256 => Task) public tasks;
    mapping (bytes32 => uint256) public taskHashArray;
    event TaskCreated(uint256 task_count, uint256 task_ID, string task_tags, string task_metadata_URI, bytes32 task_hash);
    event TaskCompleted(uint256 task_ID, string task_tags, bytes32 task_hash, uint256 task_timestamp, address completer_address);
    
    
    constructor() ERC721("OathToMeliorism", "NOFUN") {
        collectionInfoURI = "https://nftstorage.link/ipfs/bafybeifpq52p2xfppv2bmfutnjr5wlfky6lex646uiyzggbtbmoj73ka7m/OathToMeliorism.json";
    }

//__________________________________________________________________________________
// Admin Functions - all admin functions begin with two underscores __

    function __mintFree(string memory token_URI) onlyOwner public returns (uint256 token_ID) {
        token_ID = ____mint(token_URI);

        return token_ID;
    }

    function __setMintPrice(uint256 new_price, uint16 whitelist_tier) onlyOwner public returns (uint256 old_price) {
        old_price = getMintPrice(whitelist_tier);
        mint_prices[whitelist_tier] = new_price;

        return(old_price);
    }

    function __setMaxSupply(uint256 new_max_supply) onlyOwner public returns (uint256 old_max_supply) {
        old_max_supply = getMaxSupply();
        _maxSupply = new_max_supply;

        return(old_max_supply);
    }

    function __setTokenURI(uint256 token_ID, string memory token_URI) onlyOwner public returns (string memory old_token_URI) {
        require(_exists(token_ID), "ERROR: Token does not exist");

        old_token_URI = tokenURI(token_ID);
        _setTokenURI(token_ID, token_URI);
        characters[token_ID].metadata_URI = token_URI;

        return(old_token_URI);
    }

    function __setPrimaryTokenID (uint256 token_ID, address user_address) onlyOwner public {
        ____setPrimaryTokenID(token_ID, user_address);
    }


    // Sets the URI for the collection info JSON.
    function __setContractURI(string memory new_collectionInfoURI) onlyOwner public returns (string memory old_collectionInfoURI) {
        old_collectionInfoURI = collectionInfoURI;
        collectionInfoURI = new_collectionInfoURI;

        return(old_collectionInfoURI);
    }


    function __createTask(uint256 task_ID, string memory task_tags, string memory task_metadata_URI) onlyOwner public returns (bytes32 task_hash) {
        task_hash = sha256(abi.encodePacked(task_ID, task_tags));

        require(taskHashArray[task_hash] < 1, "Task with identical ID and TAGS already exists!");

        taskCounter.increment();

        uint256 task_count = taskCounter.current();

        tasks[task_count] = Task({
            metadata_URI: task_metadata_URI,
            task_ID: task_ID,
            task_tags: task_tags,
            task_hash: task_hash,
            task_completers: new address[](0),
            task_creation_timestamp: block.timestamp,
            task_creator_address: msg.sender     
        });

        taskHashArray[task_hash] = task_count;

        emit TaskCreated(task_count, task_ID, task_tags, task_metadata_URI, task_hash);
    }


/*
__________________________________________________________________________________
Internal Functions - all internal functions begin with 4 underscores ____
__________________________________________________________________________________
*/ 

    function ____mint(string memory token_URI) internal returns (uint256 token_ID) {
        require(currentTokenID.current() < _maxSupply, "ERROR: Maximum token supply reached");

        currentTokenID.increment();
        token_ID = currentTokenID.current();
        _safeMint(msg.sender, token_ID);
        _setTokenURI(token_ID, token_URI);

        // Set as Primary token if the holder has none
        if (getPrimaryTokenID(msg.sender) < 1) {
            setPrimaryTokenID(token_ID);
        }
        setPrimaryTokenID(token_ID);

        characters[token_ID] = Character({
            metadata_URI: token_URI,
            tasks_completed: 0,
            task_IDs: new uint256[](0),
            task_tags: new string[](0),
            task_hashes: new bytes32[](0),
            task_timestamps: new uint256[](0),
            user_addresses: new address[](0)
        });

        characters[token_ID].user_addresses.push(msg.sender);

        return token_ID;
    }

    function ____setPrimaryTokenID (uint256 token_ID, address user_address) internal {
        require(_ownerOf(token_ID) == user_address, "ERROR: Address is not owner of token");
        if (!(getPrimaryTokenID(user_address) > 0)) {
            primaryTokenHolderCounter.increment();
            primaryTokenHolderIndex[primaryTokenHolderCounter.current()] = user_address;
        }
        holderPrimaryTokens[user_address] = token_ID;
        emit PrimaryTokenAssigned(token_ID, user_address);
    }



/*
__________________________________________________________________________________
Public Functions
__________________________________________________________________________________
*/ 

    function getTaskHash(uint256 task_ID, string memory task_tags) public view returns (bytes32 task_hash) {
        task_hash = sha256(abi.encodePacked(task_ID, task_tags));
        return(task_hash);
    }

    function getTask(uint256 task_ID, string memory task_tags) public view returns (string memory, bytes32, address[] memory, uint256, address) {
        bytes32 task_hash = getTaskHash(task_ID, task_tags);
        Task memory task_instance = tasks[taskHashArray[task_hash]];
        
        return(task_instance.metadata_URI, task_instance.task_hash, task_instance.task_completers, task_instance.task_creation_timestamp, task_instance.task_creator_address);
    }

    function getCharacter(uint256 token_ID) public view returns (string memory, uint256, uint256[] memory, string[] memory, bytes32[] memory, uint256[] memory, address[] memory) {
        Character memory character_instance = characters[token_ID];

        return(character_instance.metadata_URI, character_instance.tasks_completed, character_instance.task_IDs, character_instance.task_tags, character_instance.task_hashes, character_instance.task_timestamps, character_instance.user_addresses);
    }

    function completeTask(uint256 task_ID, string memory task_tags) public returns (bytes32 task_hash) {
        task_hash = sha256(abi.encodePacked(task_ID, task_tags));
        uint256 token_ID = getPrimaryTokenID(msg.sender);
        uint256 task_timestamp = block.timestamp;

        characters[token_ID].tasks_completed += 1;
        characters[token_ID].task_IDs.push(task_ID);
        characters[token_ID].task_tags.push(task_tags);
        characters[token_ID].task_hashes.push(task_hash);
        characters[token_ID].task_timestamps.push(task_timestamp);

        tasks[taskHashArray[task_hash]].task_completers.push(msg.sender);

        emit TaskCompleted(task_ID, task_tags, task_hash, task_timestamp, msg.sender);
    }

    function completeTaskBatch(uint256[] memory task_IDs, string[] memory task_tags) onlyOwner public returns (bytes32[] memory completed_task_hashes) {
        require(task_IDs.length == task_tags.length, "Task ID and Task Tag arrays do not have matching lengths");

        completed_task_hashes = new bytes32[](task_IDs.length);

        for (uint256 i = 0; i < task_IDs.length; i++) {
            bytes32 task_hash = completeTask(task_IDs[i], task_tags[i]);

            completed_task_hashes[i] = task_hash;
        }
        return(completed_task_hashes);
    }

    function mint(string memory token_URI) public payable returns (uint256 token_ID) {
        uint256 mint_price = getMintPrice(getWhitelistTier(msg.sender));

        require(msg.value >= mint_price, "ERROR: Less funds were sent than the mint price");
        
        token_ID = ____mint(token_URI);
        setPrimaryTokenID(token_ID);

        return token_ID;
    }

    function getMintPrice (uint16 whitelist_tier) public view returns (uint256) {
        return (mint_prices[whitelist_tier]);
    }

    function getMaxSupply () public view returns (uint256) {
        return (_maxSupply);
    }


    function getWhitelistTier (address user_address) public view returns (uint16) {
        // should return 0 if not whitelisted
        return (whitelist_tiers[user_address]);
    }

    function setPrimaryTokenID (uint256 token_ID) public {
        ____setPrimaryTokenID(token_ID, msg.sender);
    }

    function getPrimaryTokenID (address user_address) public view returns (uint256 token_ID) {
        token_ID = holderPrimaryTokens[user_address];
        return token_ID;
    }
    
    function getPrimaryTokenURI (address user_address) public view returns (string memory _tokenURI) {
        _tokenURI = tokenURI(holderPrimaryTokens[user_address]);
        return _tokenURI;
    }

    function getPrimaryHolderCount() public view returns (uint256) {
        return primaryTokenHolderCounter.current();
    }

    function getPrimaryHolderByIndex(uint256 index) public view returns (address) {
        return primaryTokenHolderIndex[index];
    }

    /*
    function getAllPrimaryHolders() public view returns (address[] memory) {
        uint256 primaryHolderCount = getPrimaryHolderCount();
        address[] memory primaryHolderAddresses = new address[](primaryHolderCount);
        for (uint i = 1; i <= primaryHolderCount; i++) {
            primaryHolderAddresses[i] = getPrimaryHolderByIndex(i);
        }
        return primaryHolderAddresses;
    }
    */




/*
__________________________________________________________________________________
Platform Functions
__________________________________________________________________________________
*/ 

    // Required for OpenSea to obtain information about the entire collection, such as the profile image and description
    function contractURI() public view returns (string memory) {
        return collectionInfoURI;
    }

}