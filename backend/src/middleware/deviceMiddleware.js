const pool = require('../db');

async function deviceMiddleware(req, res, next) {
    const deviceToken = req.headers['x-device-token'];

    if (!deviceToken) {
        return res.status(401).json({
            message: 'Hiányzó ESP32 device token.',
        });
    }

    try {
        const result = await pool.query(
            `
      SELECT *
      FROM greenhouse_devices
      WHERE device_token = $1
      LIMIT 1
      `,
            [deviceToken]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                message: 'Érvénytelen ESP32 device token.',
            });
        }

        const device = result.rows[0];

        if (!device.is_claimed || !device.user_id) {
            return res.status(403).json({
                message: 'Az ESP32 még nincs felhasználóhoz rendelve.',
            });
        }

        req.device = device;
        req.userIdFromDevice = device.user_id;

        next();
    } catch (e) {
        console.error(e);
        res.status(500).json({
            message: 'ESP32 azonosítási hiba.',
        });
    }
}

module.exports = deviceMiddleware;