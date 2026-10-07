<?php
/**
 * POST api/auth/register.php
 * ----------------------------------------------------------------------------
 * Creates an account and signs it in, mirroring AuthController.register() in the
 * Flutter app.
 *
 * Body:
 *   full_name, email, campus_id, role, department, phone_number, password
 *   wants_emergency_location_alerts (optional bool, default true)
 *
 * 200 -> { user: {...}, token: "...", expires_at: "..." }
 * 409 -> code "email_taken"
 * 422 -> code "missing_field" | "invalid_email" | "weak_password" | "unknown_role"
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

require_method('POST');

$in = body();

$fullName    = str_field($in, 'full_name', 120);
$email       = mb_strtolower(str_field($in, 'email', 160));
$campusId    = str_field($in, 'campus_id', 40);
$role        = str_field($in, 'role', 20);
$department  = str_field($in, 'department', 120);
$phoneNumber = str_field($in, 'phone_number', 30);
$password    = str_field($in, 'password', 200);
$wantsAlerts = bool_field($in, 'wants_emergency_location_alerts', true);

/* -- Validation: same rules the app enforces client-side, re-checked here
      because a client-side validator is a convenience, not a guarantee. ----- */

if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
    fail('Enter a valid email address.', 422, 'invalid_email');
}

if (mb_strlen($password) < 8) {
    fail('Use at least 8 characters.', 422, 'weak_password');
}

if (preg_match_all('/\d/', $phoneNumber) < 7) {
    fail('Enter a complete mobile number.', 422, 'invalid_phone');
}

$roleStmt = db()->prepare('SELECT code FROM campus_roles WHERE code = ? UNION SELECT id AS code FROM roles WHERE id = ?');
$roleStmt->execute([$role, $role]);
if ($roleStmt->fetchColumn() === false) {
    // Fallback: if staff, map to faculty if needed
    if ($role === 'staff') {
        $role = 'faculty';
    } else {
        fail("'$role' is not a recognised campus role.", 422, 'unknown_role');
    }
}

/* -- Create ---------------------------------------------------------------- */

$pdo = db();
$pdo->beginTransaction();

try {
    // 1. Insert primary user credentials
    $insertUser = $pdo->prepare(
        'INSERT INTO users (full_name, email, campus_id, role_id, password_hash, is_active)
         VALUES (?, ?, ?, ?, ?, 1)'
    );
    $insertUser->execute([
        $fullName,
        $email,
        $campusId,
        $role,
        password_hash($password, PASSWORD_BCRYPT),
    ]);

    $userId = (int) $pdo->lastInsertId();

    // 2. Insert user contact and profile information
    $insertProfile = $pdo->prepare(
        'INSERT INTO user_profiles (user_id, department, phone_number, wants_emergency_location_alerts)
         VALUES (?, ?, ?, ?)'
    );
    $insertProfile->execute([
        $userId,
        $department,
        $phoneNumber,
        $wantsAlerts ? 1 : 0,
    ]);

    $pdo->commit();
} catch (PDOException $e) {
    $pdo->rollBack();

    // 23000 / 1062 unique key violation on email
    if ($e->getCode() === '23000' || $e->errorInfo[1] === 1062) {
        fail('That email is already registered. Sign in instead.', 409, 'email_taken');
    }

    throw $e;
}

/* -- Sign in --------------------------------------------------------------- */

$session = issue_token($userId);

$profile = db()->prepare('SELECT * FROM vw_user_profile WHERE id = ?');
$profile->execute([$userId]);
$row = $profile->fetch();

audit($userId, 'register', 'user', (string) $userId, "Role: $role");

ok([
    'user'       => shape_user($row),
    'token'      => $session['token'],
    'expires_at' => $session['expires_at'],
], 201);
