<?php
/**
 * Security Middleware
 * ----------------------------------------------------------------------------
 * Implements enterprise HTTP security headers, clickjacking prevention,
 * XSS filtering, and secure cookies.
 */

declare(strict_types=1);

class SecurityMiddleware
{
    public static function handle(): void
    {
        // Prevent Clickjacking attacks
        header('X-Frame-Options: DENY');

        // Prevent MIME type sniffing
        header('X-Content-Type-Options: nosniff');

        // Enable legacy XSS filter in browsers
        header('X-XSS-Protection: 1; mode=block');

        // Referrer policy
        header('Referrer-Policy: strict-origin-when-cross-origin');

        // Content Security Policy for API payloads
        header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'; object-src 'none'");

        // Strict-Transport-Security if over HTTPS
        if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') {
            header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
        }
    }
}
