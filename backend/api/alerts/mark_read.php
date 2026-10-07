<?php
/**
 * POST api/alerts/mark_read.php
 * ----------------------------------------------------------------------------
 * Marks alerts as seen by the signed-in user, which is what drives the unread
 * badge returned by alerts/list.php.
 *
 * Body:
 *   alert_ids: [1, 2, 3]   -- or omit to mark every active alert read
 *
 * 200 -> { marked: n, unread_count: 0 }
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

require_method('POST');

$user   = require_auth();
$userId = (int) $user['id'];
$in     = body();

$ids = $in['alert_ids'] ?? null;

if ($ids === null) {
    // Mark all -- what tapping the bell icon does.
    $stmt = db()->prepare(
        'INSERT INTO alert_reads (alert_id, user_id)
         SELECT a.id, ? FROM vw_active_alerts a
         ON DUPLICATE KEY UPDATE read_at = read_at'
    );
    $stmt->execute([$userId]);
    $marked = $stmt->rowCount();
} else {
    if (!is_array($ids)) {
        fail('alert_ids must be an array of ids.', 422, 'invalid_field');
    }

    $ids = array_values(array_unique(array_filter(
        array_map(static fn ($id): int => (int) $id, $ids),
        static fn (int $id): bool => $id > 0
    )));

    if ($ids === []) {
        ok(['marked' => 0, 'unread_count' => 0]);
    }

    $placeholders = implode(', ', array_fill(0, count($ids), '?'));

    // The SELECT ... WHERE id IN (...) both filters to real alerts and skips
    // ids the caller made up, so a bad payload cannot create orphan read rows.
    $stmt = db()->prepare(
        "INSERT INTO alert_reads (alert_id, user_id)
         SELECT a.id, ? FROM alerts a WHERE a.id IN ($placeholders)
         ON DUPLICATE KEY UPDATE read_at = read_at"
    );
    $stmt->execute([$userId, ...$ids]);
    $marked = $stmt->rowCount();
}

$unread = db()->prepare(
    'SELECT COUNT(*)
     FROM vw_active_alerts a
     WHERE NOT EXISTS (
         SELECT 1 FROM alert_reads r WHERE r.alert_id = a.id AND r.user_id = ?
     )'
);
$unread->execute([$userId]);

ok([
    'marked'       => $marked,
    'unread_count' => (int) $unread->fetchColumn(),
]);
