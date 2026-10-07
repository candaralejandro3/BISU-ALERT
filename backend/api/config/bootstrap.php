<?php
/**
 * BISU-Alert API -- shared bootstrap
 * ----------------------------------------------------------------------------
 * Every endpoint starts with:
 *
 *     require_once __DIR__ . '/../config/bootstrap.php';
 *
 * which gives it CORS headers, a JSON error handler, the response envelope,
 * request-body parsing, and the bearer-token auth guard.
 *
 * Response envelope, always:
 *     { "success": true,  "data": ... }
 *     { "success": false, "error": { "message": "...", "code": "..." } }
 */

declare(strict_types=1);

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/database.php';

date_default_timezone_set(APP_TIMEZONE);

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

/* -- CORS ----------------------------------------------------------------- */

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if (in_array('*', ALLOWED_ORIGINS, true)) {
    header('Access-Control-Allow-Origin: *');
} elseif ($origin !== '' && in_array($origin, ALLOWED_ORIGINS, true)) {
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Vary: Origin');
}
header('Access-Control-Allow-Methods: GET, POST, PATCH, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Max-Age: 86400');

// Browsers preflight anything with an Authorization header. Answer and stop.
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

/* -- Response envelope ---------------------------------------------------- */

/**
 * Emit a JSON body and end the request.
 *
 * @param array<string, mixed> $payload
 */
function respond(array $payload, int $status = 200): never
{
    http_response_code($status);
    echo json_encode(
        $payload,
        JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PARTIAL_OUTPUT_ON_ERROR
    );
    exit;
}

/** Success. $data is whatever the endpoint's contract says it returns. */
function ok(mixed $data = null, int $status = 200): never
{
    respond(['success' => true, 'data' => $data], $status);
}

/**
 * Failure. $code is a stable machine-readable slug the Flutter client can
 * branch on (e.g. 'email_taken'), separate from the human-readable $message.
 */
function fail(string $message, int $status = 400, string $code = 'error'): never
{
    respond([
        'success' => false,
        'error'   => ['message' => $message, 'code' => $code],
    ], $status);
}

/* -- Crash handling ------------------------------------------------------- */

/**
 * Without this an uncaught exception returns an HTML error page, and the Flutter
 * client reports "unexpected character" instead of the real problem.
 */
set_exception_handler(static function (Throwable $e): void {
    error_log('[bisu-alert] ' . $e->getMessage() . ' @ ' . $e->getFile() . ':' . $e->getLine());

    $message = DEBUG_ERRORS
        ? $e->getMessage()
        : 'The server could not complete that request.';

    respond([
        'success' => false,
        'error'   => ['message' => $message, 'code' => 'server_error'],
    ], 500);
});

set_error_handler(static function (int $severity, string $message, string $file, int $line): bool {
    if ((error_reporting() & $severity) === 0) {
        return false;
    }
    throw new ErrorException($message, 0, $severity, $file, $line);
});

/* -- Request parsing ------------------------------------------------------ */

/** The HTTP verb, uppercased. */
function method(): string
{
    return strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
}

/** Reject anything that is not one of $allowed. */
function require_method(string ...$allowed): void
{
    if (!in_array(method(), $allowed, true)) {
        header('Allow: ' . implode(', ', $allowed));
        fail(
            'This endpoint accepts ' . implode(' / ', $allowed) . ' only.',
            405,
            'method_not_allowed'
        );
    }
}

/**
 * Decoded request body. Accepts JSON (what the Flutter client sends) and falls
 * back to form-encoded so the endpoints stay testable from a browser or Postman.
 *
 * @return array<string, mixed>
 */
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
        // Multipart uploads populate $_POST and leave php://input unreadable.
        if (!empty($_POST)) {
            return $parsed = $_POST;
        }
        fail('Request body is not valid JSON.', 400, 'malformed_body');
    }

    return $parsed = is_array($decoded) ? $decoded : [];
}

/** A query-string value, trimmed. */
function query(string $key, ?string $default = null): ?string
{
    $value = $_GET[$key] ?? null;
    if ($value === null || !is_scalar($value)) {
        return $default;
    }
    $value = trim((string) $value);

    return $value === '' ? $default : $value;
}

