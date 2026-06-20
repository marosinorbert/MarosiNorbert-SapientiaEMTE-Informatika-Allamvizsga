const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/authMiddleware');

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

    if (!claimCode) {
        return res.status(400).json({
            message: 'Claim code megadása kötelező.',
        });
    }

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
        [req.user.id, claimCode]
    );

    if (result.rows.length === 0) {
        return res.status(404).json({
            message: 'Az eszköz nem található, vagy már hozzá van rendelve más felhasználóhoz.',
        });
    }

    await pool.query(
        `
    INSERT INTO system_logs (type, title, description)
    VALUES ($1, $2, $3)
    `,
        [
            'system',
            'ESP32 eszköz hozzárendelve',
            `A(z) ${result.rows[0].device_name} eszköz hozzá lett rendelve a felhasználóhoz.`,
        ]
    );

    res.json(result.rows[0]);
});

module.exports = router;