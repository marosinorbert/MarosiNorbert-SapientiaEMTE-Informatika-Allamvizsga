const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/authMiddleware');
const {
    validateClaimCode,
    validatePositiveInteger,
} = require('../utils/validation');

router.get('/', authMiddleware, async (req, res) => {
    const result = await pool.query(
        `
    SELECT id, device_name, claim_code, is_claimed, created_at, claimed_at
    FROM greenhouse_devices
    WHERE user_id = $1
    ORDER BY created_at DESC
    `,
        [req.user.id]
    );

    res.json(result.rows);
});

router.post('/claim', authMiddleware, async (req, res) => {
    const { claimCode } = req.body;

    const claimCodeError = validateClaimCode(claimCode);

    if (claimCodeError) {
        return res.status(400).json({
            message: claimCodeError,
        });
    }

    const normalizedClaimCode = claimCode.toString().trim().toUpperCase();

    const result = await pool.query(
        `
    UPDATE greenhouse_devices
    SET
      user_id = $1,
      is_claimed = true,
      claimed_at = CURRENT_TIMESTAMP
    WHERE claim_code = $2
    AND is_claimed = false
    RETURNING id, device_name, claim_code, is_claimed, claimed_at
    `,
        [req.user.id, normalizedClaimCode]
    );

    if (result.rows.length === 0) {
        return res.status(404).json({
            message: 'Az eszköz nem található, vagy már hozzá van rendelve más felhasználóhoz.',
        });
    }

    const claimedDevice = result.rows[0];

    await pool.query(
        `
  INSERT INTO device_state (
    user_id,
    greenhouse_device_id,
    device_name,
    is_on,
    is_auto,
    schedule_enabled,
    schedule_on,
    schedule_off
  )
  VALUES
    ($1, $2, 'pump', false, true, true, '08:00', '08:30'),
    ($1, $2, 'light', false, true, true, '06:00', '20:00'),
    ($1, $2, 'fan', false, true, true, '07:00', '21:00'),
    ($1, $2, 'heater', false, true, true, '05:00', '09:00')
  ON CONFLICT (user_id, greenhouse_device_id, device_name) DO NOTHING
  `,
        [
            req.user.id,
            claimedDevice.id,
        ]
    );

    await pool.query(
        `
  INSERT INTO system_logs (
    user_id,
    greenhouse_device_id,
    type,
    title,
    description
  )
  VALUES ($1, $2, $3, $4, $5)
  `,
        [
            req.user.id,
            claimedDevice.id,
            'system',
            'ESP32 eszköz hozzárendelve',
            `A(z) ${claimedDevice.device_name} eszköz hozzá lett rendelve a felhasználóhoz.`,
        ]
    );

    res.json(claimedDevice);
});

router.delete('/:id', authMiddleware, async (req, res) => {
    const { id } = req.params;
    const idError = validatePositiveInteger(id, 'ESP32 eszköz azonosító');

    if (idError) {
        return res.status(400).json({
            message: idError,
        });
    }

    const deviceResult = await pool.query(
        `
        SELECT id, device_name
        FROM greenhouse_devices
        WHERE id = $1
        AND user_id = $2
        AND is_claimed = true
        `,
        [id, req.user.id]
    );

    if (deviceResult.rows.length === 0) {
        return res.status(404).json({
            message: 'Az ESP32 eszköz nem található ennél a felhasználónál.',
        });
    }

    const device = deviceResult.rows[0];

    await pool.query(
        `
        DELETE FROM device_state
        WHERE user_id = $1
        AND greenhouse_device_id = $2
        `,
        [req.user.id, device.id]
    );

    await pool.query(
        `
        DELETE FROM esp32_status
        WHERE user_id = $1
        AND greenhouse_device_id = $2
        `,
        [req.user.id, device.id]
    );

    await pool.query(
        `
        UPDATE greenhouse_devices
        SET
            user_id = NULL,
            is_claimed = false,
            claimed_at = NULL
        WHERE id = $1
        AND user_id = $2
        `,
        [device.id, req.user.id]
    );

    await pool.query(
        `
        INSERT INTO system_logs (
            user_id,
            greenhouse_device_id,
            type,
            title,
            description
        )
        VALUES ($1, $2, $3, $4, $5)
        `,
        [
            req.user.id,
            null,
            'system',
            'ESP32 eszköz leválasztva',
            `A(z) ${device.device_name} eszköz le lett választva a felhasználói fiókról.`,
        ]
    );

    res.json({
        success: true,
        message: 'Az ESP32 eszköz sikeresen le lett választva.',
    });
});

module.exports = router;