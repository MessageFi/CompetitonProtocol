# Competition protocol

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```
# Secret ballot

generate proof:
```shell
cd zokrates
# install zokrates
curl -LSfs get.zokrat.es | sh
# compile
zokrates compile -i proof.zok
# compute 3 is a member of array [1, 2, 3, 4]
zokrates compute-witness -a 1 2 3 4 3
# generate proof
zokrates generate-proof
# generate verifier contract
zokrates export-verifier
zokrates verify
```