/**
 * Required string from the request body. Fails the request when missing, blank,
 * or longer than $maxLength -- so no endpoint has to repeat that check.
 *
 * @param array<string, mixed> $src
 */
function str_field(array $src, string $key, int $maxLength = 255): string
{
    $value = $src[$key] ?? null;
    if (!is_scalar($value) || trim((string) $value) === '') {
        fail(ucfirst(str_replace('_', ' ', $key)) . ' is required.', 422, 'missing_field');
    }

    $value = trim((string) $value);
    if (mb_strlen($value) > $maxLength) {
        fail(
            ucfirst(str_replace('_', ' ', $key)) . " must be $maxLength characters or fewer.",
            422,
            'field_too_long'
        );
    }

    return $value;
}

/**
 * Optional string. Returns null when absent or blank.
 *
 * @param array<string, mixed> $src
 */
function opt_str(array $src, string $key, int $maxLength = 255): ?string
{
    $value = $src[$key] ?? null;
    if (!is_scalar($value) || trim((string) $value) === '') {
        return null;
    }

    return mb_substr(trim((string) $value), 0, $maxLength);
}

/**
 * Boolean from the body, tolerant of JSON true, 1, "1" and "true".
 *
 * @param array<string, mixed> $src
 */
function bool_field(array $src, string $key, bool $default = false): bool
{
    if (!array_key_exists($key, $src)) {
        return $default;
    }

    return filter_var($src[$key], FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE) ?? $default;
}

/**
 * Optional coordinate. Returns null when absent, and rejects values outside the
 * valid lat/long range rather than storing nonsense.
 *
 * @param array<string, mixed> $src
 */
function opt_coord(array $src, string $key, float $limit): ?float
{
    $value = $src[$key] ?? null;
    if ($value === null || $value === '') {
        return null;
    }

    if (!is_numeric($value)) {
        fail(ucfirst($key) . ' must be a number.', 422, 'invalid_coordinate');
    }

    $coord = (float) $value;
    if ($coord < -$limit || $coord > $limit) {
        fail(ucfirst($key) . " must be between -$limit and $limit.", 422, 'invalid_coordinate');
    }

    return $coord;
}

/* -- Output shaping ------------------------------------------------------- */

/**
 * MySQL DATETIME -> ISO-8601 with the campus offset.
 *
 * The offset matters: without it Dart's DateTime.parse treats the value as the
 * phone's local time, and a device set to UTC would show every alert as 8 hours
 * in the future.
 */
function iso(?string $mysqlDateTime): ?string
{
    if ($mysqlDateTime === null || $mysqlDateTime === '') {
        return null;
    }

    return str_replace(' ', 'T', $mysqlDateTime) . APP_TZ_OFFSET;
}

/** MySQL DECIMAL/TINYINT come back as strings; make the JSON properly typed. */
function num(mixed $value): ?float
{
    return $value === null ? null : (float) $value;
}

function flag(mixed $value): bool
{
    return (bool) (int) $value;
}

/* -- Authentication ------------------------------------------------------- */

/** Raw bearer token from the Authorization header, or null. */
function bearer_token(): ?string
{
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';

    if ($header === '' && function_exists('apache_request_headers')) {
        // Some Apache configurations strip HTTP_AUTHORIZATION from $_SERVER.
        foreach (apache_request_headers() as $name => $value) {
            if (strcasecmp($name, 'Authorization') === 0) {
                $header = $value;
                break;
            }
        }
    }

    if (preg_match('/^Bearer\s+(\S+)$/i', trim($header), $m) !== 1) {
        return null;
    }

    return $m[1];
}

/**
 * Mint a session token for a user.
 *
 * Only the SHA-256 of the token is stored, so a leaked user_sessions table
 * cannot be replayed as a login.
 *
 * @return array{token: string, expires_at: string}
 */
function issue_token(int $userId): array
{
    $token     = bin2hex(random_bytes(32));
    $expiresAt = date('Y-m-d H:i:s', time() + TOKEN_TTL_HOURS * 3600);

    $stmt = db()->prepare(
        'INSERT INTO user_sessions (user_id, token_hash, user_agent, ip_address, expires_at)
         VALUES (?, ?, ?, ?, ?)'
    );
    $stmt->execute([
        $userId,
        hash('sha256', $token),
        mb_substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 255),
        $_SERVER['REMOTE_ADDR'] ?? null,
        $expiresAt,
    ]);

    return ['token' => $token, 'expires_at' => iso($expiresAt)];
}

