<?php
/**
 * BISU-Alert Shared Bootstrap
 * ----------------------------------------------------------------------------
 * Response envelopes, global exception handling, input parsing helpers.
 */

declare(strict_types=1);

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/database.php';

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

/* -- Standardized API Response Envelopes ---------------------------------- */

function respond(array $payload, int $status = 200): never
{
    http_response_code($status);
    echo json_encode(
        $payload,
        JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PARTIAL_OUTPUT_ON_ERROR
    );
    exit;
}

function ok(mixed $data = null, int $status = 200): never
{
    respond(['success' => true, 'data' => $data], $status);
}

function fail(string $message, int $status = 400, string $code = 'error'): never
{
    respond([
        'success' => false,
        'error'   => ['message' => $message, 'code' => $code],
    ], $status);
}

/* -- Uncaught Crash / Exception Handling ---------------------------------- */

set_exception_handler(static function (Throwable $e): void {
    error_log('[bisu-alert fatal] ' . $e->getMessage() . ' @ ' . $e->getFile() . ':' . $e->getLine());

    $message = DEBUG_ERRORS
        ? $e->getMessage()
        : 'The server could not complete that request.';

    respond([
        'success' => false,
        'error'   => ['message' => $message, 'code' => 'server_error'],
    ], 500);
});

/* -- Request Body & Param Parsing Helpers --------------------------------- */

function method(): string
{
    return strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
}

function require_method(string ...$allowed): void
{
    if (!in_array(method(), $allowed, true)) {
        header('Allow: ' . implode(', ', $allowed));
        fail('This endpoint accepts ' . implode(' / ', $allowed) . ' only.', 405, 'method_not_allowed');
    }
}

function body(): array
{
    static $parsed = null;
    if (is_array($parsed)) {
        return $parsed;
    }

    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return $parsed = $_POST;
    }

    $decoded = json_decode($raw, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        if (!empty($_POST)) {
            return $parsed = $_POST;
        }
        fail('Request body is not valid JSON.', 400, 'malformed_body');
    }

    return $parsed = is_array($decoded) ? $decoded : [];
}

function query(string $key, ?string $default = null): ?string
{
    $value = $_GET[$key] ?? null;
    if ($value === null || !is_scalar($value)) {
        return $default;
    }
    $value = trim((string) $value);
    return $value === '' ? $default : $value;
}

function str_field(array $src, string $key, int $maxLength = 255): string
{
    $value = $src[$key] ?? null;
    if (!is_scalar($value) || trim((string) $value) === '') {
        fail(ucfirst(str_replace('_', ' ', $key)) . ' is required.', 422, 'missing_field');
    }

    $value = trim((string) $value);
    if (mb_strlen($value) > $maxLength) {
        fail(ucfirst(str_replace('_', ' ', $key)) . " must be $maxLength characters or fewer.", 422, 'field_too_long');
    }

    return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function opt_str(array $src, string $key, int $maxLength = 255): ?string
{
    $value = $src[$key] ?? null;
    if (!is_scalar($value) || trim((string) $value) === '') {
        return null;
    }

    return htmlspecialchars(mb_substr(trim((string) $value), 0, $maxLength), ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function opt_coord(array $src, string $key, float $limit): ?float
{
    $value = $src[$key] ?? null;
    if ($value === null || $value === '') {
        return null;
    }

    if (!is_numeric($value)) {
        fail(ucfirst($key) . ' must be a valid numerical coordinate.', 422, 'invalid_coordinate');
    }

    $coord = (float) $value;
    if ($coord < -$limit || $coord > $limit) {
        fail(ucfirst($key) . " must be between -$limit and $limit.", 422, 'invalid_coordinate');
    }

    return $coord;
}

function iso(?string $mysqlDateTime): ?string
{
    if ($mysqlDateTime === null || $mysqlDateTime === '') {
        return null;
    }
    return str_replace(' ', 'T', $mysqlDateTime) . APP_TZ_OFFSET;
}
