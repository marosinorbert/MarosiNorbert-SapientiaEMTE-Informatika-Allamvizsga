const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({
    temperature: 24.5,
    humidity: 60,
    soilMoisture: 42,
    light: true,
    pump: false,
  });
});

module.exports = router;