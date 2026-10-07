<?php
/**
 * IncidentController
 * ----------------------------------------------------------------------------
 * Handles incident creation, filtering, personal reports, and status updates.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/../models/Incident.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/RateLimitMiddleware.php';

class IncidentController
{
    public static function create(): never
    {
        require_method('POST');
        RateLimitMiddleware::limitReport();

        $user = AuthMiddleware::user();
        $b = body();

        $incident = Incident::create([
            'category_code'  => str_field($b, 'category_code', 30),
            'location_label' => str_field($b, 'location_label', 150),
            'description'    => str_field($b, 'description', 2000),
            'priority'       => opt_str($b, 'priority', 20) ?? 'normal',
            'latitude'       => opt_coord($b, 'latitude', 90.0),
            'longitude'      => opt_coord($b, 'longitude', 180.0),
            'building_id'    => opt_str($b, 'building_id', 30),
            'is_anonymous'   => $b['is_anonymous'] ?? false,
            'source'         => 'app_report',
        ], $user ? (int)$user['id'] : null);

        ok($incident, 201);
    }

    public static function list(): never
    {
        require_method('GET');
        $filters = [];
        if (($status = query('status')) !== null) {
            $filters['status'] = $status;
        }
        if (($category = query('category')) !== null) {
            $filters['category'] = $category;
        }

        $items = Incident::list($filters);
        ok($items);
    }

    public static function myReports(): never
    {
        require_method('GET');
        $user = AuthMiddleware::authenticate();

        $items = Incident::list(['reporter_id' => (int)$user['id']]);
        ok($items);
    }

    public static function updateStatus(): never
    {
        require_method('POST', 'PATCH');
        $responder = RoleMiddleware::requireResponder();
        $b = body();

        $id = (int)($b['id'] ?? 0);
        if ($id <= 0) {
            fail('Incident ID is required.', 422, 'missing_id');
        }

        $newStatus = str_field($b, 'status', 30);
        $note = opt_str($b, 'note', 255);

        $updated = Incident::updateStatus($id, $newStatus, (int)$responder['id'], $note);
        ok($updated);
    }

    public static function show(): never
    {
        require_method('GET');
        $id = (int)query('id', '0');
        if ($id <= 0) {
            fail('Incident ID is required.', 422, 'missing_id');
        }

        $item = Incident::getById($id);
        if (!$item) {
            fail('Incident not found.', 404, 'not_found');
        }
        ok($item);
    }
}
