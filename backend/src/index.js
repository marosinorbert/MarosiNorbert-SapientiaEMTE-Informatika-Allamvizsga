const pool = require('./db');
const initDb = require('./initDb');
const express = require('express');
const cors = require('cors');
require('dotenv').config();
const sensorRoutes = require('./routes/sensorRoutes');
const app = express();
const deviceRoutes = require('./routes/deviceRoutes');
const settingsRoutes = require('./routes/settingsRoutes');
const esp32Routes = require('./routes/esp32Routes');
const alertRoutes = require('./routes/alertRoutes');
const logRoutes = require('./routes/logRoutes');

app.use(cors({
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: [
    'Content-Type',
    'ngrok-skip-browser-warning',
  ],
}));
app.use(express.json());

app.use('/api/sensors', sensorRoutes);
app.use('/api/devices', deviceRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/esp32', esp32Routes);
app.use('/api/alerts', alertRoutes);
app.use('/api/logs', logRoutes);

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