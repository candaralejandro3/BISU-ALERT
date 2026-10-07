<?php
/**
 * SosAlert Model
 * ----------------------------------------------------------------------------
 * Manages one-touch SOS panic triggers, campus geofence coordinates,
 * auto-creation of emergency incident dispatches, and alert cancellation.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/Incident.php';
require_once __DIR__ . '/AuditLog.php';

class SosAlert
{
    public static function activate(int $userId, float $lat, float $lng, ?float $accuracy = null, ?string $landmark = null): array
    {
        $pdo = db();
        $pdo->beginTransaction();

        try {
            // 1. Create emergency incident report automatically
            $incident = Incident::create([
                'category_code'  => 'medical',
                'location_label' => $landmark ?: sprintf('SOS GPS: %.5f, %.5f', $lat, $lng),
                'latitude'       => $lat,
                'longitude'      => $lng,
                'description'    => 'EMERGENCY SOS ACTIVATED by user. Immediate response required.',
                'priority'       => 'critical',
                'source'         => 'sos_button',
                'is_anonymous'   => false,
            ], $userId);

            // 2. Insert into sos_alerts table
            $stmt = $pdo->prepare(
                'INSERT INTO sos_alerts (user_id, latitude, longitude, accuracy_meters, incident_id, status, activated_at)
                 VALUES (?, ?, ?, ?, ?, "active", NOW())'
            );
            $stmt->execute([$userId, $lat, $lng, $accuracy, $incident['id']]);
            $sosId = (int)$pdo->lastInsertId();

            $pdo->commit();

            AuditLog::log(
                $userId,
                'sos_activate',
                'sos_alerts',
                (string)$sosId,
                "SOS triggered at ({$lat}, {$lng}). Linked incident #{$incident['id']}"
            );

            return [
                'sos_id'          => $sosId,
                'incident_id'     => $incident['id'],
                'reference_code'  => $incident['reference_code'],
                'status'          => 'active',
                'latitude'        => $lat,
                'longitude'       => $lng,
                'activated_at'    => date('c'),
            ];
        } catch (Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    public static function cancel(int $sosId, ?int $userId = null, string $reason = 'Cancelled by reporter'): void
    {
        $stmt = db()->prepare(
            'UPDATE sos_alerts SET status = "cancelled", resolved_at = NOW()
             WHERE id = ?'
        );
        $stmt->execute([$sosId]);

        // Also update linked incident if any
        $stmtInc = db()->prepare(
            'UPDATE incidents SET status_id = "cancelled", resolved_at = NOW()
             WHERE id = (SELECT incident_id FROM sos_alerts WHERE id = ?)'
        );
        $stmtInc->execute([$sosId]);

        AuditLog::log($userId, 'sos_cancel', 'sos_alerts', (string)$sosId, "SOS cancelled: {$reason}");
    }
}
