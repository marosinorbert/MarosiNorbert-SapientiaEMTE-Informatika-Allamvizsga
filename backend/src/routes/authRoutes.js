const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const router = express.Router();
const pool = require('../db');
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

module.exports = router;