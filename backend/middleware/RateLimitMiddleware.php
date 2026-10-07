<?php
/**
 * Rate Limiting Middleware
 * ----------------------------------------------------------------------------
 * Protects critical emergency endpoints (SOS activation and incident report
 * creation) from denial-of-service, accidental double-clicks, or flood attacks.
 *
 * Emits HTTP 429 Too Many Requests when limits are exceeded.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/config.php';

class RateLimitMiddleware
{
    private static string $storageDir = __DIR__ . '/../cache/ratelimits';

    private static function initStorage(): void
    {
        if (!is_dir(self::$storageDir)) {
            @mkdir(self::$storageDir, 0777, true);
        }
    }

    /**
     * Enforces sliding window rate limit.
     *
     * @param string $action Slug identifying endpoint (e.g. 'sos_activate', 'incident_create')
     * @param int $maxAttempts Allowed attempts within window
     * @param int $windowSeconds Duration of window in seconds
     */
    public static function check(string $action, int $maxAttempts = 5, int $windowSeconds = 60): void
    {
        self::initStorage();

        $clientIdentifier = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        if ($authHeader !== '') {
            $clientIdentifier .= '_' . hash('sha256', $authHeader);
        }

        $key = preg_replace('/[^a-zA-Z0-9_-]/', '_', $action . '_' . $clientIdentifier);
        $file = self::$storageDir . '/' . $key . '.json';
        $now = time();

        $history = [];
        if (file_exists($file)) {
            $content = @file_get_contents($file);
            if ($content) {
                $decoded = json_decode($content, true);
                if (is_array($decoded)) {
                    $history = array_filter($decoded, fn($ts) => is_int($ts) && ($now - $ts) < $windowSeconds);
                }
            }
        }

        if (count($history) >= $maxAttempts) {
            header('Retry-After: ' . $windowSeconds);
            fail(
                'Rate limit exceeded. Too many requests in a short time. Please wait ' . $windowSeconds . ' seconds.',
                429,
                'rate_limit_exceeded'
            );
        }

        $history[] = $now;
        @file_put_contents($file, json_encode($history));
    }

    public static function limitSos(): void
    {
        self::check('sos_activate', RATE_LIMIT_SOS_MAX, RATE_LIMIT_WINDOW);
    }

    public static function limitReport(): void
    {
        self::check('incident_create', RATE_LIMIT_REPORT_MAX, RATE_LIMIT_WINDOW);
    }
}
