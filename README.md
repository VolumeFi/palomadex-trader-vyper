# Palomadex Trader Smart Contract

## Overview

The Palomadex Trader is a Vyper smart contract that facilitates cross-chain token trading and liquidity operations through the Paloma network. The contract acts as a bridge between different blockchain networks, allowing users to purchase tokens, add/remove liquidity, and manage cross-chain operations.

**Contract Version:** 0.4.0  
**EVM Version:** Cancun  
**License:** Apache 2.0  
**Author:** Volume.finance

## Contract Architecture

### Key Components

- **Compass Interface**: Handles cross-chain token transfers via Paloma
- **ERC20 Interface**: Standard token operations
- **Fee Management**: Gas fees and service fees for operations
- **Access Control**: Paloma-based authorization system

### State Variables

```vyper
compass: public(address)                    # Paloma compass contract address
refund_wallet: public(address)             # Wallet receiving gas fees
gas_fee: public(uint256)                   # Gas fee amount in wei
service_fee_collector: public(address)     # Service fee recipient
service_fee: public(uint256)               # Service fee percentage (1e18 = 100%)
paloma: public(bytes32)                    # Paloma identifier
send_nonces: public(HashMap[uint256, bool]) # Nonce tracking for send operations
```

## Function Documentation

### Constructor

#### `__init__(_compass: address, _refund_wallet: address, _gas_fee: uint256, _service_fee_collector: address, _service_fee: uint256)`

**Purpose:** Initializes the contract with configuration parameters.

**Parameters:**
- `_compass`: Address of the Paloma compass contract
- `_refund_wallet`: Address that receives gas fees
- `_gas_fee`: Gas fee amount in wei
- `_service_fee_collector`: Address that receives service fees
- `_service_fee`: Service fee percentage (scaled by 1e18)

**Security Considerations:**
- All parameters are validated during deployment
- Events are emitted for all initial values
- No reentrancy protection needed (constructor)

**Example Usage:**
```python
# Deployment script example
trader = project.trader.deploy(
    compass="0x71956340a586db3afD10C2645Dbe8d065dD79AC8",
    refund_wallet="0x6dc0A87638CD75Cc700cCdB226c7ab6C054bc70b",
    gas_fee=3 * 10**15,  # 0.003 ETH
    service_fee_collector="0x9cf40152d7fb47dff8ad199282b002ca312ec818",
    service_fee=10**16,  # 1%
    sender=deployer_account
)
```

### Core Trading Functions

#### `purchase(from_token: address, to_token: address, amount: uint256)`

**Purpose:** Initiates a cross-chain token purchase operation.

**Parameters:**
- `from_token`: Source token address
- `to_token`: Destination token address  
- `amount`: Amount of source tokens to trade

**Function Flow:**
1. Validates input parameters (non-zero addresses and amount)
2. Handles gas fee collection from msg.value
3. Transfers tokens from user to contract
4. Calculates and deducts service fee
5. Approves compass contract to spend tokens
6. Sends tokens to Paloma via compass
7. Emits Purchase event

**Security Features:**
- `@nonreentrant` protection against reentrancy attacks
- Input validation for all parameters
- Safe token transfer operations
- Gas fee refund mechanism

**Example Usage:**
```python
# Purchase 100 USDC for ETH
trader.purchase(
    from_token="0xA0b86a33E6441b8c4C8C8C8C8C8C8C8C8C8C8C8C8",  # USDC
    to_token="0x0000000000000000000000000000000000000000",     # ETH
    amount=100 * 10**6,  # 100 USDC (6 decimals)
    value=0.01 * 10**18,  # 0.01 ETH for gas fee
    sender=user_account
)
```

#### `add_liquidity(token0: address, token1: address, amount0: uint256, amount1: uint256)`

**Purpose:** Adds liquidity to a cross-chain liquidity pool.

**Parameters:**
- `token0`: First token address
- `token1`: Second token address
- `amount0`: Amount of token0 to add
- `amount1`: Amount of token1 to add

**Function Flow:**
1. Validates token addresses and amounts
2. Handles gas fee collection
3. Transfers tokens from user to contract
4. Approves compass for both tokens
5. Sends tokens to Paloma via compass
6. Emits AddLiquidity event

**Security Features:**
- `@nonreentrant` protection
- Prevents adding same token as both token0 and token1
- Requires at least one token amount > 0
- Safe token operations

