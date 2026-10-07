<?php
/**
 * AlertController
 * ----------------------------------------------------------------------------
 * Serves active safety broadcasts, weather warnings, and emergency hotlines.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';

class AlertController
{
    public static function active(): never
    {
        require_method('GET');

        // Fetch announcements
        $stmt = db()->query(
            'SELECT * FROM announcements WHERE is_active = 1 ORDER BY published_at DESC LIMIT 20'
        );
        $announcements = $stmt->fetchAll();

        // Fetch weather alerts
        $stmtWeather = db()->query(
            'SELECT * FROM weather_alerts WHERE is_active = 1 ORDER BY effective_at DESC LIMIT 5'
        );
        $weather = $stmtWeather->fetchAll();

        ok([
            'alerts'  => array_map(fn($a) => [
                'id'           => (int)$a['id'],
                'title'        => $a['title'],
                'detail'       => $a['content'],
                'is_critical'  => ($a['priority'] === 'critical'),
                'published_at' => iso($a['published_at']),
            ], $announcements),
            'weather' => array_map(fn($w) => [
                'id'             => (int)$w['id'],
                'severity'       => $w['severity'],
                'headline'       => $w['headline'],
                'advisory'       => $w['advisory'],
                'wind_speed_kph' => isset($w['wind_speed_kph']) ? (float)$w['wind_speed_kph'] : null,
                'source'         => $w['source'],
                'effective_at'   => iso($w['effective_at']),
            ], $weather),
        ]);
    }

    public static function contacts(): never
    {
        require_method('GET');

        $stmt = db()->query(
            'SELECT * FROM emergency_contacts WHERE is_active = 1 ORDER BY sort_order ASC'
        );
        $rows = $stmt->fetchAll();

        ok(array_map(fn($c) => [
            'id'           => (int)$c['id'],
            'name'         => $c['name'],
            'role_label'   => $c['role_label'],
            'phone_number' => $c['phone_number'],
            'is_on_campus' => (bool)$c['is_on_campus'],
        ], $rows));
    }
}
