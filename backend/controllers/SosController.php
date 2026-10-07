<?php
/**
 * SosController
 * ----------------------------------------------------------------------------
 * Handles instant SOS panic triggers and alert cancellations.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/../models/SosAlert.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RateLimitMiddleware.php';

class SosController
{
    public static function activate(): never
    {
        require_method('POST');
        RateLimitMiddleware::limitSos();

        $user = AuthMiddleware::authenticate();
        $b = body();

        $lat = opt_coord($b, 'latitude', 90.0);
        $lng = opt_coord($b, 'longitude', 180.0);

        if ($lat === null || $lng === null) {
            fail('GPS latitude and longitude coordinates are required for SOS dispatch.', 422, 'missing_coordinates');
        }

        $accuracy = isset($b['accuracy_meters']) && is_numeric($b['accuracy_meters']) ? (float)$b['accuracy_meters'] : null;
        $landmark = opt_str($b, 'landmark', 150);

        $alert = SosAlert::activate((int)$user['id'], $lat, $lng, $accuracy, $landmark);
        ok($alert, 201);
    }

    public static function cancel(): never
    {
        require_method('POST');
        $user = AuthMiddleware::authenticate();
        $b = body();

        $sosId = (int)($b['sos_id'] ?? 0);
        if ($sosId <= 0) {
            fail('SOS ID is required.', 422, 'missing_sos_id');
        }

        $reason = opt_str($b, 'reason', 255) ?? 'Cancelled by user';
        SosAlert::cancel($sosId, (int)$user['id'], $reason);

        ok(['message' => 'SOS emergency alert has been cancelled.']);
    }
}
