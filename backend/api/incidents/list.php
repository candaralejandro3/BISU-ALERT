<?php
/**
 * GET api/incidents/list.php
 * ----------------------------------------------------------------------------
 * Fetches incident reports.
 * 
 * Query params:
 *   filter   = 'mine' | 'active' | 'all' (default: 'mine' for students, 'active' for responders)
 *   status   = 'pending' | 'acknowledged' | 'responding' | 'resolved' | 'dismissed'
 *   category = incident category code
 *   limit    = integer (default 50, max 100)
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/shape.php';

require_method('GET');

$user   = require_auth();
$userId = (int) $user['id'];
$role   = $user['role_code'] ?? 'student';
$isResponder = in_array($role, ['security', 'staff', 'admin'], true);

$filter   = $_GET['filter'] ?? ($isResponder ? 'active' : 'mine');
$status   = opt_str($_GET, 'status', 20);
$category = opt_str($_GET, 'category', 30);
$limit    = isset($_GET['limit']) ? min(100, max(1, (int)$_GET['limit'])) : 50;

$where = [];
$params = [];

if ($filter === 'mine') {
    $where[] = 'reporter_user_id = ?';
    $params[] = $userId;
} elseif ($filter === 'active') {
    $where[] = "status IN ('pending', 'acknowledged', 'responding')";
}

if ($status !== null) {
    $where[] = 'status = ?';
    $params[] = $status;
}

if ($category !== null) {
    $where[] = 'category_code = ?';
    $params[] = $category;
}

$sql = 'SELECT * FROM vw_incident_feed';
if (!empty($where)) {
    $sql .= ' WHERE ' . implode(' AND ', $where);
}
$sql .= ' ORDER BY reported_at DESC LIMIT ' . $limit;

$stmt = db()->prepare($sql);
$stmt->execute($params);
$rows = $stmt->fetchAll();

$incidents = array_map('shape_incident', $rows);

ok([
    'total'     => count($incidents),
    'incidents' => $incidents,
]);
