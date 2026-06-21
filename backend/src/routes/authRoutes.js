const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/authMiddleware');
const {
    validateEmail,
    validateName,
    validatePassword,
} = require('../utils/validation');

function createToken(user) {
    return jwt.sign(
        {
            id: user.id,
            email: user.email,
        },
        process.env.JWT_SECRET,
        {
            expiresIn: '7d',
        }
    );
}

router.post('/register', async (req, res) => {
    try {
        const { name, email, password } = req.body;

        const validationErrors = [
            validateName(name),
            validateEmail(email),
            validatePassword(password),
        ].filter(Boolean);

        if (validationErrors.length > 0) {
            return res.status(400).json({
                message: validationErrors[0],
                errors: validationErrors,
            });
        }

        const normalizedName = name.toString().trim();
        const normalizedEmail = email.toString().trim().toLowerCase();

        const existing = await pool.query(
            'SELECT id FROM users WHERE email = $1',
            [normalizedEmail]
        );

        if (existing.rows.length > 0) {
            return res.status(409).json({
                message: 'Ezzel az email címmel már létezik felhasználó.',
            });
        }

        const passwordHash = await bcrypt.hash(password, 10);

        const result = await pool.query(
            `
      INSERT INTO users (name, email, password_hash)
      VALUES ($1, $2, $3)
      RETURNING id, name, email, created_at
      `,
            [normalizedName, normalizedEmail, passwordHash]
        );

        const user = result.rows[0];
        const token = createToken(user);

        res.status(201).json({
            user,
            token,
        });
    } catch (e) {
        console.error(e);
        res.status(500).json({
            message: 'Sikertelen regisztráció.',
        });
    }
});

router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        const validationErrors = [
            validateEmail(email),
            password ? null : 'Jelszó megadása kötelező.',
        ].filter(Boolean);

        if (validationErrors.length > 0) {
            return res.status(400).json({
                message: validationErrors[0],
                errors: validationErrors,
            });
        }

        const normalizedEmail = email.toString().trim().toLowerCase();

        const result = await pool.query(
            'SELECT * FROM users WHERE email = $1',
            [normalizedEmail]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                message: 'Hibás email vagy jelszó.',
            });
        }

        const user = result.rows[0];

        const passwordOk = await bcrypt.compare(
            password,
            user.password_hash
        );

        if (!passwordOk) {
            return res.status(401).json({
                message: 'Hibás email vagy jelszó.',
            });
        }

        const token = createToken(user);

        res.json({
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                created_at: user.created_at,
            },
            token,
        });
    } catch (e) {
        console.error(e);
        res.status(500).json({
            message: 'Sikertelen bejelentkezés.',
        });
    }
});

router.put('/password', authMiddleware, async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword) {
            return res.status(400).json({
                message: 'Jelenlegi jelszó megadása kötelező.',
            });
        }

        const passwordError = validatePassword(newPassword);

        if (passwordError) {
            return res.status(400).json({
                message: passwordError,
            });
        }

        const result = await pool.query(
            `
      SELECT id, password_hash
      FROM users
      WHERE id = $1
      `,
            [req.user.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Felhasználó nem található.',
            });
        }

        const user = result.rows[0];

        const currentPasswordOk = await bcrypt.compare(
            currentPassword,
            user.password_hash
        );

        if (!currentPasswordOk) {
            return res.status(401).json({
                message: 'A jelenlegi jelszó hibás.',
            });
        }

        const newPasswordHash = await bcrypt.hash(newPassword, 10);

        await pool.query(
            `
      UPDATE users
      SET password_hash = $1
      WHERE id = $2
      `,
            [newPasswordHash, req.user.id]
        );

        res.json({
            success: true,
            message: 'A jelszó sikeresen módosítva lett.',
        });
    } catch (e) {
        console.error(e);
        res.status(500).json({
            message: 'Nem sikerült módosítani a jelszót.',
        });
    }
});

router.delete('/profile', authMiddleware, async (req, res) => {
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const devicesResult = await client.query(
            `
      SELECT id
      FROM greenhouse_devices
      WHERE user_id = $1
      `,
            [req.user.id]
        );

        const deviceIds = devicesResult.rows.map((row) => row.id);

        await client.query(
            `
      DELETE FROM sensor_data
      WHERE user_id = $1
      `,
            [req.user.id]
        );

        await client.query(
            `
      DELETE FROM device_state
      WHERE user_id = $1
      `,
            [req.user.id]
        );

        await client.query(
            `
      DELETE FROM system_settings
      WHERE user_id = $1
      `,
            [req.user.id]
        );

        await client.query(
            `
      DELETE FROM esp32_status
      WHERE user_id = $1
      `,
            [req.user.id]
        );

        await client.query(
            `
      DELETE FROM alerts
      WHERE user_id = $1
      `,
            [req.user.id]
        );

        await client.query(
            `
      DELETE FROM system_logs
      WHERE user_id = $1
      `,
            [req.user.id]
        );

        await client.query(
            `
      DELETE FROM plants
      WHERE user_id = $1
      `,
            [req.user.id]
        );

        if (deviceIds.length > 0) {
            await client.query(
                `
        UPDATE greenhouse_devices
        SET
          user_id = NULL,
          is_claimed = false,
          claimed_at = NULL
        WHERE id = ANY($1::int[])
        `,
                [deviceIds]
            );
        }

        await client.query(
            `
      DELETE FROM users
      WHERE id = $1
      `,
            [req.user.id]
        );

        await client.query('COMMIT');

        res.json({
            success: true,
            message: 'A felhasználói profil és minden hozzá tartozó adat törölve lett.',
        });
    } catch (e) {
        await client.query('ROLLBACK');
        console.error(e);

        res.status(500).json({
            message: 'Nem sikerült törölni a profilt.',
        });
    } finally {
        client.release();
    }
});

module.exports = router;