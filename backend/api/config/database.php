<?php
/**
 * BISU-Alert API -- PDO connection factory
 * ----------------------------------------------------------------------------
 * One connection per request, handed out by db(). Every query in this API goes
 * through a prepared statement on this handle; nothing builds SQL by string
 * concatenation.
 *
 * Automatically attempts fallback ports (3306, 3307, 3308, 3305) if the primary
 * port is unreachable.
 */

declare(strict_types=1);

require_once __DIR__ . '/config.php';

if (!function_exists('db')) {
/**
 * Shared PDO handle for the current request.
 *
 * @throws RuntimeException when the database is unreachable.
 */
function db(): PDO
{
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
                // Real prepared statements
                PDO::ATTR_EMULATE_PREPARES   => false,
                PDO::ATTR_STRINGIFY_FETCHES  => false,
                PDO::ATTR_TIMEOUT            => 2,
            ]);

            // Pinned time zone
            $stmt = $pdo->prepare('SET time_zone = ?');
            $stmt->execute([APP_TZ_OFFSET]);

            return $pdo;
        } catch (PDOException $e) {
            $lastException = $e;
            // If the error was wrong credentials or unknown database, don't keep trying other ports
            if ($e->getCode() === 1049 || $e->getCode() === 1045) {
                break;
            }
        }
    }

    $errMsg = $lastException ? $lastException->getMessage() : 'Unknown error';
    throw new RuntimeException(
        'Cannot reach the ' . DB_NAME . ' database on ' . DB_HOST . ' (tried ports: '
        . implode(', ', $candidatePorts) . '). Is MySQL running in WAMP/XAMPP, '
        . 'and has 01_schema.sql been imported? (' . $errMsg . ')',
        0,
        $lastException
    );
}
}
