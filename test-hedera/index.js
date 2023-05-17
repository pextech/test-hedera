
require("dotenv").config();
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
	NftId,
	TokenNftInfoQuery,
	TransferTransaction,
	TokenId,
	TokenAssociateTransaction,
	TransactionRecordQuery,
	TransactionId,
	TokenBurnTransaction,
	TokenWipeTransaction,
	AccountInfoQuery,
} = require("@hashgraph/sdk");
const fs = require("fs");

// 0.0.48638650      0000000000000000000000000000000002e62aba


const operatorKey = PrivateKey.fromString(process.env.PRIVATE_KEY);
const operatorId = AccountId.fromString(process.env.ACCOUNT_ID);
const client = Client.forTestnet().setOperator(operatorId, operatorKey).setMaxQueryPayment(new Hbar(2));

async function createFungibleToken() {
    const ourToken = await new TokenCreateTransaction()
	.setTokenName("CARD")
	.setTokenSymbol("C")
	.setTokenType(TokenType.FungibleCommon)
	.setDecimals(2)
	.setInitialSupply(10000)
	.setTreasuryAccountId(operatorId)
	.setAdminKey(operatorKey)
	.setSupplyKey(operatorKey)
		.freezeWith(client)
		.sign(operatorKey)

	const sumbitNFTToken = await ourToken.execute(client)
	const tokenCreateReceipt = await sumbitNFTToken.getReceipt(client)
	const tokenId = tokenCreateReceipt.tokenId
	const tokenIdSolidity = tokenId.toSolidityAddress()

	console.log("Token Id: ", tokenId.toString())
	console.log("As a sol address: ", tokenIdSolidity)
}

async function createCollection(name, symbol) {
    const ourToken = await new TokenCreateTransaction()
	.setTokenName(name)
	.setTokenSymbol(symbol)
	.setTokenType(TokenType.NonFungibleUnique)
	.setDecimals(0)
	.setInitialSupply(0)
	.setTreasuryAccountId(operatorId)
	.setAdminKey(operatorKey)
	.setSupplyKey(operatorKey)
		.freezeWith(client)
		.sign(operatorKey)

	const sumbitNFTToken = await ourToken.execute(client)
	const tokenCreateReceipt = await sumbitNFTToken.getReceipt(client)
	const tokenId = tokenCreateReceipt.tokenId
	const tokenIdSolidity = tokenId.toSolidityAddress()

	console.log("Token Id: ", tokenId.toString())
    console.log("As a sol address: ", tokenIdSolidity)
    
    return [tokenId.toString(), tokenIdSolidity]
}

async function mintNft(functionName, bytes, ipfsUrl, collectionAddress) {

   try {
    const contractMintCollectionNFT = await new ContractExecuteTransaction()
	.setContractId(ContractId.fromString(process.env.FACTORY_CONTRACT_ID))
	.setGas(3000000)
	.setFunction('mintGold', new ContractFunctionParameters().addBytesArray([Buffer.from(ipfsUrl)]).addString(ipfsUrl).addAddress(collectionAddress))
	.setMaxTransactionFee(new Hbar(2)).freezeWith(client).sign(operatorKey)

	const contractMintCollectionNFTExecute = await contractMintCollectionNFT.execute(client)
	const contractMintCollectionNFTReceipt = await contractMintCollectionNFTExecute.getReceipt(client)

	console.log("Contract mint NFT in a Collection was a ", contractMintCollectionNFTReceipt.status.toString())

	// const tokeninfo5 = await tQueryFcn(tokenId)
	// console.log("Token Supply key is: ", tokeninfo5.totalSupply.low)
   } catch (error) {
    console.log('error is', error)
   }
}


async function main() {
// await createFungibleToken()
    const [tokenId, tokenAddress] = await createCollection("GOLD TIER COLLECTION", "GTC")
    return await mintNft('mintGold','064b937f54f81739ae9bd545967f3abab', 'https://ipfs.io/ipfs/Qmf4cPi3Le8zWLrmb9EvQwzbjLAstyDJYf1mh5GnLjrgn1', tokenAddress)
}
main();