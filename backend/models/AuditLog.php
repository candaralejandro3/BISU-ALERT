<?php
/**
 * AuditLog Model
 * ----------------------------------------------------------------------------
 * Logs security and operational actions to the immutable audit_logs table.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';

class AuditLog
{
    public static function log(
        ?int $userId,
        string $action,
        ?string $entityType = null,
        ?string $entityId = null,
        ?string $detail = null
    ): void {
        try {
            $stmt = db()->prepare(
                'INSERT INTO audit_logs (user_id, action, entity_type, entity_id, detail, ip_address)
                 VALUES (?, ?, ?, ?, ?, ?)'
            );
            $stmt->execute([
                $userId,
                $action,
                $entityType,
                $entityId,
                $detail !== null ? mb_substr($detail, 0, 255) : null,
                $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1',
            ]);
        } catch (Throwable $e) {
            error_log('[AuditLog error] ' . $e->getMessage());
        }
    }
}