**Example Usage:**
```python
# Add 1000 USDC and 0.5 ETH to liquidity pool
trader.add_liquidity(
    token0="0xA0b86a33E6441b8c4C8C8C8C8C8C8C8C8C8C8C8C8",  # USDC
    token1="0x0000000000000000000000000000000000000000",     # ETH
    amount0=1000 * 10**6,  # 1000 USDC
    amount1=0.5 * 10**18,  # 0.5 ETH
    value=0.01 * 10**18,   # Gas fee
    sender=user_account
)
```

#### `remove_liquidity(token0: address, token1: address, amount: uint256)`

**Purpose:** Initiates liquidity removal from a cross-chain pool.

**Parameters:**
- `token0`: First token address
- `token1`: Second token address
- `amount`: Liquidity amount to remove

**Function Flow:**
1. Handles gas fee collection
2. Emits RemoveLiquidity event
3. Actual token transfer handled by Paloma system

**Security Features:**
- `@nonreentrant` protection
- Gas fee handling
- Event logging for tracking

**Example Usage:**
```python
# Remove liquidity from USDC/ETH pool
trader.remove_liquidity(
    token0="0xA0b86a33E6441b8c4C8C8C8C8C8C8C8C8C8C8C8C8",  # USDC
    token1="0x0000000000000000000000000000000000000000",     # ETH
    amount=100 * 10**18,  # 100 LP tokens
    value=0.01 * 10**18,  # Gas fee
    sender=user_account
)
```

### Cross-Chain Token Transfer

#### `send_token(tokens: DynArray[address, 64], to: address, amounts: DynArray[uint256, 64], nonce: uint256)`

**Purpose:** Executes cross-chain token transfers initiated by Paloma.

**Parameters:**
- `tokens`: Array of token addresses (max 64)
- `to`: Recipient address
- `amounts`: Array of token amounts
- `nonce`: Unique identifier to prevent replay attacks

**Function Flow:**
1. Validates caller is compass contract
2. Validates Paloma identifier
3. Checks nonce hasn't been used
4. Validates arrays have same length
5. Transfers tokens or ETH to recipient
6. Marks nonce as used
7. Emits TokenSent events

**Security Features:**
- `@nonreentrant` protection
- Paloma authorization check
- Nonce replay protection
- Array length validation
- Safe token transfers

**Example Usage:**
```python
# Called by compass contract after Paloma validation
trader.send_token(
    tokens=["0xA0b86a33E6441b8c4C8C8C8C8C8C8C8C8C8C8C8C8"],  # USDC
    to="0x1234567890123456789012345678901234567890",
    amounts=[100 * 10**6],  # 100 USDC
    nonce=12345,
    sender=compass_contract
)
```

### Paloma Integration Functions

#### `deposit(token: String[128], amount: uint256)`

**Purpose:** Logs token deposits to Paloma system.

**Parameters:**
- `token`: Token identifier string
- `amount`: Deposit amount

**Security Features:**
- Input validation for token string and amount
- Event logging only (no actual token transfer)

#### `withdraw(token: String[128], amount: uint256)`

**Purpose:** Logs token withdrawals from Paloma system.

**Parameters:**
- `token`: Token identifier string
- `amount`: Withdrawal amount

**Security Features:**
- Input validation
- Event logging only

#### `claim_reward(token: String[128])`

**Purpose:** Logs reward claims from Paloma system.

**Parameters:**
- `token`: Token identifier string

**Security Features:**
- Input validation
- Event logging only

### Lock Management Functions

#### `create_lock(end_lock_time: uint256, amount: uint256)`

**Purpose:** Creates a time-locked position.

**Parameters:**
- `end_lock_time`: Lock expiration timestamp
- `amount`: Locked amount

**Security Features:**
- Validates lock time is in future
- Validates amount > 0

#### `increase_lock_amount(amount: uint256)`

**Purpose:** Increases locked amount.

**Parameters:**
- `amount`: Additional amount to lock

**Security Features:**
- Validates amount > 0

#### `increase_end_lock_time(end_lock_time: uint256)`

**Purpose:** Extends lock duration.

**Parameters:**
- `end_lock_time`: New lock expiration timestamp

**Security Features:**
- Validates new time is in future

