<?php
/**
 * GET api/contacts/list.php
 * ----------------------------------------------------------------------------
 * The emergency directory the app dials from. On-campus numbers sort first --
 * the clinic and the guard house are reachable in seconds, the municipal lines
 * are not.
 *
 * 200 -> { contacts: [{id, name, role, phone_number, is_on_campus}, ...] }
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';

require_method('GET');
require_auth();

$contacts = array_map(
    static fn (array $r): array => [
        'id'           => (int) $r['id'],
        'name'         => $r['name'],
        'role'         => $r['role_label'],
        'phone_number' => $r['phone_number'],
        'is_on_campus' => flag($r['is_on_campus']),
    ],
    db()->query('SELECT * FROM vw_emergency_directory')->fetchAll()
);

ok(['contacts' => $contacts]);
