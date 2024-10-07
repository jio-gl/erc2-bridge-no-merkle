// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract L2Bridge is ERC20, Ownable {
    using ECDSA for bytes32;

    uint256 private constant FRAUD_PERIOD = 60 seconds;
    uint256 private constant MINT_FEE_PERCENTAGE = 1; // 0.1% fee

    uint256 public sequenceNumber;
    mapping(address => bool) public relayers;
    mapping(uint256 => bytes32) public operationHashes;
    mapping(uint256 => uint256) public fraudPeriodEndTimes;
    mapping(uint256 => address) public updateRelayers;
    uint256 public incentiveFund;

    enum Operation { Bond, Unbond, Deposit, ChallengeFraud }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function updateRoot(uint256 seqNum, bytes32 newOperationHash, Operation operation, uint256 amount, address account, bytes memory signature) external {
        if (operation == Operation.Bond) {
            require(relayers[msg.sender] || owner() == msg.sender, "Not a relayer or admin");
        } else {
            require(relayers[msg.sender], "Not a relayer");
        }
        bytes32 message = keccak256(abi.encodePacked(seqNum, newOperationHash, operation, amount, account));
        address signer = message.toEthSignedMessageHash().recover(signature);
        require(relayers[signer] || owner() == signer, "Invalid signer");
        operationHashes[seqNum] = newOperationHash;
        fraudPeriodEndTimes[seqNum] = block.timestamp + FRAUD_PERIOD;
        updateRelayers[seqNum] = msg.sender;
    }

    function mint(uint256 seqNum, uint256 amount, address recipient, bytes32 operationHash, bytes memory signature) external {
        require(block.timestamp > fraudPeriodEndTimes[seqNum], "Fraud period not over");
        bytes32 message = keccak256(abi.encodePacked(seqNum, operationHashes[seqNum], operationHash));
        address signer = message.toEthSignedMessageHash().recover(signature);
        require(relayers[signer], "Invalid signer");
        require(operationHash == keccak256(abi.encodePacked(Operation.Deposit, amount, recipient)), "Invalid operationHash");

        uint256 mintFee = (amount * MINT_FEE_PERCENTAGE) / 1000;
        uint256 mintAmount = amount - mintFee;
        _mint(recipient, mintAmount);
        incentiveFund += mintFee;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        // Emit event or perform necessary actions for withdrawal in L1
    }

    function finalizeOperation(uint256 seqNum) external {
        require(block.timestamp > fraudPeriodEndTimes[seqNum], "Fraud period not over");
        bytes32 operationHash = operationHashes[seqNum];
        Operation operation = Operation(uint8(operationHash[0]));

        if (operation == Operation.Bond) {
            address account = address(uint160(uint256(operationHash)));
            relayers[account] = true;
        } else if (operation == Operation.Unbond || operation == Operation.ChallengeFraud) {
            address account = address(uint160(uint256(operationHash)));
            relayers[account] = false;
        }

        uint256 relayerReward = incentiveFund / 100;
        incentiveFund -= relayerReward;
        _mint(updateRelayers[seqNum], relayerReward);
    }
}
