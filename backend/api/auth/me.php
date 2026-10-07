<?php
/**
 * GET api/auth/me.php
 * ----------------------------------------------------------------------------
 * The profile behind the current bearer token. The app calls this on startup to
 * decide whether a stored token is still good, so it doubles as a session check.
 *
 * 200 -> { user: {...} }
 * 401 -> code "unauthenticated"  (token missing, expired, revoked, or disabled)
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

require_method('GET');

ok(['user' => shape_user(require_auth())]);
