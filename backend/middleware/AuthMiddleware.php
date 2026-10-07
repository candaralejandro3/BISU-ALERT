<?php
/**
 * Authentication Middleware
 * ----------------------------------------------------------------------------
 * Validates Bearer tokens against hashed sessions in the database, verifies
 * session expiration and revocation, and attaches the active user.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

class AuthMiddleware
{
    private static ?array $currentUser = null;

    public static function getBearerToken(): ?string
    {
        $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';

        if ($header === '' && function_exists('apache_request_headers')) {
            foreach (apache_request_headers() as $name => $value) {
                if (strcasecmp($name, 'Authorization') === 0) {
                    $header = $value;
                    break;
                }
            }
        }

        if (preg_match('/^Bearer\s+(\S+)$/i', trim($header), $m) === 1) {
            return $m[1];
        }

        return null;
    }

    public static function user(): ?array
    {
        if (self::$currentUser !== null) {
            return self::$currentUser;
        }

        $token = self::getBearerToken();
        if ($token === null) {
            return null;
        }

        try {
            $stmt = db()->prepare(
                'SELECT u.id, u.full_name, u.email, u.campus_id, u.role_id,
                        r.name AS role_label, r.can_respond, r.can_publish, r.is_admin,
                        p.department, p.phone_number, p.ice_contact_name, p.ice_contact_number,
                        p.blood_type, p.allergies, p.medical_conditions
                 FROM user_sessions s
                 INNER JOIN users u ON u.id = s.user_id
                 INNER JOIN roles r ON r.id = u.role_id
                 LEFT JOIN user_profiles p ON p.user_id = u.id
                 WHERE s.token_hash = ?
                   AND s.revoked_at IS NULL
                   AND s.expires_at > NOW()
                   AND u.is_active = 1
                 LIMIT 1'
            );
            $stmt->execute([hash('sha256', $token)]);
            $row = $stmt->fetch();

            if ($row) {
                self::$currentUser = $row;
                return self::$currentUser;
            }
        } catch (Throwable $e) {
            error_log('[AuthMiddleware error] ' . $e->getMessage());
        }

        return null;
    }

    public static function authenticate(): array
    {
        $user = self::user();
        if ($user === null) {
            fail('Authentication required. Please sign in to continue.', 401, 'unauthenticated');
        }
        return $user;
    }
}
