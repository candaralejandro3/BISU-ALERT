<?php
/**
 * POST|PATCH api/users/update_profile.php
 * ----------------------------------------------------------------------------
 * Partial update of the signed-in user's own profile -- everything the "Profile
 * & Emergency Settings" screen can edit. Send only the keys you are changing.
 *
 * Body (all optional):
 *   campus_id, department, phone_number, wants_emergency_location_alerts,
 *   ice_contact_name, ice_contact_number, ice_relationship,
 *   blood_type, allergies, medical_conditions
 *
 * Identity fields (full_name, email, role) are deliberately not editable here --
 * changing who an account belongs to is a records-office action, not a settings
 * toggle.
 *
 * 200 -> { user: {...} }
 * 422 -> code "no_changes" | "invalid_phone"
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

require_method('POST', 'PATCH');

$user   = require_auth();
$userId = (int) $user['id'];
$in     = body();

/* -- users columns --------------------------------------------------------- */

$userUpdates = [];
$userParams  = [];

foreach (['campus_id' => 40, 'department' => 120, 'phone_number' => 30] as $key => $maxLength) {
    $value = opt_str($in, $key, $maxLength);
    if ($value === null) {
        continue;
    }

    if ($key === 'phone_number' && preg_match_all('/\d/', $value) < 7) {
        fail('Enter a complete mobile number.', 422, 'invalid_phone');
    }

    $userUpdates[] = "`$key` = ?";
    $userParams[]  = $value;
}

if (array_key_exists('wants_emergency_location_alerts', $in)) {
    $userUpdates[] = '`wants_emergency_location_alerts` = ?';
    $userParams[]  = bool_field($in, 'wants_emergency_location_alerts') ? 1 : 0;
}

/* -- user_medical_profiles columns ----------------------------------------- */

$medicalColumns = [
    'ice_contact_name'   => 120,
    'ice_contact_number' => 30,
    'ice_relationship'   => 60,
    'blood_type'         => 8,
    'allergies'          => 255,
    'medical_conditions' => 255,
];

$medicalUpdates = [];
$medicalParams  = [];

foreach ($medicalColumns as $key => $maxLength) {
    if (!array_key_exists($key, $in)) {
        continue;
    }

    // Present but blank means "clear this field", which is different from absent.
    $medicalUpdates[] = "`$key` = ?";
    $medicalParams[]  = opt_str($in, $key, $maxLength);
}

if ($userUpdates === [] && $medicalUpdates === []) {
    fail('No editable fields were supplied.', 422, 'no_changes');
}

/* -- Apply ----------------------------------------------------------------- */

$pdo = db();
$pdo->beginTransaction();

try {
    if ($userUpdates !== []) {
        $userParams[] = $userId;
        $pdo->prepare(
            'UPDATE users SET ' . implode(', ', $userUpdates) . ' WHERE id = ?'
        )->execute($userParams);
    }

    if ($medicalUpdates !== []) {
        // Registration seeds a row per user, but an account imported straight
        // into SQLyog may not have one -- make sure it exists before updating.
        $pdo->prepare(
            'INSERT INTO user_medical_profiles (user_id) VALUES (?)
             ON DUPLICATE KEY UPDATE user_id = user_id'
        )->execute([$userId]);

        $medicalParams[] = $userId;
        $pdo->prepare(
            'UPDATE user_medical_profiles SET ' . implode(', ', $medicalUpdates)
            . ' WHERE user_id = ?'
        )->execute($medicalParams);
    }

    $pdo->commit();
} catch (Throwable $e) {
    $pdo->rollBack();
    throw $e;
}

$profile = $pdo->prepare('SELECT * FROM vw_user_profile WHERE id = ?');
$profile->execute([$userId]);

audit(
    $userId,
    'profile_update',
    'user',
    (string) $userId,
    'Fields: ' . implode(', ', array_keys($in))
);

ok(['user' => shape_user($profile->fetch())]);
