# Escrow Contract

A clean, simple, and secure Clarity smart contract for STX escrow transactions on the Stacks blockchain.

## Overview

This escrow contract facilitates trustless transactions between a buyer and seller by holding funds in escrow until the buyer approves the transaction. The contract owner acts as a dispute resolver if needed.

## Features

- **Secure Deposits**: Buyer deposits STX into escrow
- **Approval Flow**: Buyer approves transaction before funds are released
- **Seller Claims**: Seller can claim funds only after buyer approval
- **Refund Capability**: Buyer can request refund before seller claims
- **Dispute Resolution**: Contract owner can resolve disputes by directing funds
- **Pre-Deposit Cancellation**: Buyer can cancel before depositing
- **Dynamic Configuration**: Owner can update escrow amount before deposit
- **Emergency Withdraw**: Owner has emergency withdrawal capability
- **Owner Transfer**: Owner can transfer contract ownership

## Contract State

| Variable | Type | Description |
|----------|------|-------------|
| `owner` | principal | Contract deployer with admin rights |
| `buyer` | principal | Party receiving goods/services |
| `seller` | principal | Party providing goods/services |
| `amount` | uint | STX amount in escrow |
| `approved` | bool | Whether buyer has approved the transaction |
| `deposited` | bool | Whether buyer has deposited funds |

## Public Functions

### Setup

#### `set-parties(new-buyer, new-seller, escrow-amount)`
Owner initializes the escrow with buyer, seller, and amount.

**Parameters:**
- `new-buyer` (principal): Buyer's STX address
- `new-seller` (principal): Seller's STX address
- `escrow-amount` (uint): Amount of STX in microSTX

**Returns:** `(ok true)` or error code

### Escrow Flow

#### `deposit()`
Buyer deposits the agreed amount into escrow.

**Requirements:** 
- Caller must be the buyer
- Funds have not been deposited yet
- Caller must have sufficient STX balance

**Returns:** `(ok uint)` (amount transferred) or error code

#### `approve()`
Buyer approves the transaction, allowing seller to claim funds.

**Requirements:** Caller must be the buyer

**Returns:** `(ok true)` or error code

#### `claim()`
Seller claims funds from escrow after buyer approval.

**Requirements:**
- Caller must be the seller
- Buyer must have approved the transaction
- Funds must be in escrow

**Returns:** `(ok uint)` (amount transferred) or error code

### Refund & Dispute

#### `refund()`
Buyer requests refund of escrowed funds.

**Requirements:** Caller must be the buyer

**Returns:** `(ok uint)` (amount transferred) or error code

#### `resolve-to-seller()`
Owner directs funds to seller in dispute resolution.

**Requirements:** Caller must be contract owner

**Returns:** `(ok uint)` (amount transferred) or error code

#### `resolve-to-buyer()`
Owner directs funds back to buyer in dispute resolution.

**Requirements:** Caller must be contract owner

**Returns:** `(ok uint)` (amount transferred) or error code

### Management

#### `cancel-before-deposit()`
Buyer cancels escrow before depositing funds.

**Requirements:**
- Caller must be the buyer
- Funds have not been deposited yet

**Returns:** `(ok true)` or error code

#### `update-amount(new-amount)`
Owner updates the escrow amount before deposit.

**Requirements:**
- Caller must be contract owner
- Funds have not been deposited yet
- New amount must be greater than 0

**Parameters:**
- `new-amount` (uint): New escrow amount in microSTX

**Returns:** `(ok true)` or error code

#### `emergency-withdraw(recipient)`
Owner withdraws all escrowed funds to specified recipient.

**Requirements:**
- Caller must be contract owner
- Recipient must be a valid principal

**Parameters:**
- `recipient` (principal): Recipient STX address

**Returns:** `(ok uint)` (amount transferred) or error code

#### `change-owner(new-owner)`
Transfer contract ownership to new address.

**Requirements:** Caller must be current owner

**Parameters:**
- `new-owner` (principal): New owner's STX address

**Returns:** `(ok true)` or error code

### Read-Only Functions

#### `get-info()`
Retrieve current escrow state information.

**Returns:** 
```clarity
{
  buyer: principal,
  seller: principal,
  amount: uint,
  approved: bool,
  deposited: bool
}
