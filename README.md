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
npx hardhat ignition deploy ./ignition/modules/MemeUSDT.ts --network bsc_testnet 
npx hardhat ignition deploy ./ignition/modules/MemeFactory.ts --network bsc_testnet
npx hardhat ignition deploy ./ignition/modules/LPVault.ts --network bsc_testnet
npx hardhat ignition deploy ./ignition/modules/MemeTestToken.ts --network bsc_testnet


npx hardhat verify --network bsc_testnet 0x4337f1174e0f7A09a356BfA3fC75582cFBD35259
npx hardhat verify --network bsc_testnet 0x801380dA6041F034E929b8BC91d904A2e04E7405
npx hardhat verify --network bsc_testnet 0x2ee2Ef059AE644d8E982428317EA0DD756E2eCfe
```

### Testnet
| Smart Contract | Address                                    | Status   |
|----------------------------|--------------------------------------------|----------|
| MemeBuilder                | 0xf47f56A933eD6F9A7A195121d2c0aFCA845B1629 | Deployed |
| Memelabs USDT(mUSDT)       | 0xb26463e35841898aCae40c1724D732f268F56349 | Deployed |
| LPVault                    | 0x5fE287Cb757cFD7150A5B3A9f4c2a3bf95E613a9 | Deployed |
