require('dotenv').config();
const { ethers } = require('ethers');
const fs   = require('fs');
const path = require('path');

async function main() {
  const artifactPath = path.join(__dirname, '../artifacts/Bank.json');
  if (!fs.existsSync(artifactPath)) {
    console.error('❌ Run npm run compile first');
    process.exit(1);
  }

  const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
  const provider = new ethers.JsonRpcProvider(process.env.BLOCKCHAIN_RPC_URL);
  const wallet   = new ethers.Wallet(process.env.BANK_OWNER_PRIVATE_KEY, provider);

  console.log('🚀 Deploying Bank contract...');
  console.log('   From:', wallet.address);

  const factory  = new ethers.ContractFactory(artifact.abi, artifact.bytecode, wallet);
  const contract = await factory.deploy(process.env.BANK_NAME || 'MyBlockchainBank');
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log('✅ Deployed at:', address);

  let envContent = fs.readFileSync(path.join(__dirname, '../.env'), 'utf8');
  envContent = envContent.replace(/CONTRACT_ADDRESS=.*/, `CONTRACT_ADDRESS=${address}`);
  fs.writeFileSync(path.join(__dirname, '../.env'), envContent);
  console.log('📄 Address saved to .env');
}

main().catch(err => {
  console.error('❌ Deploy failed:', err.message);
  process.exit(1);
});
