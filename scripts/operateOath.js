const pinToIPFS = require("./pin-to-ipfs.js")

require("dotenv").config()
const ALCHEMY_API_URL = process.env.ALCHEMY_API_URL
const PUBLIC_KEY = process.env.PUBLIC_KEY
const ACCOUNT_1 = process.env.ACCOUNT_1
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS

const { createAlchemyWeb3 } = require("@alch/alchemy-web3")
const web3 = createAlchemyWeb3(ALCHEMY_API_URL)

const contract = require("../artifacts/contracts/OathToMeliorism.sol/OathToMeliorism.json")
const nftContract = new web3.eth.Contract(contract.abi, CONTRACT_ADDRESS)

//E~ Pauses the program to wait for blockchain responses
function pause(time) {
  return new Promise(resolve => setTimeout(resolve, time));
}

//E~ This mints an NFT by pulling the metadata from a local file
async function mintFromFile(fileName) {
  NFTmetadata = require("../" + fileName)
  console.log("The NFT will be named: ", NFTmetadata.name)
  mintFromMetadata(NFTmetadata)
}

async function mintFromMetadata(NFTmetadata) {
  //E~ pins metadata to IPFS
  const tokenURI = pinToIPFS.pinMetadata(NFTmetadata)
  tokenURI
  .then(tokenURI => {
    console.log("The token URI is: ", tokenURI)
    mintNFT(tokenURI)
  })
}

async function mintNFT(tokenURI) {
  const nonce = web3.eth.getTransactionCount(PUBLIC_KEY, "latest") //get latest nonce
  //the transaction
  const tx = {
    from: PUBLIC_KEY,
    to: CONTRACT_ADDRESS,
    nonce: nonce,
    gas: 500000,
    data: nftContract.methods.mint(PUBLIC_KEY, tokenURI).encodeABI(),
  }

  const signPromise = web3.eth.accounts.signTransaction(tx, ACCOUNT_1)
  signPromise
    .then((signedTx) => {
      web3.eth.sendSignedTransaction(
        signedTx.rawTransaction,
        function (err, hash) {
          if (!err) {
            console.log(
              "The hash of your transaction is: ",
              hash,
              "\nCheck Alchemy's Mempool to view the status of your transaction!"
            );
            const transactionReceipt = web3.eth.getTransactionReceipt(hash);
            console.log(transactionReceipt);
          } else {
            console.log(
              "Something went wrong when submitting your transaction:",
              err
            )
          }
        }
      )
    })
    .catch((err) => {
      console.log(" Promise failed:", err)
    })
}

//mintFromFile("metadata_files/1.json");

mintNFT('https://nftstorage.link/ipfs/bafybeifidnk7srfdkgwajz55br4hotn2b3ybspdrbd25ekvwwdv2jdg2lm/4.json');

//const metadata = new Object();
//metadata.name = "Magic 8-ball";
//metadata.image = "ipfs://QmaBCfqjKAsHmy4EEA4xq3uXhC7qwpGh3WpjrB6Aq4KMpy";
//metadata.description = "See your future...now!";
//metadata.animation_url = 'ipfs://QmUwY2LbFQ7WHbVtbVDo1TVmKCL8TLWCAhCtFbcuKiGtts';
//metadata.animation_details = '{"format": "HTML"}'
//mintFromMetadata(metadata)

//mintNFT('ipfs://QmUwY2LbFQ7WHbVtbVDo1TVmKCL8TLWCAhCtFbcuKiGtts')