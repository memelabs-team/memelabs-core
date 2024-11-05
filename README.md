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



npx hardhat ignition deploy ./ignition/modules/MemeBuilder.ts --network bsc_testnet 
npx hardhat ignition deploy ./ignition/modules/MemeUSDT.ts --network bsc_testnet 

npx hardhat verify --network bsc_testnet 0x4337f1174e0f7A09a356BfA3fC75582cFBD35259
npx hardhat verify --network bsc_testnet 0x801380dA6041F034E929b8BC91d904A2e04E7405