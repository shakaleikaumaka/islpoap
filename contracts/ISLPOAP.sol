// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// ─────────────────────────────────────────────────────────────────────────────
///  🏝️ ISLPOAP — the island where POAPs live on (PHASE 2 DRAFT — NOT DEPLOYED)
///
///  A free-claim ERC-1155 for Base. Token id = BasePaint day number.
///  Any address may claim any finished day's badge, once, for gas only.
///  No fees. No owner mint privileges. No pause. A gift, not extractive.
///
///  Dedicated to Patricio, Isabel and the whole POAP team. Mahalo. 🤙🌺
///
///  STATUS: staged draft for review — unaudited, not yet deployed.
///  Deliberately minimal & dependency-free so anyone can read all of it.
/// ─────────────────────────────────────────────────────────────────────────────
contract ISLPOAP {
    // ─── ERC-1155 events ────────────────────────────────────────────────────
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    event Claimed(address indexed collector, uint256 indexed day);

    // BasePaint genesis (day 1 start, unix seconds)
    uint256 public constant GENESIS = 1691599315;

    string public name = "ISLPOAP";
    string public symbol = "ISLPOAP";
    string private _base; // e.g. ipfs://<CID>/ or https://... metadata root

    mapping(uint256 => mapping(address => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(uint256 => uint256) public claimedCount; // day => total claims

    constructor(string memory baseURI) { _base = baseURI; }

    /// Current BasePaint day (1-based).
    function currentDay() public view returns (uint256) {
        return (block.timestamp - GENESIS) / 86400 + 1;
    }

    /// Claim the badge for a finished BasePaint day. Free. Once per address per day.
    function claim(uint256 day) external {
        require(day >= 1 && day < currentDay(), "day not finished");
        require(balanceOf[day][msg.sender] == 0, "already claimed");
        balanceOf[day][msg.sender] = 1;
        unchecked { claimedCount[day] += 1; }
        emit TransferSingle(msg.sender, address(0), msg.sender, day, 1);
        emit Claimed(msg.sender, day);
    }

    // ─── minimal ERC-1155 surface ───────────────────────────────────────────
    function uri(uint256 id) external view returns (string memory) {
        return string(abi.encodePacked(_base, _toString(id), ".json"));
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external view returns (uint256[] memory out)
    {
        require(owners.length == ids.length, "length");
        out = new uint256[](owners.length);
        for (uint256 i; i < owners.length; ++i) out[i] = balanceOf[ids[i]][owners[i]];
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// Badges are memories: soulbound by default is a design question for Shaka &
    /// the community — this draft allows transfers, like POAP did.
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata) external {
        require(from == msg.sender || isApprovedForAll[from][msg.sender], "not allowed");
        require(to != address(0), "zero to");
        require(balanceOf[id][from] >= amount, "balance");
        unchecked { balanceOf[id][from] -= amount; }
        balanceOf[id][to] += amount;
        emit TransferSingle(msg.sender, from, to, id, amount);
        // NOTE (draft): ERC-1155 receiver hook check to be added before deploy.
    }

    function supportsInterface(bytes4 iid) external pure returns (bool) {
        return iid == 0xd9b67a26 /* ERC1155 */ || iid == 0x0e89341c /* ERC1155MetadataURI */ || iid == 0x01ffc9a7 /* ERC165 */;
    }

    function _toString(uint256 v) private pure returns (string memory) {
        if (v == 0) return "0";
        uint256 t = v; uint256 d;
        while (t != 0) { d++; t /= 10; }
        bytes memory b = new bytes(d);
        while (v != 0) { b[--d] = bytes1(uint8(48 + v % 10)); v /= 10; }
        return string(b);
    }
}
