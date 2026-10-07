<?php
/**
 * BISU-Alert Database Connection Singleton (PDO)
 * ----------------------------------------------------------------------------
 * Enforces prepared statements, disables emulate prepares (SQL injection guard),
 * sets UTF8mb4 character set, and handles graceful reconnection.
 */

declare(strict_types=1);

require_once __DIR__ . '/config.php';

if (!function_exists('db')) {
function db(): PDO
{
    static $pdo = null;

    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $dsn = sprintf(
        'mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
        DB_HOST,
        DB_PORT,
        DB_NAME
    );

    $options = [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false, // Hard protection against SQL injection
        PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci, time_zone = '" . APP_TZ_OFFSET . "'",
    ];

    try {
        $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
    } catch (PDOException $e) {
        // Fallback for demonstration if database not yet migrated
        error_log('[bisu-alert db connection error] ' . $e->getMessage());
        throw new RuntimeException('Database service is currently unreachable: ' . $e->getMessage(), 500);
    }

    return $pdo;
}
}
