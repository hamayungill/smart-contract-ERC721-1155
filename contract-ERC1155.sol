// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DualTk is ERC1155, Ownable {

    address public contractAdmin;
    uint public lastRun = block.timestamp;
    uint256[] max_supplies = [1000, 1000, 1000]; // token id would be 1, 2, 3
    uint256[] minted_tok = [0, 0, 0]; // number of token user already minted
    address[] userAddress;

    mapping( address => User ) userD; // address => already minted
    
    struct User {
        uint256 max_limit;
        uint256 already_minted;
    }

    constructor() ERC1155("") {
        contractAdmin = msg.sender;
    }

    /** only Admin */
    modifier onlyAdmin () {
        require(msg.sender == contractAdmin, "Only Admin can whitelist the users.");
        _;
    }
    
    /** only whitelisted users */
    modifier onlyWhiteListedUser () {
        require(checkWhitelistUser(msg.sender), "Only Whitelisted user can mint.");
        _;
    }

    function whitelistUser(address userAdrs, uint256 maxSply) public onlyAdmin returns (bool success){
        bool isExist = checkWhitelistUser(userAdrs);
        if(!isExist){
            userAddress.push(userAdrs);
            userD[userAdrs].max_limit = maxSply;
            userD[userAdrs].already_minted = 0;
        }
        return true;
    }

    function checkWhitelistUser(address userAdrs) internal view returns (bool success){
        bool isExist = false;
        for(uint i = 0; i < userAddress.length; i++){
           if(userAddress[i] == userAdrs){
               isExist = true;
           } 
        }
        return isExist;
    }

    function mint(uint256 id, uint256 amount) public onlyWhiteListedUser {
        validateTime();

        require(id <= max_supplies.length, "Token Doesn't Exist"); //token should be [1, 2, 3] 
        require(id > 0, "Token Doesn't Exist");
        require(minted_tok[id-1] + amount < max_supplies[id-1], "Max Limit Exceed for the ID");
        require(userD[msg.sender].already_minted + amount <= userD[msg.sender].max_limit, "User Exceed his/her max minted limit for 2 minutes.");
        
        _mint(msg.sender, id, amount, "");
        userD[msg.sender].already_minted += amount;
        minted_tok[id-1] += amount;
    }

    function validateTime() internal {
        if(block.timestamp - lastRun > 2 minutes){
            lastRun = block.timestamp;
            resetAlreadyMinted();
        }
    }

    function resetAlreadyMinted() internal {
        for(uint i = 0; i < userAddress.length; i++ ){
            userD[userAddress[i]].already_minted = 0;
       }
    }
}