<?php
/**
 * AuthController
 * ----------------------------------------------------------------------------
 * Handles authentication, registration, session management, profile updating,
 * password changing, and account termination.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/../models/User.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';

class AuthController
{
    public static function login(): never
    {
        require_method('POST');
        $b = body();
        $email = str_field($b, 'email', 160);
        $password = str_field($b, 'password', 128);

        $session = User::login($email, $password);
        ok($session);
    }

    public static function register(): never
    {
        require_method('POST');
        $b = body();

        $session = User::register([
            'full_name'    => str_field($b, 'full_name', 120),
            'email'        => str_field($b, 'email', 160),
            'password'     => str_field($b, 'password', 128),
            'campus_id'    => str_field($b, 'campus_id', 40),
            'department'   => opt_str($b, 'department', 120) ?? 'General',
            'phone_number' => opt_str($b, 'phone_number', 30) ?? '',
            'role_id'      => opt_str($b, 'role_code', 30) ?? 'student',
        ]);

        ok($session, 201);
    }

    public static function me(): never
    {
        require_method('GET');
        $user = AuthMiddleware::authenticate();
        $profile = User::findById((int)$user['id']);
        ok(User::formatUser($profile));
    }

    public static function updateProfile(): never
    {
        require_method('POST', 'PATCH');
        $user = AuthMiddleware::authenticate();
        $b = body();

        $updated = User::updateProfile((int)$user['id'], [
            'campus_id'                       => opt_str($b, 'campus_id', 40),
            'department'                      => opt_str($b, 'department', 120),
            'phone_number'                    => opt_str($b, 'phone_number', 30),
            'ice_contact_name'                => opt_str($b, 'ice_contact_name', 120),
            'ice_contact_number'              => opt_str($b, 'ice_contact_number', 30),
            'ice_relationship'                => opt_str($b, 'ice_relationship', 60),
            'blood_type'                      => opt_str($b, 'blood_type', 8),
            'allergies'                       => opt_str($b, 'allergies', 255),
            'medical_conditions'              => opt_str($b, 'medical_conditions', 255),
            'wants_emergency_location_alerts' => $b['wants_emergency_location_alerts'] ?? true,
        ]);

        ok($updated);
    }

    public static function changePassword(): never
    {
        require_method('POST');
        $user = AuthMiddleware::authenticate();
        $b = body();

        $old = str_field($b, 'current_password', 128);
        $new = str_field($b, 'new_password', 128);

        User::changePassword((int)$user['id'], $old, $new);
        ok(['message' => 'Password updated successfully.']);
    }

    public static function logout(): never
    {
        require_method('POST');
        $token = AuthMiddleware::getBearerToken();
        if ($token !== null) {
            $stmt = db()->prepare('UPDATE user_sessions SET revoked_at = NOW() WHERE token_hash = ?');
            $stmt->execute([hash('sha256', $token)]);
        }
        ok(['message' => 'Logged out successfully.']);
    }

    public static function deleteAccount(): never
    {
        require_method('POST', 'DELETE');
        $user = AuthMiddleware::authenticate();

        User::deleteAccount((int)$user['id']);
        ok(['message' => 'Account deactivated and emergency records cleared.']);
    }
}
