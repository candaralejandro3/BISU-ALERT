<?php
/**
 * POST api/incidents/create.php
 * ----------------------------------------------------------------------------
 * Submits an incident report -- the "Submit Alert" button on the report screen.
 * Delegates to sp_submit_incident_report so the reference code and the
 * category's default priority are assigned in one place.
 *
 * Body:
 *   category         medical | security | fire_hazard | facility_damage
 *   description      required
 *   location_code    optional, a campus_locations code when a landmark was tagged
 *   location_label   optional, defaults to the landmark name or the GPS string
 *   latitude         optional
 *   longitude        optional
 *   is_anonymous     optional bool, default false
 *
 * Anonymity is honoured at the database level: the procedure stores a NULL
 * reporter, so the identity is not recorded rather than merely hidden.
 *
 * 201 -> { incident: {...} }
 * 422 -> code "unknown_category" | "unknown_location" | "missing_field"
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

require_method('POST');

$user   = require_auth();
$userId = (int) $user['id'];
$in     = body();

$category    = str_field($in, 'category', 30);
$description = str_field($in, 'description', 5000);
$isAnonymous = bool_field($in, 'is_anonymous', false);
$latitude    = opt_coord($in, 'latitude', 90.0);
$longitude   = opt_coord($in, 'longitude', 180.0);
$locationCode  = opt_str($in, 'location_code', 30);
$locationLabel = opt_str($in, 'location_label', 150);

$categoryStmt = db()->prepare('SELECT code FROM incident_categories WHERE code = ?');
$categoryStmt->execute([$category]);
if ($categoryStmt->fetchColumn() === false) {
    fail("'$category' is not a recognised incident category.", 422, 'unknown_category');
}

/* A tagged landmark supplies the label and the coordinates when the client did
   not send its own, so a report always has somewhere for responders to go. */
if ($locationCode !== null) {
    $locStmt = db()->prepare(
        'SELECT name, latitude, longitude FROM campus_locations WHERE code = ? AND is_active = 1'
    );
    $locStmt->execute([$locationCode]);
    $location = $locStmt->fetch();

    if ($location === false) {
        fail("'$locationCode' is not an active campus location.", 422, 'unknown_location');
    }

    $locationLabel ??= $location['name'];
    $latitude      ??= (float) $location['latitude'];
    $longitude     ??= (float) $location['longitude'];
}

if ($locationLabel === null) {
    $locationLabel = ($latitude !== null && $longitude !== null)
        ? sprintf('GPS: %.5f, %.5f', $latitude, $longitude)
        : 'Location not specified';
}

/* -- Submit ---------------------------------------------------------------- */

$call = db()->prepare(
    'CALL sp_submit_incident_report(?, ?, ?, ?, ?, ?, ?, ?, ?, @incident_id, @reference_code)'
);
$call->execute([
    $userId,
    $category,
    $locationCode,
    $locationLabel,
    $latitude,
    $longitude,
    $description,
    $isAnonymous ? 1 : 0,
    'app_report',
]);
$call->closeCursor();

$outs = db()->query('SELECT @incident_id AS id, @reference_code AS reference_code')->fetch();
$incidentId = (int) $outs['id'];

audit(
    $isAnonymous ? null : $userId,
    'incident_create',
    'incident_report',
    (string) $incidentId,
    "Category: $category" . ($isAnonymous ? ' (anonymous)' : '')
);

$row = db()->prepare('SELECT * FROM vw_incident_feed WHERE id = ?');
$row->execute([$incidentId]);

require_once __DIR__ . '/shape.php';

ok(['incident' => shape_incident($row->fetch())], 201);
