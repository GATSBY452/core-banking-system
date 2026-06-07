require('dotenv').config();
const express = require('express');
const cors    = require('cors');

const app  = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

app.get('/api/v1/health', (req, res) => {
  res.json({
    success:   true,
    message:   'Blockchain Banking API is running',
    timestamp: new Date().toISOString(),
    version:   '1.0.0',
    system:    'blockchain',
    chain: {
      rpc:      process.env.BLOCKCHAIN_RPC_URL,
      contract: process.env.CONTRACT_ADDRESS || 'not deployed',
    },
  });
});

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.path} not found`,
  });
});

app.listen(PORT, () => {
  console.log('⛓️  Blockchain Banking API running on port ' + PORT);
});

module.exports = app;
