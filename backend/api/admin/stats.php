<?php
/**
 * GET api/admin/stats.php
 * ----------------------------------------------------------------------------
 * High-level system metrics and live status for the Admin/Responder Dashboard.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/../incidents/shape.php';

require_method('GET');

$activeEmergencies = (int) db()->query(
    "SELECT COUNT(*) FROM sos_activations WHERE status IN ('active', 'responding')"
)->fetchColumn();

$pendingReports = (int) db()->query(
    "SELECT COUNT(*) FROM incident_reports WHERE status = 'pending'"
)->fetchColumn();

$responding = (int) db()->query(
    "SELECT COUNT(*) FROM incident_reports WHERE status = 'responding'"
)->fetchColumn();

$resolvedToday = (int) db()->query(
    "SELECT COUNT(*) FROM incident_reports 
     WHERE status = 'resolved' AND DATE(resolved_at) = CURDATE()"
)->fetchColumn();

// Categories breakdown from view
$cats = db()->query('SELECT * FROM vw_incident_stats_by_category')->fetchAll();

// Recent 10 incidents
$recentRows = db()->query(
    'SELECT * FROM vw_incident_feed ORDER BY reported_at DESC LIMIT 10'
)->fetchAll();

// Active responders
$responders = db()->query(
    "SELECT u.id, u.full_name, u.role_code, u.phone_number, u.department,
            (SELECT COUNT(*) FROM incident_reports r WHERE r.handled_by_user_id = u.id AND r.status = 'responding') AS active_cases
     FROM users u
     WHERE u.role_code IN ('security', 'staff') AND u.is_active = 1"
)->fetchAll();

ok([
    'metrics' => [
        'active_emergencies' => $activeEmergencies,
        'pending_reports'    => $pendingReports,
        'responding'         => $responding,
        'resolved_today'     => $resolvedToday,
    ],
    'categories' => $cats,
    'recent_incidents' => array_map('shape_incident', $recentRows),
    'responders' => $responders,
]);
