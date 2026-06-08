const express = require('express');
const cors = require('cors');
require('dotenv').config();

const sensorRoutes = require('./routes/sensorRoutes');

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/sensors', sensorRoutes);

app.get('/', (req, res) => {
  res.send('Smart Greenhouse API is running');
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});