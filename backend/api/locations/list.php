<?php
/**
 * GET api/locations/list.php
 * ----------------------------------------------------------------------------
 * Everything the campus map needs in one round trip: the landmarks and the
 * perimeter polygon they must sit inside.
 *
 * Query (optional):
 *   type=emergency_hub|building|evacuation_zone   filter to one category
 *
 * 200 -> { locations: [...], boundary: [{latitude, longitude}, ...], types: [...] }
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

require_method('GET');
require_auth();

$type = query('type');

if ($type !== null) {
    $stmt = db()->prepare('SELECT * FROM vw_campus_map WHERE location_type_code = ?');
    $stmt->execute([$type]);
} else {
    $stmt = db()->query('SELECT * FROM vw_campus_map');
}

$locations = array_map(
    static fn (array $r): array => [
        'code'                => $r['code'],
        'name'                => $r['name'],
        'description'         => $r['description'],
        'latitude'            => num($r['latitude']),
        'longitude'           => num($r['longitude']),
        'location_type'       => $r['location_type_code'],
        'location_type_label' => $r['location_type_label'],
        'marker_hue'          => $r['marker_hue'],
        'contact_number'      => $r['contact_number'],
    ],
    $stmt->fetchAll()
);

$boundary = array_map(
    static fn (array $r): array => [
        'latitude'  => num($r['latitude']),
        'longitude' => num($r['longitude']),
    ],
    db()->query(
        'SELECT latitude, longitude FROM campus_boundary_points ORDER BY point_order'
    )->fetchAll()
);

$types = array_map(
    static fn (array $r): array => [
        'code'       => $r['code'],
        'label'      => $r['label'],
        'marker_hue' => $r['marker_hue'],
    ],
    db()->query('SELECT code, label, marker_hue FROM location_types ORDER BY sort_order')->fetchAll()
);

ok([
    'locations' => $locations,
    'boundary'  => $boundary,
    'types'     => $types,
]);
