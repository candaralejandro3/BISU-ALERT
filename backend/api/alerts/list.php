<?php
/**
 * GET api/alerts/list.php
 * ----------------------------------------------------------------------------
 * The Active Alerts feed. Critical broadcasts sort to the top, then newest first.
 *
 * Query (optional):
 *   limit=1..100   default 20
 *
 * Location privacy: an alert's coordinates are only included for users who
 * switched on "Emergency location alerts". Everyone still sees the title, detail
 * and the landmark name -- opting out withholds the map pin, not the warning.
 *
 * 200 -> { alerts: [...], unread_count: n }
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

require_method('GET');

$user   = require_auth();
$userId = (int) $user['id'];
$shareLocation = flag($user['wants_emergency_location_alerts']);

$limit = (int) (query('limit') ?? '20');
$limit = max(1, min(100, $limit));

// LIMIT cannot be bound as a string parameter with emulation off, so it is cast
// to int and clamped above rather than interpolated from raw input.
$stmt = db()->prepare("SELECT * FROM vw_active_alerts LIMIT $limit");
$stmt->execute();

$alerts = array_map(
    static function (array $r) use ($shareLocation): array {
        return [
            'id'               => (int) $r['id'],
            'title'            => $r['title'],
            'detail'           => $r['detail'],
            'is_critical'      => flag($r['is_critical']),
            'alert_type'       => $r['alert_type_code'],
            'alert_type_label' => $r['alert_type_label'],
            'location_name'    => $r['location_name'],
            'latitude'         => $shareLocation ? num($r['latitude']) : null,
            'longitude'        => $shareLocation ? num($r['longitude']) : null,
            'incident_id'      => $r['incident_report_id'] === null
                                      ? null : (int) $r['incident_report_id'],
            'published_by'     => $r['published_by'],
            'published_at'     => iso($r['published_at']),
            'expires_at'       => iso($r['expires_at']),
        ];
    },
    $stmt->fetchAll()
);

$unread = db()->prepare(
    'SELECT COUNT(*)
     FROM vw_active_alerts a
     WHERE NOT EXISTS (
         SELECT 1 FROM alert_reads r WHERE r.alert_id = a.id AND r.user_id = ?
     )'
);
$unread->execute([$userId]);

ok([
    'alerts'       => $alerts,
    'unread_count' => (int) $unread->fetchColumn(),
]);
