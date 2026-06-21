function isValidNumber(value) {
    return value !== null &&
        value !== undefined &&
        value !== '' &&
        !Number.isNaN(Number(value)) &&
        Number.isFinite(Number(value));
}

function toNumber(value) {
    return Number(value);
}

function validateRange(min, max, label) {
    if (!isValidNumber(min) || !isValidNumber(max)) {
        return `${label}: mindkét érték megadása kötelező.`;
    }

    if (toNumber(min) >= toNumber(max)) {
        return `${label}: a minimum értéknek kisebbnek kell lennie a maximumnál.`;
    }

    return null;
}

function validateRequiredString(value, label) {
    if (!value || value.toString().trim().length === 0) {
        return `${label} megadása kötelező.`;
    }

    return null;
}

function validateDeviceName(device) {
    const allowedDevices = ['pump', 'light', 'fan', 'heater'];

    if (!allowedDevices.includes(device)) {
        return 'Ismeretlen eszköz.';
    }

    return null;
}

function validateBoolean(value, label) {
    if (typeof value !== 'boolean') {
        return `${label}: logikai érték szükséges.`;
    }

    return null;
}

function validateClaimCode(claimCode) {
    if (!claimCode || claimCode.toString().trim().length < 4) {
        return 'Claim kód megadása kötelező.';
    }

    const normalized = claimCode.toString().trim().toUpperCase();

    const claimCodeRegex = /^[A-Z0-9-]{4,50}$/;

    if (!claimCodeRegex.test(normalized)) {
        return 'Érvénytelen claim kód formátum. Csak betű, szám és kötőjel használható.';
    }

    return null;
}

function validateTimeString(value, label) {
    if (!value || typeof value !== 'string') {
        return `${label}: időpont megadása kötelező.`;
    }

    const timeRegex = /^([01]\d|2[0-3]):([0-5]\d)(:[0-5]\d)?$/;

    if (!timeRegex.test(value)) {
        return `${label}: érvényes időformátum szükséges, például 08:00.`;
    }

    return null;
}

function validatePositiveInteger(value, label) {
    const number = Number(value);

    if (!Number.isInteger(number) || number <= 0) {
        return `${label}: érvényes pozitív egész szám szükséges.`;
    }

    return null;
}

function validateEmail(email) {
    if (!email || email.toString().trim().length === 0) {
        return 'Email cím megadása kötelező.';
    }

    const normalized = email.toString().trim();

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(normalized)) {
        return 'Érvénytelen email cím formátum.';
    }

    if (normalized.length > 150) {
        return 'Az email cím legfeljebb 150 karakter lehet.';
    }

    return null;
}

function validateName(name) {
    if (!name || name.toString().trim().length === 0) {
        return 'Név megadása kötelező.';
    }

    const normalized = name.toString().trim();

    if (normalized.length < 2) {
        return 'A név legalább 2 karakter hosszú kell legyen.';
    }

    if (normalized.length > 100) {
        return 'A név legfeljebb 100 karakter lehet.';
    }

    return null;
}

function validatePassword(password) {
    if (!password || password.length === 0) {
        return 'Jelszó megadása kötelező.';
    }

    if (password.length < 8) {
        return 'A jelszónak legalább 8 karakter hosszúnak kell lennie.';
    }

    if (!/[A-Z]/.test(password)) {
        return 'A jelszónak tartalmaznia kell legalább 1 nagybetűt.';
    }

    if (!/[a-z]/.test(password)) {
        return 'A jelszónak tartalmaznia kell legalább 1 kisbetűt.';
    }

    if (!/[0-9]/.test(password)) {
        return 'A jelszónak tartalmaznia kell legalább 1 számot.';
    }

    if (!/[^A-Za-z0-9]/.test(password)) {
        return 'A jelszónak tartalmaznia kell legalább 1 speciális karaktert.';
    }

    return null;
}

module.exports = {
    isValidNumber,
    toNumber,
    validateRange,
    validateRequiredString,
    validateDeviceName,
    validateBoolean,
    validateClaimCode,
    validateTimeString,
    validatePositiveInteger,
    validateEmail,
    validateName,
    validatePassword,
};