<?php
/**
 * POST api/incidents/update_status.php
 * ----------------------------------------------------------------------------
 * Updates incident status (accept, dispatch, arrive, resolve, dismiss).
 * Uses stored procedure sp_update_incident_status to ensure audit trail and
 * timestamps (acknowledged_at, resolved_at) remain consistent.
 *
 * Body:
 *   incident_id  int/string required
 *   status       'pending' | 'acknowledged' | 'responding' | 'resolved' | 'dismissed'
 *   note         optional string (up to 255 chars)
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/shape.php';

require_method('POST');

$user   = require_auth();
$userId = (int) $user['id'];
$in     = body();

$incidentId = (int) ($in['incident_id'] ?? 0);
if ($incidentId <= 0) {
    fail('Field "incident_id" must be a positive integer.', 422, 'invalid_incident_id');
}

$status = str_field($in, 'status', 20);
$allowedStatuses = ['pending', 'acknowledged', 'responding', 'resolved', 'dismissed'];
if (!in_array($status, $allowedStatuses, true)) {
    fail("Status '$status' is not allowed. Allowed values: " . implode(', ', $allowedStatuses), 422, 'invalid_status');
}

$note = opt_str($in, 'note', 255);

$call = db()->prepare('CALL sp_update_incident_status(?, ?, ?, ?)');
$call->execute([$incidentId, $status, $userId, $note]);
$call->closeCursor();

audit(
    $userId,
    'incident_status_update',
    'incident_report',
    (string) $incidentId,
    "Status updated to '$status'" . ($note ? ": $note" : '')
);

$row = db()->prepare('SELECT * FROM vw_incident_feed WHERE id = ?');
$row->execute([$incidentId]);
$incident = $row->fetch();

if (!$incident) {
    fail('Incident not found after update.', 404, 'not_found');
}

ok([
    'incident' => shape_incident($incident),
]);
