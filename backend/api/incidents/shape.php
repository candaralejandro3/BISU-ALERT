<?php
/**
 * BISU-Alert API -- incident response shaping
 * ----------------------------------------------------------------------------
 * Shared by incidents/create.php, incidents/list.php and incidents/update_status.php
 * so all three return the same object shape.
 */

declare(strict_types=1);

/**
 * vw_incident_feed row -> JSON object.
 *
 * The view has already masked the reporter on anonymous rows, so nothing here
 * needs to re-check is_anonymous before exposing a name.
 *
 * @param array<string, mixed> $r
 * @return array<string, mixed>
 */
function shape_incident(array $r): array
{
    return [
        'id'              => (int) $r['id'],
        'reference_code'  => $r['reference_code'],
        'category'        => $r['category_code'],
        'category_label'  => $r['category_label'],
        'location_code'   => $r['location_code'],
        'location_label'  => $r['location_label'],
        'latitude'        => num($r['latitude']),
        'longitude'       => num($r['longitude']),
        'description'     => $r['description'],
        'is_anonymous'    => flag($r['is_anonymous']),
        'priority'        => $r['priority'],
        'status'          => $r['status'],
        'source'          => $r['source'],
        'reporter_id'     => $r['reporter_user_id'] === null ? null : (int) $r['reporter_user_id'],
        'reporter_name'   => $r['reporter_name'],
        'reporter_role'   => $r['reporter_role'],
        'handled_by'      => $r['handled_by'],
        'media_count'     => (int) $r['media_count'],
        'reported_at'     => iso($r['reported_at']),
        'acknowledged_at' => iso($r['acknowledged_at']),
        'resolved_at'     => iso($r['resolved_at']),
    ];
}