/**
 * The signed-in user, or null when there is no usable token.
 *
 * @return array<string, mixed>|null Row from vw_user_profile.
 */
function current_user(): ?array
{
    static $user = null;
    static $resolved = false;

    if ($resolved) {
        return $user;
    }
    $resolved = true;

    $token = bearer_token();
    if ($token === null) {
        return null;
    }

    $stmt = db()->prepare(
        'SELECT p.*
         FROM user_sessions s
              INNER JOIN vw_user_profile p ON p.id = s.user_id
         WHERE s.token_hash = ?
           AND s.revoked_at IS NULL
           AND s.expires_at > NOW()
           AND p.is_active = 1
         LIMIT 1'
    );
    $stmt->execute([hash('sha256', $token)]);
    $row = $stmt->fetch();

    if ($row === false) {
        return null;
    }

    // Read by trg_incident_status_change so audit rows are attributed even when
    // the write goes through a plain UPDATE rather than a stored procedure.
    $actor = db()->prepare('SET @bisu_actor_id = ?');
    $actor->execute([(int) $row['id']]);

    return $user = $row;
}

/**
 * Same as current_user(), but ends the request with 401 when unauthenticated.
 *
 * @return array<string, mixed>
 */
function require_auth(): array
{
    $user = current_user();
    if ($user === null) {
        fail('Sign in to continue.', 401, 'unauthenticated');
    }

    return $user;
}

/**
 * Ends the request with 403 unless the signed-in user's role may act on
 * incidents (staff and security, per campus_roles.can_respond).
 *
 * @return array<string, mixed>
 */
function require_responder(): array
{
    $user = require_auth();
    if (!flag($user['can_respond'])) {
        fail(
            'Only campus responders can change an incident.',
            403,
            'not_a_responder'
        );
    }

    return $user;
}

/* -- Audit ---------------------------------------------------------------- */

/** Append a row to audit_logs. Never throws -- logging must not break a request. */
function audit(
    ?int $userId,
    string $action,
    ?string $entityType = null,
    ?string $entityId = null,
    ?string $detail = null
): void {
    try {
        $stmt = db()->prepare(
            'INSERT INTO audit_logs (user_id, action, entity_type, entity_id, detail, ip_address)
             VALUES (?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $userId,
            $action,
            $entityType,
            $entityId,
            $detail === null ? null : mb_substr($detail, 0, 255),
            $_SERVER['REMOTE_ADDR'] ?? null,
        ]);
    } catch (Throwable $e) {
        error_log('[bisu-alert] audit failed: ' . $e->getMessage());
    }
}

/* -- Shared shaping ------------------------------------------------------- */

/**
 * vw_user_profile row -> the user object every endpoint returns.
 *
 * One function so /auth/login, /auth/register, /auth/me and /users/update_profile
 * cannot drift into returning different shapes.
 *
 * @param array<string, mixed> $row
 * @return array<string, mixed>
 */
function shape_user(array $row): array
{
    return [
        'id'                              => (int) $row['id'],
        'full_name'                       => $row['full_name'],
        'email'                           => $row['email'],
        'campus_id'                       => $row['campus_id'],
        'role'                            => $row['role_code'],
        'role_label'                      => $row['role_label'],
        'can_respond'                     => flag($row['can_respond']),
        'can_publish'                     => flag($row['can_publish']),
        'department'                      => $row['department'],
        'phone_number'                    => $row['phone_number'],
        'wants_emergency_location_alerts' => flag($row['wants_emergency_location_alerts']),
        'last_login_at'                   => iso($row['last_login_at'] ?? null),
        'created_at'                      => iso($row['created_at'] ?? null),
        'medical' => [
            'ice_contact_name'   => $row['ice_contact_name'],
            'ice_contact_number' => $row['ice_contact_number'],
            'ice_relationship'   => $row['ice_relationship'],
            'blood_type'         => $row['blood_type'],
            'allergies'          => $row['allergies'],
            'medical_conditions' => $row['medical_conditions'],
        ],
    ];
}
