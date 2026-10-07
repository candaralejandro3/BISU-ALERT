<?php
/**
 * POST api/sos/cancel.php
 * ----------------------------------------------------------------------------
 * Cancels an active SOS alert (e.g. user pressed cancel, or false alarm).
 *
 * Body:
 *   sos_id      optional int (if known)
 *   incident_id optional int (if known)
 *   reason      optional string
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/../incidents/shape.php';

require_method('POST');

$user   = require_auth();
$userId = (int) $user['id'];
$in     = body();

$sosId      = isset($in['sos_id']) ? (int) $in['sos_id'] : 0;
$incidentId = isset($in['incident_id']) ? (int) $in['incident_id'] : 0;
$reason     = opt_str($in, 'reason', 255) ?? 'Cancelled by user';

if ($sosId <= 0 && $incidentId <= 0) {
    // Look up most recent active SOS by this user
    $find = db()->prepare(
        "SELECT id, incident_report_id FROM sos_activations 
         WHERE user_id = ? AND status IN ('active', 'responding') 
         ORDER BY activated_at DESC LIMIT 1"
    );
    $find->execute([$userId]);
    $active = $find->fetch();
    if ($active) {
        $sosId = (int) $active['id'];
        $incidentId = (int) $active['incident_report_id'];
    }
}

if ($sosId > 0) {
    $stmt = db()->prepare(
        "UPDATE sos_activations 
         SET status = 'false_alarm', resolved_at = NOW() 
         WHERE id = ?"
    );
    $stmt->execute([$sosId]);
}

if ($incidentId > 0) {
    $call = db()->prepare('CALL sp_update_incident_status(?, ?, ?, ?)');
    $call->execute([$incidentId, 'dismissed', $userId, 'Emergency cancelled: ' . $reason]);
    $call->closeCursor();
}

audit(
    $userId,
    'sos_cancel',
    'sos_activation',
    (string) $sosId,
    "Emergency cancelled. Reason: $reason"
);

ok([
    'cancelled' => true,
    'sos_id'    => $sosId,
    'incident_id' => $incidentId,
    'message'   => 'Emergency alert successfully cancelled.',
]);
