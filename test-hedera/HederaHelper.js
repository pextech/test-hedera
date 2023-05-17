const {
  Client,
  AccountId,
  PrivateKey,
  TokenInfoQuery,
  AccountBalanceQuery,
  TokenCreateTransaction,
  FileCreateTransaction,
  FileAppendTransaction,
  Hbar,
  ContractCreateTransaction,
  ContractFunctionParameters,
  TokenUpdateTransaction,
  ContractExecuteTransaction,
  AccountCreateTransaction,
  TokenSupplyType,
  TokenType,
  ContractId,
  ContractCallQuery,
} = require('@hashgraph/sdk');
const fs = require('fs');
const Web3 = require('web3');
const Contract = require('./src/contracts/artifacts/testNFT.json');
require('dotenv').config();

const operatorKey = PrivateKey.fromString(process.env.PRIVATE_KEY);
const operatorId = AccountId.fromString(process.env.ACCOUNT_ID);


const web3 = new Web3();
const client = Client.forTestnet().setOperator(operatorId, operatorKey);
let abi

abi = Contract.abi;

async function main() {

  function encodeFunctionCall(functionName, parameters) {
    const functionAbi = abi.find(
      (func) => func.name === functionName && func.type === 'function',
    );
    const encodedParametersHex = web3.eth.abi
      .encodeFunctionCall(functionAbi, parameters)
      .slice(2);
    return Buffer.from(encodedParametersHex, 'hex');
  }

  function decodeFunctionResult(functionName, resultAsBytes) {
    const functionAbi = abi.find((func) => func.name === functionName);
    const functionParameters = functionAbi.outputs;
    const resultHex = '0x'.concat(Buffer.from(resultAsBytes).toString('hex'));
    const result = web3.eth.abi.decodeParameters(functionParameters, resultHex);
    return result;
  }

  async function getSetting(fcnName) {
    const functionCallAsUint8Array = await encodeFunctionCall(fcnName, []);
    const contractCall = await new ContractCallQuery()
      .setContractId(ContractId.fromString(process.env.FACTORY_CONTRACT_ID))
      .setFunctionParameters(functionCallAsUint8Array)
      .setMaxQueryPayment(new Hbar(2))
      .setGas(100000)
      .execute(client);
    const queryResult = await decodeFunctionResult(fcnName, contractCall.bytes);
    return queryResult['0'];
  }

  const Museum = await getSetting('collectionCount');

  console.log(Museum);

  return Museum;
}

main()