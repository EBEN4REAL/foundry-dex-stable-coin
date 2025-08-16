
## 🏦 DecentralizedStableCoin (DSC) System

A minimal, crypto-backed, overcollateralized **stablecoin protocol**, inspired by MakerDAO — but simplified with:

* **No governance**
* **No stability fees**
* Backed solely by **ETH/WBTC-like collateral**

---

### 🔑 Main Contracts

| Contract                  | Purpose                                                |
| ------------------------- | ------------------------------------------------------ |
| `DecentralizedStableCoin` | ERC20 stablecoin token (DSC), pegged to \$1            |
| `DSCEngine`               | Core protocol logic (minting, collateral, liquidation) |

---

### ⚙️ How the System Works

```txt
+---------------------+
|  User deposits ETH   |
+-----------+---------+
            |
            v
+---------------------+    <-- Chainlink price feeds determine USD value
| Collateral stored    |
| in DSCEngine         |
+-----------+---------+
            |
            v
+---------------------+
|  User mints DSC     |   <-- Only allowed if collateral value ≥ 2× DSC minted
+-----------+---------+
            |
            v
+---------------------+
| Health Factor check |
+-----------+---------+
            |
   if < 1.0  |  if ≥1.0
  ---------- | ----------
 |LIQUIDATE  | SAFE POSITION
  ---------- | ----------
```

---

### 📌 Core Design Principles

* ✅ **Exogenous collateral** (crypto)
* ✅ **Overcollateralized (≥200%)**
* ✅ **USD-pegged**
* 🔁 **Algorithmic stability (health factor)**
* ❌ No governance token
* ❌ No borrower interest / stability fee

---

### 🚨 Liquidation Mechanism

* If a user’s **health factor < 1**, anyone can **liquidate** them:

  * Pay off their DSC debt
  * Receive their collateral **at a 10% discount**

---

### 📣 Why This Project Matters

This smart contract system demonstrates fundamental DeFi concepts such as:

* Price-oracle driven collateralization (Chainlink feeds)
* Minting/burning ERC20 stablecoins
* Health factors & overcollateralization logic
* Liquidation incentives and mechanisms
