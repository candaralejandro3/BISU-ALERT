<?php
/**
 * POST api/auth/login.php
 * ----------------------------------------------------------------------------
 * Body: email, password
 *
 * 200 -> { user: {...}, token: "...", expires_at: "..." }
 * 401 -> code "unknown_email" | "wrong_password"
 * 403 -> code "account_disabled"
 *
 * Note on the two distinct 401 codes: they let the app reproduce the wording it
 * already shows ("No BISU-Alert account uses that email yet" vs "Incorrect
 * password"), at the cost of confirming whether an address is registered. That
 * is an acceptable trade for a campus roster; a public-facing service should
 * collapse both into one generic message.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

require_method('POST');

$in       = body();
$email    = mb_strtolower(str_field($in, 'email', 160));
$password = str_field($in, 'password', 200);

$stmt = db()->prepare(
    'SELECT id, password_hash, is_active FROM users WHERE email = ? LIMIT 1'
);
$stmt->execute([$email]);
$account = $stmt->fetch();

if ($account === false) {
    fail(
        'No BISU-Alert account uses that email yet. Create one first.',
        401,
        'unknown_email'
    );
}

if (!password_verify($password, $account['password_hash'])) {
    audit((int) $account['id'], 'login_failed', 'user', (string) $account['id']);
    fail('Incorrect password. Please try again.', 401, 'wrong_password');
}

if (!flag($account['is_active'])) {
    fail(
        'This account has been deactivated. Contact the campus security office.',
        403,
        'account_disabled'
    );
}

$userId = (int) $account['id'];

// bcrypt cost may have been raised in config since this hash was written, or the
// row may predate a default change. Re-hash on a successful login so accounts
// migrate forward on their own instead of needing a bulk reset.
if (password_needs_rehash($account['password_hash'], PASSWORD_BCRYPT)) {
    db()->prepare('UPDATE users SET password_hash = ? WHERE id = ?')
        ->execute([password_hash($password, PASSWORD_BCRYPT), $userId]);
}

db()->prepare('UPDATE users SET last_login_at = NOW() WHERE id = ?')->execute([$userId]);

$session = issue_token($userId);

$profile = db()->prepare('SELECT * FROM vw_user_profile WHERE id = ?');
$profile->execute([$userId]);

audit($userId, 'login', 'user', (string) $userId);

ok([
    'user'       => shape_user($profile->fetch()),
    'token'      => $session['token'],
    'expires_at' => $session['expires_at'],
]);
