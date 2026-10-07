<?php
/**
 * BISU-Alert Enterprise Configuration
 * ----------------------------------------------------------------------------
 * Central configuration with dynamic campus base URL resolution,
 * database credentials, rate limiting thresholds, and security parameters.
 */

declare(strict_types=1);

/* -- Database Connection Settings ------------------------------------------ */
define('DB_HOST', getenv('DB_HOST') ?: '127.0.0.1');
define('DB_PORT', (int) (getenv('DB_PORT') ?: 3306));
define('DB_NAME', getenv('DB_NAME') ?: 'bisu_alert26');
define('DB_USER', getenv('DB_USER') ?: 'root');
define('DB_PASS', getenv('DB_PASS') !== false ? getenv('DB_PASS') : '');

/* -- Campus Timezone & Locale ---------------------------------------------- */
const APP_TIMEZONE = 'Asia/Manila';
const APP_TZ_OFFSET = '+08:00';
date_default_timezone_set(APP_TIMEZONE);

/* -- Dynamic Host & Campus Base URL Resolution ----------------------------- */
function resolve_base_url(): string {
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') || ($_SERVER['SERVER_PORT'] ?? '') == 443 ? 'https://' : 'http://';
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $script = $_SERVER['SCRIPT_NAME'] ?? '';
    $dir = dirname(dirname($script)); // Points to /bisu-alert/backend or similar
    return rtrim($protocol . $host . $dir, '/');
}
define('APP_BASE_URL', getenv('APP_BASE_URL') ?: resolve_base_url());

/* -- Authentication & Session Security ------------------------------------- */
const TOKEN_TTL_HOURS = 720; // 30 days
const SESSION_EXPIRY_SECONDS = 720 * 3600;

/* -- Rate Limiting Thresholds (Security Protection against Flooding) ------- */
const RATE_LIMIT_SOS_MAX = 5;       // Max 5 SOS requests per 60 seconds
const RATE_LIMIT_REPORT_MAX = 10;   // Max 10 incident reports per 60 seconds
const RATE_LIMIT_WINDOW = 60;       // 60-second sliding window

/* -- File Upload Security Vault -------------------------------------------- */
define('UPLOAD_DIR', __DIR__ . '/../uploads');
const ALLOWED_UPLOAD_TYPES = [
    'image/jpeg' => 'jpg',
    'image/png'  => 'png',
    'image/webp' => 'webp',
    'video/mp4'  => 'mp4',
];
const MAX_UPLOAD_BYTES = 20 * 1024 * 1024; // 20 MB

/* -- CORS & Origins -------------------------------------------------------- */
const ALLOWED_ORIGINS = ['*'];
const DEBUG_ERRORS = true;

/* -- Database Connection --------------------------------------------------- */
if (!function_exists('db')) {
function db(): PDO {
    static $pdo = null;

    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $candidatePorts = array_unique([
        DB_PORT,
        3306,
        3307,
        3308,
        3305,
    ]);

    $lastException = null;

    foreach ($candidatePorts as $port) {
        $dsn = sprintf(
            'mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
            DB_HOST,
            $port,
            DB_NAME
        );

        try {
            $pdo = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
                PDO::ATTR_STRINGIFY_FETCHES  => false,
                PDO::ATTR_TIMEOUT            => 2,
            ]);

            $stmt = $pdo->prepare('SET time_zone = ?');
            $stmt->execute([APP_TZ_OFFSET]);

            return $pdo;
        } catch (PDOException $e) {
            $lastException = $e;
            if ($e->getCode() === 1049 || $e->getCode() === 1045) {
                break;
            }
        }
    }

    $errMsg = $lastException ? $lastException->getMessage() : 'Unknown error';
    throw new RuntimeException(
        'Cannot reach the ' . DB_NAME . ' database on ' . DB_HOST . ' (tried ports: '
        . implode(', ', $candidatePorts) . '). Is MySQL running in WAMP/XAMPP? (' . $errMsg . ')',
        0,
        $lastException
    );
}
}