const {
	Client,
	AccountId,
	PrivateKey,
	ContractCreateFlow,
	AccountCreateTransaction,
	ContractCreateTransaction,
	Hbar,
} = require('@hashgraph/sdk');
const fs = require('fs');
// const { hethers } = require('@hashgraph/hethers');
require('dotenv').config();

// Get operator from .env file
const operatorKey = PrivateKey.fromString(process.env.PRIVATE_KEY);
const operatorId = AccountId.fromString(process.env.ACCOUNT_ID);

const client = Client.forTestnet().setOperator(operatorId, operatorKey);

async function contractDeployFcn(bytecode, gasLim) {
	const contractCreateTx = new ContractCreateFlow().setBytecode(bytecode).setGas(gasLim);
	const contractCreateSubmit = await contractCreateTx.execute(client);
	const contractCreateRx = await contractCreateSubmit.getReceipt(client);
	const contractId = contractCreateRx.contractId;
	const contractAddress = contractId.toSolidityAddress();
	return [contractId, contractAddress];
}

const main = async () => {

	// const json = JSON.parse(fs.readFileSync('./MuseumFactory.json'));

    // const contractBytecode = json.bytecode;
    
    const bytecode = fs.readFileSync("./factory.bin")

	console.log('\n- Deploying contract...');
	const gasLimit = 1200000;

	const [contractId, contractAddress] = await contractDeployFcn(bytecode, gasLimit);

	console.log(`Contract created with ID: ${contractId} / ${contractAddress}`);

};

main()
	.then(() => process.exit(0))
	.catch(error => {
		console.error(error);
		process.exit(1);
	});