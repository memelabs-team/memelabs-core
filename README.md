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
npx hardhat ignition deploy ./ignition/modules/Vesting.ts --network bsc_testnet
npx hardhat ignition deploy ./ignition/modules/TestLP.ts --network bsc_testnet

npx hardhat verify --network bsc_testnet 0x0B76F788c3fcf0352b07275B20B39932912765A4
npx hardhat verify --network bsc_testnet 0x801380dA6041F034E929b8BC91d904A2e04E7405
npx hardhat verify --network bsc_testnet 0x00d9c12CE07316F59EE7986d2D08a63D1f3F95c1


```

### Testnet
| Smart Contract | Address                                    | Status   |
|----------------------------|--------------------------------------------|----------|
| MemeBuilder                | 0xf47f56A933eD6F9A7A195121d2c0aFCA845B1629 | Deployed |
| Memelabs USDT(mUSDT)       | 0xb26463e35841898aCae40c1724D732f268F56349 | Deployed |
| LPVault                    | 0x5fE287Cb757cFD7150A5B3A9f4c2a3bf95E613a9 | Deployed |
