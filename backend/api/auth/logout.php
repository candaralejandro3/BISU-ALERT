<?php
/**
 * POST api/auth/logout.php
 * ----------------------------------------------------------------------------
 * Revokes the bearer token used to make this call. Other devices signed in as
 * the same account keep their sessions.
 *
 * 200 -> { revoked: true }
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

require_method('POST');

$user  = require_auth();
$token = bearer_token();

$stmt = db()->prepare(
    'UPDATE user_sessions
     SET revoked_at = NOW()
     WHERE token_hash = ? AND revoked_at IS NULL'
);
$stmt->execute([hash('sha256', (string) $token)]);

audit((int) $user['id'], 'logout', 'user', (string) $user['id']);

ok(['revoked' => $stmt->rowCount() > 0]);
