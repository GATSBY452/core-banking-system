const solc = require('solc');
const fs   = require('fs');
const path = require('path');

const contractPath = path.join(__dirname, '../contracts/Bank.sol');

if (!fs.existsSync(contractPath)) {
  console.log('⚠️  Bank.sol not found — add it to contracts/');
  process.exit(0);
}

const src   = fs.readFileSync(contractPath, 'utf8');
const input = {
  language: 'Solidity',
  sources:  { 'Bank.sol': { content: src } },
  settings: {
    outputSelection: { '*': { '*': ['abi', 'evm.bytecode'] } },
    optimizer: { enabled: true, runs: 200 }
  }
};

const out = JSON.parse(solc.compile(JSON.stringify(input)));

if (out.errors) {
  out.errors.forEach(e => {
    if (e.severity === 'error') console.error(e.formattedMessage);
  });
  if (out.errors.some(e => e.severity === 'error')) process.exit(1);
}

fs.mkdirSync(path.join(__dirname, '../artifacts'), { recursive: true });
fs.writeFileSync(
  path.join(__dirname, '../artifacts/Bank.json'),
  JSON.stringify({
    abi:      out.contracts['Bank.sol']['Bank'].abi,
    bytecode: out.contracts['Bank.sol']['Bank'].evm.bytecode.object
  }, null, 2)
);

console.log('✅ Bank.sol compiled successfully');
