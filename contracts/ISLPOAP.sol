// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// ─────────────────────────────────────────────────────────────────────────────
///  🏝️ ISLPOAP — the island where POAPs live on · "IStill Love Poap"
///
///  A free-claim ERC-1155 on Base. Token id = BasePaint day number.
///  Any address may claim any finished day's badge, once, for gas only.
///  No fees. No owner. No admin keys. No pause. A gift, not extractive.
///  Metadata is generated fully on-chain (base64 JSON) — no server, no IPFS,
///  no kill switch. The badge art is the day's CC0 BasePaint canvas.
///
///  Dedicated to Patricio, Isabel and the whole POAP team, who spent five
///  years turning "I was there" into something you could keep forever.
///  Mahalo. 🤙🌺
/// ─────────────────────────────────────────────────────────────────────────────
contract ISLPOAP {
    // ─── events ─────────────────────────────────────────────────────────────
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    event Claimed(address indexed collector, uint256 indexed day);

    // BasePaint genesis (day 1 start, unix seconds) — basepaint.xyz/ai.txt
    uint256 public constant GENESIS = 1691599315;

    string public constant name = "ISLPOAP";
    string public constant symbol = "ISLPOAP";

    mapping(uint256 => mapping(address => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(uint256 => uint256) public claimedCount; // day => total claims

    // ─── the heart ──────────────────────────────────────────────────────────

    /// Current BasePaint day (1-based).
    function currentDay() public view returns (uint256) {
        return (block.timestamp - GENESIS) / 86400 + 1;
    }

    /// Claim the badge for a finished BasePaint day. Free. Once per address per day.
    function claim(uint256 day) public {
        require(day >= 1 && day < currentDay(), "day not finished");
        require(balanceOf[day][msg.sender] == 0, "already claimed");
        balanceOf[day][msg.sender] = 1;
        unchecked { claimedCount[day] += 1; }
        emit TransferSingle(msg.sender, address(0), msg.sender, day, 1);
        emit Claimed(msg.sender, day);
        _acceptanceCheck(msg.sender, address(0), msg.sender, day, 1, "");
    }

    /// Claim several days in one transaction.
    function claimMany(uint256[] calldata days_) external {
        for (uint256 i; i < days_.length; ++i) claim(days_[i]);
    }

    // ─── on-chain metadata ──────────────────────────────────────────────────

    function uri(uint256 id) external pure returns (string memory) {
        string memory d = _toString(id);
        bytes memory json = abi.encodePacked(
            '{"name":"ISLPOAP \\u2014 BasePaint Day ', d,
            '","description":"Proof of presence on BasePaint day ', d,
            ' \\u2014 CC0 collaborative pixel art painted by many hands. Free claim on the island where POAPs live on (IStill Love Poap), dedicated to the POAP team. A gift, not extractive.",',
            '"image":"https://basepaint.net/v3/', _pad4(id), '.png",',
            '"external_url":"https://basepaint.xyz/canvas/', d, '",',
            '"attributes":[{"trait_type":"Day","value":', d, '},',
            '{"trait_type":"License","value":"CC0"},',
            '{"trait_type":"Dedication","value":"To Patricio, Isabel & the POAP team"}]}'
        );
        return string(abi.encodePacked("data:application/json;base64,", _base64(json)));
    }

    // ─── ERC-1155 surface ───────────────────────────────────────────────────

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

    /// Transferable, like POAP was. Memories can be given.
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external {
        require(from == msg.sender || isApprovedForAll[from][msg.sender], "not allowed");
        require(to != address(0), "zero to");
        uint256 bal = balanceOf[id][from];
        require(bal >= amount, "balance");
        unchecked { balanceOf[id][from] = bal - amount; }
        balanceOf[id][to] += amount;
        emit TransferSingle(msg.sender, from, to, id, amount);
        _acceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external {
        require(from == msg.sender || isApprovedForAll[from][msg.sender], "not allowed");
        require(to != address(0), "zero to");
        require(ids.length == amounts.length, "length");
        for (uint256 i; i < ids.length; ++i) {
            uint256 bal = balanceOf[ids[i]][from];
            require(bal >= amounts[i], "balance");
            unchecked { balanceOf[ids[i]][from] = bal - amounts[i]; }
            balanceOf[ids[i]][to] += amounts[i];
        }
        emit TransferBatch(msg.sender, from, to, ids, amounts);
        if (to.code.length != 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) returns (bytes4 ret) {
                require(ret == IERC1155Receiver.onERC1155BatchReceived.selector, "rejected");
            } catch { revert("non-receiver"); }
        }
    }

    function supportsInterface(bytes4 iid) external pure returns (bool) {
        return iid == 0xd9b67a26 /* ERC1155 */ || iid == 0x0e89341c /* ERC1155MetadataURI */ || iid == 0x01ffc9a7 /* ERC165 */;
    }

    // ─── internals ──────────────────────────────────────────────────────────

    function _acceptanceCheck(address operator, address from, address to, uint256 id, uint256 amount, bytes memory data) private {
        if (to.code.length != 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 ret) {
                require(ret == IERC1155Receiver.onERC1155Received.selector, "rejected");
            } catch { revert("non-receiver"); }
        }
    }

    function _toString(uint256 v) private pure returns (string memory) {
        if (v == 0) return "0";
        uint256 t = v; uint256 d;
        while (t != 0) { d++; t /= 10; }
        bytes memory b = new bytes(d);
        while (v != 0) { b[--d] = bytes1(uint8(48 + v % 10)); v /= 10; }
        return string(b);
    }

    /// zero-padded to at least 4 digits, as basepaint.net expects
    function _pad4(uint256 v) private pure returns (string memory) {
        string memory s = _toString(v);
        while (bytes(s).length < 4) s = string(abi.encodePacked("0", s));
        return s;
    }

    bytes private constant B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function _base64(bytes memory data) private pure returns (string memory) {
        if (data.length == 0) return "";
        bytes memory table = B64;
        uint256 outLen = 4 * ((data.length + 2) / 3);
        bytes memory out = new bytes(outLen);
        uint256 i; uint256 j;
        while (i + 3 <= data.length) {
            uint256 n = (uint256(uint8(data[i])) << 16) | (uint256(uint8(data[i+1])) << 8) | uint256(uint8(data[i+2]));
            out[j] = table[(n >> 18) & 63]; out[j+1] = table[(n >> 12) & 63];
            out[j+2] = table[(n >> 6) & 63]; out[j+3] = table[n & 63];
            i += 3; j += 4;
        }
        uint256 rem = data.length - i;
        if (rem == 1) {
            uint256 n = uint256(uint8(data[i])) << 16;
            out[j] = table[(n >> 18) & 63]; out[j+1] = table[(n >> 12) & 63];
            out[j+2] = "="; out[j+3] = "=";
        } else if (rem == 2) {
            uint256 n = (uint256(uint8(data[i])) << 16) | (uint256(uint8(data[i+1])) << 8);
            out[j] = table[(n >> 18) & 63]; out[j+1] = table[(n >> 12) & 63];
            out[j+2] = table[(n >> 6) & 63]; out[j+3] = "=";
        }
        return string(out);
    }
}

interface IERC1155Receiver {
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4);
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns (bytes4);
}
