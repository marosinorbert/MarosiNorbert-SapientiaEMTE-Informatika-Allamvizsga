const pool = require('./db');
const initDb = require('./initDb');
const express = require('express');
const cors = require('cors');
require('dotenv').config();
const sensorRoutes = require('./routes/sensorRoutes');
const app = express();
const deviceRoutes = require('./routes/deviceRoutes');

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type'],
}));
app.use(express.json());

app.use('/api/sensors', sensorRoutes);
app.use('/api/devices', deviceRoutes);

app.get('/', async (req, res) => {
  const result = await pool.query('SELECT NOW()');
  res.json({
    message: 'Smart Greenhouse API is running',
    databaseTime: result.rows[0].now,
  });
});

const PORT = process.env.PORT || 3000;

initDb();

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});