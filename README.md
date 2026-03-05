
## Deployment

### Environment variables

Environment variables are loaded from `.env` (see `.env.example` for a commented template):

- **PK**: Deployer / permissions executor private key (Account A), used by `forge script`.
- **RPC_URL**: RPC endpoint for the target network.
- **ADMIN**: Business admin address (Account B). This will become:
  - Admin of `FeeModule`
  - Admin of `CTFExchange`
- **EXCHANGE**: `CTFExchange` contract address.
- **NR_CTF_EXCHANGE / NR_CTF_ADAPTER / CTF**: Addresses used by the NegRisk fee module deployment script.

### Using Foundry script (`DeployFeeModule.s.sol`)

The recommended way to deploy is via the Foundry script, without using `.sh` scripts:

```bash
source .env

forge script src/scripts/deploy/DeployFeeModule.s.sol:DeployFeeModule \
  --rpc-url "$RPC_URL" \
  --private-key "$PK" \
  --broadcast \
  -s "run(address,address)" "$ADMIN" "$EXCHANGE"
```

This single script performs both deployment and role configuration, following section 2.2.5 of `Polymarket流程跑通.pdf`:

- **On `FeeModule`**
  - Deploys `FeeModule(EXCHANGE)`.
  - Calls `FeeModule.addAdmin(ADMIN)` to grant admin to Account B.
  - Calls `FeeModule.renounceAdmin()` so the deployer (Account A) renounces admin.

- **On `CTFExchange`**
  - Calls `CTFExchange.addOperator(FeeModule)` to set `FeeModule` as operator.
  - Calls `CTFExchange.addAdmin(ADMIN)` to set Account B as admin.

After running the script:

- `CTFExchange`:
  - Operator: `FeeModule` address.
  - Admin: Account B (`ADMIN`).
- `FeeModule`:
  - Admin: Account B (`ADMIN`).
  - Deployer (Account A) is no longer admin.
# Polymarket CTF Exchange Fee Module

The `FeeModule` contract proxies the `Exchange`'s `matchOrders` function and refunds orders' fees if they are charged more than the operator's intent.


## Functions

The contract exposes a single main entry point:

```[solidity]
function matchOrders(
    Order memory takerOrder,
    Order[] memory makerOrders,
    uint256 takerFillAmount,
    uint256[] memory makerFillAmounts,
    uint256 takerFeeAmount,
    uint256[] memory makerFeeAmounts
) external;
```