#### `withdraw_lock()`

**Purpose:** Withdraws from locked position.

**Security Features:**
- Event logging only

### Administrative Functions

#### `update_compass(new_compass: address)`

**Purpose:** Updates the compass contract address.

**Parameters:**
- `new_compass`: New compass contract address

**Security Features:**
- Only callable by current compass
- Checks SLC switch status
- Event logging

#### `set_paloma()`

**Purpose:** Sets the Paloma identifier.

**Security Features:**
- Only callable by compass when paloma is empty
- Validates message data length
- One-time operation

#### `update_refund_wallet(new_refund_wallet: address)`

**Purpose:** Updates the refund wallet address.

**Parameters:**
- `new_refund_wallet`: New refund wallet address

**Security Features:**
- Paloma authorization required
- Event logging

#### `update_gas_fee(new_gas_fee: uint256)`

**Purpose:** Updates the gas fee amount.

**Parameters:**
- `new_gas_fee`: New gas fee in wei

**Security Features:**
- Paloma authorization required
- Event logging

#### `update_service_fee_collector(new_service_fee_collector: address)`

**Purpose:** Updates the service fee collector address.

**Parameters:**
- `new_service_fee_collector`: New collector address

**Security Features:**
- Paloma authorization required
- Event logging

#### `update_service_fee(new_service_fee: uint256)`

**Purpose:** Updates the service fee percentage.

**Parameters:**
- `new_service_fee`: New service fee (scaled by 1e18)

**Security Features:**
- Paloma authorization required
- Validates fee < 100% (1e18)
- Event logging

### Internal Helper Functions

#### `_safe_approve(_token: address, _to: address, _value: uint256)`

**Purpose:** Safely approves token spending.

**Security Features:**
- External call validation
- Revert on failure

#### `_safe_transfer(_token: address, _to: address, _value: uint256)`

**Purpose:** Safely transfers tokens.

**Security Features:**
- External call validation
- Revert on failure

#### `_safe_transfer_from(_token: address, _from: address, _to: address, _value: uint256)`

**Purpose:** Safely transfers tokens from another address.

**Security Features:**
- External call validation
- Revert on failure

#### `_paloma_check()`

**Purpose:** Validates Paloma authorization.

**Security Features:**
- Checks caller is compass
- Validates Paloma identifier from message data

## Security Considerations

### Access Control
- **Compass Authorization**: Critical functions require compass contract authorization
- **Paloma Validation**: Cross-chain operations validated via Paloma identifier
- **Nonce Protection**: Replay attack prevention via nonce tracking

### Reentrancy Protection
- All external functions marked with `@nonreentrant`
- Safe external calls with validation

### Input Validation
- Address validation (non-zero addresses)
- Amount validation (positive values)
- Array length validation
- Time validation (future timestamps)

### Fee Management
- Gas fees collected and sent to refund wallet
- Service fees calculated and sent to collector
- Fee percentages validated against maximum (100%)

### Token Safety
- Safe ERC20 operations with revert on failure
- Balance checks before and after transfers
- Proper approval management

### Event Logging
- Comprehensive event emission for all operations
- Indexed parameters for efficient filtering
- Audit trail for all state changes

## Deployment Configuration

### Network-Specific Parameters

**Ethereum:**
- Gas Fee: 0.003 ETH
- Service Fee: 1%

**Polygon:**
- Gas Fee: 0.1 MATIC
- Service Fee: 1%

### Common Parameters
- Service Fee Collector: `0x9cf40152d7fb47dff8ad199282b002ca312ec818`
- Refund Wallet: `0x6dc0A87638CD75Cc700cCdB226c7ab6C054bc70b`

## Testing Recommendations

1. **Unit Tests**: Test each function with valid and invalid inputs
2. **Integration Tests**: Test cross-chain operations end-to-end
3. **Security Tests**: Test reentrancy, access control, and edge cases
4. **Gas Tests**: Verify gas usage optimization
5. **Event Tests**: Verify all events are emitted correctly

## Audit Checklist

- [ ] Access control validation
- [ ] Reentrancy protection
- [ ] Input validation
- [ ] Fee calculation accuracy
- [ ] Token transfer safety
- [ ] Event emission completeness
- [ ] Nonce replay protection
- [ ] Paloma integration security
- [ ] Gas optimization
- [ ] Error handling 