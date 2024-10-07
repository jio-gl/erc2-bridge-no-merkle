# erc20-bridge-no-merkle
A Solidity ERC20 Bridge without Merkle Trees and Merkle Proofs, just an array and ECDSA signatures.

This bridge implementation offers a unique approach to cross-chain asset transfers, prioritizing security through its fraud challenge system and economic incentives. The use of relayers and optimistic operations allows for efficient bridging while maintaining a high level of security through economic game theory.

## Overview

This project implements a novel approach to cross-chain bridging between Layer 1 (L1) and Layer 2 (L2) networks. The system uses a unique combination of relayers, fraud proofs, and incentive mechanisms to ensure secure and efficient asset transfers between chains.

## Key Components

### L1Bridge Contract

The L1Bridge contract is deployed on the Layer 1 network and handles the following main functions:

1. **Relayer Management**
   - Relayers can bond ETH to participate in the system.
   - Unbonding process with a delay to allow for fraud challenges.

2. **Deposit Handling**
   - Users can deposit tokens to be bridged to L2.

3. **Fraud Challenge Mechanism**
   - Relayers can challenge potentially fraudulent operations.
   - Slashing mechanism for malicious actors.
   - Incentive distribution for successful challenges.

### L2Bridge Contract

The L2Bridge contract is deployed on the Layer 2 network and manages the following primary functions:

1. **Operation Updates**
   - Relayers update the state of operations from L1.
   - Fraud period implementation for each update.

2. **Minting**
   - Mints tokens on L2 after the fraud period.
   - Collects a small fee for the incentive fund.

3. **Burning**
   - Burns tokens on L2 for withdrawal to L1.

4. **Operation Finalization**
   - Finalizes operations after the fraud period.
   - Updates relayer status and distributes rewards.

## Unique Features

1. **Fraud Challenge System**
   - Allows relayers to challenge potentially fraudulent operations.
   - Implements a slashing mechanism for both false challenges and actual fraud.

2. **Incentive Structure**
   - Maintains an incentive fund on both L1 and L2.
   - Distributes rewards to honest relayers and successful challengers.

3. **Dynamic Relayer Management**
   - Relayers can join by bonding ETH.
   - Unbonding process with a delay to ensure security.

4. **Optimistic Approach**
   - Operations are considered valid after a fraud period unless challenged.

5. **Fee Structure**
   - Small fee on L2 minting to sustain the incentive fund.

## Security Considerations

1. **Fraud Period**
   - All operations have a fraud period allowing for challenges.

2. **Signature Verification**
   - Uses ECDSA for operation signing and verification.

3. **Slashing Mechanism**
   - Discourages malicious behavior by slashing bonds.

4. **Delay on Unbonding**
   - Ensures relayers can't immediately withdraw after committing fraud.

## Economic Model

1. **Relayer Incentives**
   - Rewards for updating and finalizing operations.
   - Potential to earn from successful fraud challenges.

2. **User Fees**
   - Small fee on L2 minting to maintain the system.

3. **Fraud Deterrence**
   - Economic disincentives for attempting fraudulent actions.

## Note on Withdrawal Process

The current implementation focuses on the deposit direction (L1 to L2) and the fraud challenge mechanism. The withdrawal direction (L2 to L1) is not explicitly implemented in the provided code but would follow a similar pattern:

1. User burns tokens on L2.
2. Relayer observes the burn and initiates a withdrawal on L1.
3. After a fraud period, the withdrawal can be finalized on L1.

The withdrawal process would also be subject to fraud challenges and would interact with the incentive mechanisms already in place.


