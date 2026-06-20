const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/authMiddleware');
const deviceMiddleware = require('../middleware/deviceMiddleware');

async function getUserDevice(req, res) {
  const result = await pool.query(
    `
    SELECT id
    FROM greenhouse_devices
    WHERE user_id = $1
    AND is_claimed = true
    ORDER BY claimed_at DESC
    LIMIT 1
    `,
    [req.user.id]
  );

  if (result.rows.length === 0) {
    res.status(404).json({
      message: 'Nincs ESP32 eszköz hozzárendelve ehhez a fiókhoz.',
    });
    return null;
  }

  return result.rows[0];
}

router.get('/status', authMiddleware, async (req, res) => {
  const device = await getUserDevice(req, res);
  if (!device) return;

  const result = await pool.query(
    `
    SELECT *,
      CASE
        WHEN last_seen >= NOW() - INTERVAL '30 seconds'
        THEN true
        ELSE false
      END AS is_online_calculated
    FROM esp32_status
    WHERE user_id = $1
    AND greenhouse_device_id = $2
    LIMIT 1
    `,
    [req.user.id, device.id]
  );

  if (result.rows.length === 0) {
    return res.json({
      isOnline: false,
      wifiConnected: false,
      mqttConnected: false,
      signalStrength: 0,
      freeRam: 0,
      totalRam: 320,
      cpuTemp: 0,
      uptimeSeconds: 0,
      ipAddress: null,
      firmwareVersion: 'v1.0.0',
      lastSeen: null,
    });
  }

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
    INSERT INTO esp32_status (
      user_id,
      greenhouse_device_id,
      is_online,
      wifi_connected,
      mqtt_connected,
      signal_strength,
      free_ram,
      total_ram,
      cpu_temp,
      uptime_seconds,
      ip_address,
      firmware_version,
      last_seen
    )
    VALUES ($1,$2,true,$3,$4,$5,$6,$7,$8,$9,$10,$11,CURRENT_TIMESTAMP)
    ON CONFLICT (greenhouse_device_id)
    DO UPDATE SET
      user_id = EXCLUDED.user_id,
      is_online = true,
      wifi_connected = EXCLUDED.wifi_connected,
      mqtt_connected = EXCLUDED.mqtt_connected,
      signal_strength = EXCLUDED.signal_strength,
      free_ram = EXCLUDED.free_ram,
      total_ram = EXCLUDED.total_ram,
      cpu_temp = EXCLUDED.cpu_temp,
      uptime_seconds = EXCLUDED.uptime_seconds,
      ip_address = EXCLUDED.ip_address,
      firmware_version = EXCLUDED.firmware_version,
      last_seen = CURRENT_TIMESTAMP
    RETURNING *
    `,
    [
      req.device.user_id,
      req.device.id,
      wifiConnected,
      mqttConnected,
      signalStrength,
      freeRam,
      totalRam,
      cpuTemp,
      uptimeSeconds,
      ipAddress,
      firmwareVersion,
    ]
  );

  res.json(result.rows[0]);
});

router.get('/commands', deviceMiddleware, async (req, res) => {
  const result = await pool.query(
    `
    SELECT device_name, is_on
    FROM device_state
    WHERE user_id = $1
    AND greenhouse_device_id = $2
    `,
    [
      req.device.user_id,
      req.device.id,
    ]
  );

  const commands = {
    pump: false,
    light: false,
    fan: false,
    heater: false,
  };

  result.rows.forEach((row) => {
    commands[row.device_name] = row.is_on;
  });

  res.json(commands);
});

module.exports = router;