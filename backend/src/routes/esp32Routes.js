const express = require('express');
const router = express.Router();
const pool = require('../db');
const deviceMiddleware = require('../middleware/deviceMiddleware');

router.get('/status', async (req, res) => {
  const result = await pool.query(`
    SELECT *,
      CASE
        WHEN last_seen >= NOW() - INTERVAL '30 seconds'
        THEN true
        ELSE false
      END AS is_online_calculated
    FROM esp32_status
    WHERE id = 1
  `);

  const row = result.rows[0];

  res.json({
    isOnline: row.is_online_calculated,
    wifiConnected: row.wifi_connected,
    mqttConnected: row.mqtt_connected,
    signalStrength: row.signal_strength,
    freeRam: row.free_ram,
    totalRam: row.total_ram,
    cpuTemp: row.cpu_temp,
    uptimeSeconds: row.uptime_seconds,
    ipAddress: row.ip_address,
    firmwareVersion: row.firmware_version,
    lastSeen: row.last_seen,
  });
});

router.post('/heartbeat', deviceMiddleware, async (req, res) => {
  const {
    wifiConnected,
    mqttConnected,
    signalStrength,
    freeRam,
    totalRam,
    cpuTemp,
    uptimeSeconds,
    ipAddress,
    firmwareVersion,
  } = req.body;

  const result = await pool.query(
    `
  UPDATE esp32_status
  SET
    is_online = true,
    wifi_connected = $1,
    mqtt_connected = $2,
    signal_strength = $3,
    free_ram = $4,
    total_ram = $5,
    cpu_temp = $6,
    uptime_seconds = $7,
    ip_address = $8,
    firmware_version = $9,
    user_id = $10,
    greenhouse_device_id = $11,
    last_seen = CURRENT_TIMESTAMP
  WHERE id = 1
  RETURNING *
  `,
    [
      wifiConnected,
      mqttConnected,
      signalStrength,
      freeRam,
      totalRam,
      cpuTemp,
      uptimeSeconds,
      ipAddress,
      firmwareVersion,
      req.device.user_id,
      req.device.id,
    ]
  );

  res.json(result.rows[0]);
});

router.get('/commands', deviceMiddleware, async (req, res) => {
  const result = await pool.query(`
    SELECT device_name, is_on
    FROM device_state
  `);

  const commands = {
    pump: false,
    light: false,
    fan: false,
    heater: false,
  };

  result.rows.forEach(row => {
    commands[row.device_name] = row.is_on;
  });

  res.json(commands);
});

module.exports = router;