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
        return 'Érvénytelen claim kód.';
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

module.exports = {
    isValidNumber,
    toNumber,
    validateRange,
    validateRequiredString,
    validateDeviceName,
    validateBoolean,
    validateClaimCode,
    validateTimeString,
};