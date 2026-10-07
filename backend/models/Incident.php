<?php
/**
 * Incident Model
 * ----------------------------------------------------------------------------
 * Handles incident reporting, reference code generation, triage lifecycle,
 * media file associations, and responder assignment.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/AuditLog.php';

class Incident
{
    public static function generateReferenceCode(): string
    {
        $year = date('Y');
        $random = strtoupper(bin2hex(random_bytes(3))); // 6 hex digits
        return "BA-{$year}-{$random}";
    }

    public static function create(array $data, ?int $reporterUserId = null): array
    {
        $refCode = self::generateReferenceCode();
        $isAnonymous = !empty($data['is_anonymous']);
        $actualReporter = $isAnonymous ? null : $reporterUserId;

        $category = trim($data['category_code'] ?? $data['category_id'] ?? 'other');
        $locationLabel = trim($data['location_label'] ?? 'BISU Campus');
        $description = trim($data['description'] ?? '');
        $priority = in_array($data['priority'] ?? 'normal', ['low', 'normal', 'high', 'critical'], true)
            ? $data['priority']
            : 'normal';

        $lat = isset($data['latitude']) && is_numeric($data['latitude']) ? (float)$data['latitude'] : null;
        $lng = isset($data['longitude']) && is_numeric($data['longitude']) ? (float)$data['longitude'] : null;
        $buildingId = $data['building_id'] ?? null;
        $source = $data['source'] ?? 'app_report';

        $stmt = db()->prepare(
            'INSERT INTO incidents (
                reference_code, reporter_user_id, category_id, status_id, building_id,
                location_label, latitude, longitude, description, priority, source, is_anonymous, reported_at
             ) VALUES (?, ?, ?, "pending", ?, ?, ?, ?, ?, ?, ?, ?, NOW())'
        );

        $stmt->execute([
            $refCode,
            $actualReporter,
            $category,
            $buildingId,
            $locationLabel,
            $lat,
            $lng,
            $description,
            $priority,
            $source,
            $isAnonymous ? 1 : 0,
        ]);

        $incidentId = (int)db()->lastInsertId();

        AuditLog::log(
            $actualReporter,
            'incident_create',
            'incidents',
            (string)$incidentId,
            "Created incident {$refCode} ({$category})"
        );

        return self::getById($incidentId) ?? ['id' => $incidentId, 'reference_code' => $refCode];
    }

    public static function getById(int $id): ?array
    {
        $stmt = db()->prepare(
            'SELECT i.*, c.name AS category_label, s.name AS status_label, s.color_hex,
                    u.full_name AS reporter_name, h.full_name AS handler_name
             FROM incidents i
             LEFT JOIN incident_categories c ON c.id = i.category_id
             LEFT JOIN incident_statuses s ON s.id = i.status_id
             LEFT JOIN users u ON u.id = i.reporter_user_id
             LEFT JOIN users h ON h.id = i.handled_by_user_id
             WHERE i.id = ? LIMIT 1'
        );
        $stmt->execute([$id]);
        $row = $stmt->fetch();
        return $row ? self::formatIncident($row) : null;
    }

    public static function list(array $filters = []): array
    {
        $sql = 'SELECT i.*, c.name AS category_label, s.name AS status_label, s.color_hex,
                       u.full_name AS reporter_name, h.full_name AS handler_name
                FROM incidents i
                LEFT JOIN incident_categories c ON c.id = i.category_id
                LEFT JOIN incident_statuses s ON s.id = i.status_id
                LEFT JOIN users u ON u.id = i.reporter_user_id
                LEFT JOIN users h ON h.id = i.handled_by_user_id
                WHERE 1=1';

        $params = [];

        if (!empty($filters['status'])) {
            $sql .= ' AND i.status_id = ?';
            $params[] = $filters['status'];
        }

        if (!empty($filters['reporter_id'])) {
            $sql .= ' AND i.reporter_user_id = ?';
            $params[] = (int)$filters['reporter_id'];
        }

        if (!empty($filters['category'])) {
            $sql .= ' AND i.category_id = ?';
            $params[] = $filters['category'];
        }

        $sql .= ' ORDER BY i.reported_at DESC LIMIT 100';

        $stmt = db()->prepare($sql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll();

        return array_map([self::class, 'formatIncident'], $rows);
    }

    public static function updateStatus(int $id, string $newStatus, ?int $handlerUserId = null, ?string $note = null): array
    {
        $validStatuses = ['pending', 'acknowledged', 'responding', 'resolved', 'cancelled'];
        if (!in_array($newStatus, $validStatuses, true)) {
            fail("Invalid status '{$newStatus}'.", 422, 'invalid_status');
        }

        $resolvedAt = ($newStatus === 'resolved') ? date('Y-m-d H:i:s') : null;

        $stmt = db()->prepare(
            'UPDATE incidents SET
                status_id = ?,
                handled_by_user_id = COALESCE(?, handled_by_user_id),
                acknowledged_at = CASE WHEN ? = "acknowledged" AND acknowledged_at IS NULL THEN NOW() ELSE acknowledged_at END,
                resolved_at = CASE WHEN ? = "resolved" THEN NOW() ELSE resolved_at END,
                updated_at = NOW()
             WHERE id = ?'
        );
        $stmt->execute([$newStatus, $handlerUserId, $newStatus, $newStatus, $id]);

        AuditLog::log(
            $handlerUserId,
            'incident_status_change',
            'incidents',
            (string)$id,
            "Changed status to {$newStatus}. Note: {$note}"
        );

        return self::getById($id) ?? ['id' => $id, 'status' => $newStatus];
    }

    public static function formatIncident(array $row): array
    {
        return [
            'id'             => (int)$row['id'],
            'reference_code' => $row['reference_code'],
            'category_code'  => $row['category_id'] ?? 'other',
            'category_label' => $row['category_label'] ?? ucfirst($row['category_id'] ?? 'Incident'),
            'status'         => $row['status_id'] ?? 'pending',
            'status_label'   => $row['status_label'] ?? ucfirst($row['status_id'] ?? 'Pending'),
            'color_hex'      => $row['color_hex'] ?? '#F59E0B',
            'priority'       => $row['priority'] ?? 'normal',
            'location_label' => $row['location_label'] ?? '',
            'latitude'       => isset($row['latitude']) ? (float)$row['latitude'] : null,
            'longitude'      => isset($row['longitude']) ? (float)$row['longitude'] : null,
            'description'    => $row['description'] ?? '',
            'is_anonymous'   => (bool)($row['is_anonymous'] ?? false),
            'source'         => $row['source'] ?? 'app_report',
            'reporter_id'    => isset($row['reporter_user_id']) ? (int)$row['reporter_user_id'] : null,
            'reporter_name'  => (!empty($row['is_anonymous'])) ? 'Anonymous' : ($row['reporter_name'] ?? 'Campus Reporter'),
            'handler_name'   => $row['handler_name'] ?? null,
            'reported_at'    => iso($row['reported_at'] ?? null),
            'resolved_at'    => iso($row['resolved_at'] ?? null),
        ];
    }
}
