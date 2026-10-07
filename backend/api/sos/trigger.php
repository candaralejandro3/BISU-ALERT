<?php
/**
 * POST api/sos/trigger.php
 * ----------------------------------------------------------------------------
 * The home screen's SOS button. One tap opens three linked rows -- the
 * activation, a critical incident so it enters the responder queue, and a
 * critical alert so the campus feed shows it -- and sp_trigger_sos writes all
 * three in one transaction, so a half-registered SOS cannot happen.
 *
 * Nothing here is optional to the caller in practice: the button sends whatever
 * position it has and no description at all, because a person pressing it has
 * no time to type. Everything responders need is derived server side.
 *
 * Body (all optional):
 *   latitude         device GPS; the client falls back to the campus centre
 *   longitude
 *   accuracy_meters  GPS accuracy the handset reported
 *   category         medical | security | fire_hazard | facility_damage.
 *                    Defaults to medical inside the procedure -- a panic press
 *                    says nothing about what is wrong, so it is triaged as the
 *                    most urgent kind until a responder learns otherwise.
 *
 * 201 -> { sos_id: 12, incident: {...} }
 * 422 -> code "unknown_category"
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

require_method('POST');

$user   = require_auth();
$userId = (int) $user['id'];
$in     = body();

$latitude  = opt_coord($in, 'latitude', 90.0);
$longitude = opt_coord($in, 'longitude', 180.0);

// sos_activations.accuracy_meters is DECIMAL(6,2), so 9999.99 m is the widest
// circle the column can hold. A negative accuracy is meaningless; drop it
// rather than reject the SOS over it.
$accuracy = opt_coord($in, 'accuracy_meters', 9999.99);
if ($accuracy !== null && $accuracy < 0) {
    $accuracy = null;
}

$category = opt_str($in, 'category', 30);
if ($category !== null) {
    $categoryStmt = db()->prepare('SELECT code FROM incident_categories WHERE code = ?');
    $categoryStmt->execute([$category]);
    if ($categoryStmt->fetchColumn() === false) {
        fail("'$category' is not a recognised incident category.", 422, 'unknown_category');
    }
}

/* -- Activate -------------------------------------------------------------- */

$call = db()->prepare(
    'CALL sp_trigger_sos(?, ?, ?, ?, ?, @sos_id, @incident_id, @reference_code)'
);
$call->execute([$userId, $latitude, $longitude, $accuracy, $category]);
$call->closeCursor();

$outs = db()
    ->query('SELECT @sos_id AS sos_id, @incident_id AS incident_id, @reference_code AS reference_code')
    ->fetch();

$sosId      = (int) $outs['sos_id'];
$incidentId = (int) $outs['incident_id'];

audit(
    $userId,
    'sos_trigger',
    'sos_activation',
    (string) $sosId,
    'Incident ' . ($outs['reference_code'] ?? $incidentId)
);

$row = db()->prepare('SELECT * FROM vw_incident_feed WHERE id = ?');
$row->execute([$incidentId]);

require_once __DIR__ . '/../incidents/shape.php';

ok([
    'sos_id'   => $sosId,
    'incident' => shape_incident($row->fetch()),
], 201);
