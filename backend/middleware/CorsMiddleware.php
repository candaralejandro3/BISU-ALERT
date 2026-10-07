<?php
/**
 * CORS Middleware
 * ----------------------------------------------------------------------------
 * Handles Cross-Origin Resource Sharing and browser preflight requests.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/config.php';

class CorsMiddleware
{
    public static function handle(): void
    {
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
        if (in_array('*', ALLOWED_ORIGINS, true)) {
            header('Access-Control-Allow-Origin: *');
        } elseif ($origin !== '' && in_array($origin, ALLOWED_ORIGINS, true)) {
            header('Access-Control-Allow-Origin: ' . $origin);
            header('Vary: Origin');
        }

        header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
        header('Access-Control-Max-Age: 86400');

        if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
            http_response_code(204);
            exit;
        }
    }
}
