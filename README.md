# MemeLabs Project


Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat compile
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.ts
```


### Deployments
```
npx hardhat ignition deploy ./ignition/modules/MemeBuilder.ts --network bsc_testnet
npx hardhat ignition deploy ./ignition/modules/CommunityTreasury.ts --network bsc_testnet
npx hardhat ignition deploy ./ignition/modules/LPVault.ts --network bsc_testnet
npx hardhat ignition deploy ./ignition/modules/Vesting.ts --network bsc_testnet


npx hardhat ignition deploy ./ignition/modules/MemeUSDT.ts --network bsc_testnet
npx hardhat ignition deploy ./ignition/modules/MemeFactory.ts --network bsc_testnet
npx hardhat ignition deploy ./ignition/modules/LPVault.ts --network bsc_testnet
npx hardhat ignition deploy ./ignition/modules/MemeTestToken.ts --network bsc_testnet

npx hardhat ignition deploy ./ignition/modules/TestLP.ts --network bsc_testnet

npx hardhat verify --network bsc_testnet 0xfd876Ca6B6BD6668Cf9ef3d09cc726Eaa32f3Aa8
npx hardhat verify --network bsc_testnet 0x801380dA6041F034E929b8BC91d904A2e04E7405
npx hardhat verify --network bsc_testnet 0x9aa189e9Fb830aFAA17AAA41F8b02ff0E47A381F


```

### Testnet
| Smart Contract | Address                                    | Status   |
|----------------------------|--------------------------------------------|----------|
| MemeBuilder                | 0x9aa189e9Fb830aFAA17AAA41F8b02ff0E47A381F | Deployed |
| Memelabs USDT(mUSDT)       | 0xb26463e35841898aCae40c1724D732f268F56349 | Deployed |
| TokenVesting               | 0xcF041a47604360E448F34347eaEC7E28590D85c4 | Deployed |
| LPVault                    | 0xac529C60ACA6fcB94AfB16F289fba960883fE0D8 | Deployed |
| CommunityTreasury          | 0x439B30df7416887e86c7Bf3f4456B952872E8AEa | Deployed |
