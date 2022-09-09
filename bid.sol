// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <mikhail.vladimirov@gmail.com>
 */
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC20.sol";
import "./NFT.sol";

contract Bid is ReentrancyGuard {
    struct Block {
        uint256 timestamp;
        uint256 bn;
        uint256 baseAmount;
        bool isBidOpen;
        string blockType;
        bool code;
        address owner;
        bool a;
        bool b;
        bool c;
        bool d;
        bool e;
        bool f;
        bool g;
        bool h;
        bool i;
        uint256 gameStoneBaseAmount;
        uint256 lastClaimTime;
        uint256 lastbidTime;
    }
    struct TopBid {
        address payable bider;
        uint256 amount;
    }
    struct prevBid {
        address bider;
        uint256 amount;
    }
    uint256 usdtholder = 0;
    // uint256 bid_percentage;
    // uint256 next_bid_amount;
    address admin;
    uint256 blockCount = 0;
    uint256 lastbn;
    address prevHighBid;
    uint256 withdrawableUSDT = 0;
    address ERC20Address;
    address usdtAddress;
    uint256 currentbid;
    IERC20 public usdt;
    IERC20 public gsd;
    NFT public nft;

    mapping(address => uint256) balances;
    mapping(uint256 => uint256) bid_counts;
    mapping(uint256 => Block) blocks;
    mapping(uint256 => TopBid) top_bids;
    mapping(address => uint256) cERC20;
    mapping(uint => address[100]) agents;
    mapping(address => mapping(address => uint256)) tokens;
    // Arrays
    uint256[] public bns;
    address[] public addresses;
    event Deposit(
        address indexed user,
        address token,
        uint256 amount,
        uint256 timestamp
    );
    event BidDeposit(address indexed user, uint256 amount, uint256 timestamp);
    event Transfer(address sender, address to, uint256 amount);

    constructor(
        address USDTAddress,
        address ERC20Address,
        address nftAddress
    ) {
        admin = msg.sender;
        usdt = ERC20(USDTAddress);
        gsd = ERC20(ERC20Address);
        nft = NFT(nftAddress);
        ERC20Address = ERC20Address;
        usdtAddress = usdtAddress;
    }

    function safeMul(uint256 a, uint256 b) private pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) private pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) private pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function createStruct(
        uint256 _timestamp,
        uint256 _block,
        uint256 _baseAmount,
        bool _code,
        string memory video_uri
    ) public payable {
        require(msg.sender == admin);
        if (_code == true) {
            closeBid(lastbn);
        }
        bid_counts[_block] = 0;
        blocks[_block].code = _code;
        blocks[_block].baseAmount = _baseAmount;
        blocks[_block].code = _code;
        blocks[_block].bn = _block;
        blocks[_block].timestamp = _timestamp;
        blocks[_block].isBidOpen = true;
        blocks[_block].a = false;
        blocks[_block].b = false;
        blocks[_block].c = false;
        blocks[_block].d = false;
        blocks[_block].e = false;
        blocks[_block].f = false;
        blocks[_block].g = false;
        blocks[_block].h = false;
        blocks[_block].i = false;
        blocks[_block].owner = admin;
        blocks[_block].lastClaimTime = 0;
        bns.push(_block);
        top_bids[_block].bider = payable(admin);
        top_bids[_block].amount = _baseAmount;
        currentbid = _baseAmount;
        if (_code == true) {
            lastbn = _block;
        }
        blockCount += 1;
        nft.createToken(video_uri, _block);
    }

    function userDeposit() external payable nonReentrant {
        require(msg.value > 0);
        balances[msg.sender] += msg.value;
    }

    function addAgent(uint256 _block, address _agent)
        public
        payable
        nonReentrant
    {
        require(!blocks[_block].isBidOpen);
        agents[_block][agents[_block].length] = _agent;
    }

    function depositUSDTandConvertToCustom(uint256 amount)
        external
        nonReentrant
        returns (bool)
    {
        require(amount > 0);
        usdt.transferFrom(msg.sender, address(this), amount);
        usdtholder = safeAdd(usdtholder, amount);
        tokens[ERC20Address][msg.sender] = safeAdd(
            tokens[ERC20Address][msg.sender],
            amount
        );
        emit BidDeposit(msg.sender, amount, block.timestamp);
        return true;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function userWithdraw() external nonReentrant {
        require(balances[msg.sender] > 0);
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function adminWithdraw() external nonReentrant {
        require(msg.sender == admin);
        uint256 amount = balances[admin];
        balances[admin] = 0;
        payable(admin).transfer(amount);
    }

    function getUserBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function getBlockDetail(uint256 _block)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            bool,
            string memory,
            address
        )
    {
        return (
            blocks[_block].timestamp,
            blocks[_block].bn,
            top_bids[_block].amount,
            blocks[_block].code,
            blocks[_block].isBidOpen,
            blocks[_block].blockType,
            blocks[_block].owner
        );
    }

    function bid(uint256 _block) external nonReentrant returns (uint256) {
        require(balances[msg.sender] > 0);
        uint256 bid_percentage = (top_bids[_block].amount * 5) / 100;
        uint256 next_bid_amount = top_bids[_block].amount + bid_percentage;
        require(balances[msg.sender] > next_bid_amount);
        balances[msg.sender] -= next_bid_amount;
        uint256 amount_to_user = top_bids[_block].amount + (bid_percentage / 2);
        uint256 amount_to_admin = bid_percentage / 2;
        balances[top_bids[_block].bider] += amount_to_user;
        balances[admin] += amount_to_admin;
        top_bids[_block].bider = payable(msg.sender);
        top_bids[_block].amount = next_bid_amount;
        lastBlockHighestBidder = msg.sender;
        bid_counts[_block] += 1;
        currentbid = next_bid_amount;
        return balances[msg.sender];
    }

    function closeBid(uint256 _block) private nonReentrant {
        blocks[_block].isBidOpen = false;
        blocks[_block].code = false;
        blocks[_block].owner = top_bids[_block].bider;
    }

    function closeVBid(uint256 _block) public nonReentrant {
        require(blocks[_block].code = false);
        if (msg.sender != blocks[_block].owner) {
            require(blocks[_block].lastbidTime - block.timestamp > 864000);
        }
        blocks[_block].isBidOpen = false;
        blocks[_block].owner = top_bids[_block].bider;
    }

    function openBid(uint256 _block) public nonReentrant {
        require(blocks[_block].code = false);
        require(blocks[_block].owner == msg.sender);
        blocks[_block].isBidOpen = true;
    }

    function getCurrentblockDetail()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            bool,
            string memory,
            address
        )
    {
        return (
            blocks[lastbn].timestamp,
            blocks[lastbn].bn,
            currentbid,
            blocks[lastbn].code,
            blocks[lastbn].isBidOpen,
            blocks[lastbn].blockType,
            blocks[lastbn].owner
        );
    }

    function getTopBid(uint256 _block)
        external
        view
        returns (
            uint256,
            uint256,
            address
        )
    {
        return (
            bid_counts[_block],
            top_bids[_block].amount,
            top_bids[_block].bider
        );
    }

    function getCurrentTopBid()
        external
        view
        returns (
            uint256,
            uint256,
            address
        )
    {
        return (
            bid_counts[lastbn],
            top_bids[lastbn].amount,
            top_bids[lastbn].bider
        );
    }

    function getMarketPlaceContent() external view returns (Block[] memory) {
        uint256 itemCount = bns.length;
        Block[] memory items = new Block[](itemCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < itemCount; i++) {
            uint256 id = bns[i];
            if (
                blocks[id].isBidOpen == true &&
                blocks[id].bn != lastbn &&
                blocks[id].owner != address(0)
            ) {
                Block storage currentItem = blocks[id];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getMyBlocks() external view returns (Block[] memory) {
        uint256 totalItemCount = bns.length;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalItemCount; i++) {
            uint256 id = bns[i];
            if (blocks[id].owner == msg.sender) {
                itemCount += 1;
            }
        }
        Block[] memory items = new Block[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            uint256 id = bns[i];
            if (
                blocks[id].owner == msg.sender &&
                blocks[id].code == false &&
                blocks[id].bn != lastbn
            ) {
                Block storage currentItem = blocks[id];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function vendorBid(uint256 _block) external returns (uint256) {
        require(balances[msg.sender] > 0);
        uint256 bid_percentage = (top_bids[_block].amount * 5) / 100;
        uint256 next_bid_amount = top_bids[_block].amount + bid_percentage;
        require(msg.sender != blocks[_block].owner);
        require(balances[msg.sender] > next_bid_amount);
        balances[msg.sender] -= next_bid_amount;
        balances[blocks[_block].owner] += top_bids[_block].amount;
        // balances[admin] += bid_percentage;
        top_bids[_block].bider = payable(msg.sender);
        top_bids[_block].amount = next_bid_amount;
        blocks[lastbn].timestamp = block.timestamp;
        bid_counts[_block] += 1;
        return balances[msg.sender];
    }

    function getERC20TotalBalance() external view returns (uint256) {
        return tokens[ERC20Address][msg.sender];
    }

    function claimReward(uint256 _block, uint256 _time) external nonReentrant {
        uint256 oneDay = 86400;
        require(msg.sender == blocks[_block].owner);
        require(_time - blocks[_block].lastClaimTime >= oneDay);
        cERC20[msg.sender] += 1000 * 10**18;
        blocks[_block].lastClaimTime = _time;
    }

    function handleBuy(uint256 _amount) private returns (bool) {
        require(
            cERC20[msg.sender] + tokens[ERC20Address][msg.sender] > _amount
        );
        _amount = _amount * (10**18);
        if (cERC20[msg.sender] <= 0) {
            tokens[ERC20Address][msg.sender] =
                tokens[ERC20Address][msg.sender] -
                _amount;
            usdtholder -= _amount;
            withdrawableUSDT += _amount;
        } else {
            uint256 _temp = tokens[ERC20Address][msg.sender];
            tokens[ERC20Address][msg.sender] =
                tokens[ERC20Address][msg.sender] +
                cERC20[msg.sender] -
                _amount;
            if (tokens[ERC20Address][msg.sender] > _temp) {
                cERC20[msg.sender] = tokens[ERC20Address][msg.sender] - _temp;
                tokens[ERC20Address][msg.sender] = _temp;
            }
            usdtholder -= _amount;
            withdrawableUSDT += _amount;
        }
        return true;
    }

    function buyGSDStone(string memory alpha, uint256 _block)
        external
        payable
        nonReentrant
    {
        require(msg.sender == blocks[_block].owner);
        if (
            keccak256(abi.encodePacked(alpha)) ==
            keccak256(abi.encodePacked("a"))
        ) {
            handleBuy(5000);
            blocks[_block].a = true;
        } else if (
            keccak256(abi.encodePacked(alpha)) ==
            keccak256(abi.encodePacked("b"))
        ) {
            handleBuy(10000);
            blocks[_block].b = true;
        } else if (
            keccak256(abi.encodePacked(alpha)) ==
            keccak256(abi.encodePacked("c"))
        ) {
            handleBuy(25000);
            blocks[_block].c = true;
        } else if (
            keccak256(abi.encodePacked(alpha)) ==
            keccak256(abi.encodePacked("d"))
        ) {
            handleBuy(45000);
            blocks[_block].d = true;
        } else if (
            keccak256(abi.encodePacked(alpha)) ==
            keccak256(abi.encodePacked("e"))
        ) {
            handleBuy(75000);
            blocks[_block].e = true;
        } else if (
            keccak256(abi.encodePacked(alpha)) ==
            keccak256(abi.encodePacked("f"))
        ) {
            handleBuy(120000);
            blocks[_block].f = true;
        } else if (
            keccak256(abi.encodePacked(alpha)) ==
            keccak256(abi.encodePacked("g"))
        ) {
            handleBuy(170000);
            blocks[_block].g = true;
        } else if (
            keccak256(abi.encodePacked(alpha)) ==
            keccak256(abi.encodePacked("h"))
        ) {
            handleBuy(220000);
            blocks[_block].h = true;
        } else if (
            keccak256(abi.encodePacked(alpha)) ==
            keccak256(abi.encodePacked("i"))
        ) {
            handleBuy(265000);
            blocks[_block].i = true;
        } else {
            revert("Stone does not exist");
        }
    }

    function getGameDetail(uint256 _block)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            bool,
            address
        )
    {
        require(msg.sender == blocks[_block].owner);
        uint256 bal = tokens[ERC20Address][msg.sender];
        return (
            blocks[_block].lastClaimTime,
            blocks[_block].bn,
            bal,
            blocks[_block].code,
            blocks[_block].isBidOpen,
            blocks[_block].owner
        );
    }

    function withdrawUsdt() external nonReentrant {
        require(tokens[ERC20Address][msg.sender] > 0);
        uint256 amount = tokens[ERC20Address][msg.sender];
        tokens[ERC20Address][msg.sender] = 0;
        usdtholder -= amount;
        usdt.transfer(msg.sender, amount);
    }

    function getGSDMainBal() external view returns (uint256) {
        return tokens[ERC20Address][msg.sender];
    }

    function getGSDClaimedBal() external view returns (uint256) {
        return cERC20[msg.sender];
    }

    function withdrawNFT(uint256 _id) external nonReentrant {
        require(blocks[_id].owner == msg.sender);
        require(!blocks[_id].isBidOpen);
        blocks[_id].owner = address(0);
        nft.safeTransferFrom(address(this), msg.sender, _id);
    }

    function depositNFT(uint256 _id) external nonReentrant {
        require(blocks[_id].owner == address(0));
        require(blocks[_id].bn == _id);
        require(blocks[_id].lastbidTime != 0);
        blocks[_id].owner = msg.sender;
        nft.transfer(msg.sender, _id);
    }

    function getStones2(uint256 _block)
        public
        view
        returns (
            bool,
            bool,
            bool,
            bool
        )
    {
        bool f = blocks[_block].f;
        bool g = blocks[_block].g;
        bool h = blocks[_block].h;
        bool i = blocks[_block].i;
        return (f, g, h, i);
    }

    function getStones1(uint256 _block)
        public
        view
        returns (
            bool,
            bool,
            bool,
            bool,
            bool
        )
    {
        bool a = blocks[_block].a;
        bool b = blocks[_block].b;
        bool c = blocks[_block].c;
        bool d = blocks[_block].d;
        bool e = blocks[_block].e;
        return (a, b, c, d, e);
    }
}
