// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract L1Bridge {
    using ECDSA for bytes32;

    uint256 private constant MIN_BOND = 10 ether;
    uint256 private constant UNBOND_DELAY = 120 seconds; // 2 fraud periods

    IERC20 public immutable token;
    uint256 public sequenceNumber;
    mapping(address => bool) public relayers;
    mapping(address => uint256) public unbondTimestamps;
    mapping(uint256 => bytes32) public operationHashes;
    uint256 public incentiveFund;

    enum Operation { Bond, Unbond, Deposit, ChallengeFraud }

    constructor(address _token) {
        token = IERC20(_token);
    }

    function bond() external payable {
        require(msg.value >= MIN_BOND, "Insufficient bond");
        relayers[msg.sender] = true;
        _addOperation(Operation.Bond, msg.value, msg.sender);
    }

    function startUnbond() external {
        require(relayers[msg.sender], "Not a relayer");
        require(unbondTimestamps[msg.sender] == 0, "Unbond already in progress");
        unbondTimestamps[msg.sender] = block.timestamp;
        _addOperation(Operation.Unbond, 0, msg.sender);
    }

    function finalizeUnbond() external {
        require(relayers[msg.sender], "Not a relayer");
        require(unbondTimestamps[msg.sender] != 0, "Unbond not started");
        require(block.timestamp >= unbondTimestamps[msg.sender] + UNBOND_DELAY, "Unbond delay not passed");
        relayers[msg.sender] = false;
        unbondTimestamps[msg.sender] = 0;
        payable(msg.sender).transfer(MIN_BOND);
    }

    function deposit(uint256 amount, address recipient) external {
        token.transferFrom(msg.sender, address(this), amount);
        _addOperation(Operation.Deposit, amount, recipient);
    }

    function challengeFraud(uint256 seqNum, Operation operation, uint256 amount, address account, address delinquentRelayer, bytes memory signature) external {
        require(relayers[msg.sender], "Not a relayer");
        bytes32 message = keccak256(abi.encodePacked(seqNum, operation, amount, account));
        address signer = message.toEthSignedMessageHash().recover(signature);
        require(signer == delinquentRelayer, "Invalid signature");
        
        address beneficiary = account;
        uint256 slashAmount = 0;
        
        if (message == operationHashes[seqNum]) {
            // Invalid challenge, slash the challenger (msg.sender)
            if (address(this).balance >= MIN_BOND) {
                relayers[msg.sender] = false;
                slashAmount = MIN_BOND;
                beneficiary = delinquentRelayer;
            }
        } else {
            // Valid challenge, slash the delinquent relayer
            if (address(this).balance >= MIN_BOND) {
                relayers[delinquentRelayer] = false;
                slashAmount = MIN_BOND;
                beneficiary = msg.sender;
            }
        }
        
        if (slashAmount > 0) {
            uint256 beneficiaryShare = slashAmount * 3 / 4; // 75% to the beneficiary
            uint256 incentiveFundShare = slashAmount - beneficiaryShare; // 25% to the incentive fund
            
            payable(beneficiary).transfer(beneficiaryShare);
            incentiveFund += incentiveFundShare;
            
            // Distribute 10% of the incentive fund to the beneficiary
            // While the delinquent relayer is being slashed, might as well continue sending bad transactions
            uint256 incentiveDistribution = incentiveFund / 10;
            payable(beneficiary).transfer(incentiveDistribution);
            incentiveFund -= incentiveDistribution;
        }
        
        _addOperation(Operation.ChallengeFraud, amount, delinquentRelayer);
    }

    function _addOperation(Operation operation, uint256 amount, address account) private {
        bytes32 operationHash = keccak256(abi.encodePacked(operation, amount, account));
        operationHashes[sequenceNumber] = operationHash;
        sequenceNumber++;
    }
}
