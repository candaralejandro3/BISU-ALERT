<?php
/**
 * Role-Based Access Control (RBAC) Middleware
 * ----------------------------------------------------------------------------
 * Restricts administrative and dispatch routes. Ensures student and visitor
 * accounts are strictly rejected with 403 Forbidden on privileged actions.
 */

declare(strict_types=1);

require_once __DIR__ . '/AuthMiddleware.php';

class RoleMiddleware
{
    /**
     * Strictly limits access to users with is_admin = 1 or role_id = 'admin'.
     * Returns 403 Forbidden for students, faculty, or responders without admin rights.
     */
    public static function requireAdmin(): array
    {
        $user = AuthMiddleware::authenticate();

        $isAdmin = (!empty($user['is_admin']) && (int)$user['is_admin'] === 1) ||
                   ($user['role_id'] ?? '') === 'admin';

        if (!$isAdmin) {
            fail('Access forbidden: Administrative privileges required.', 403, 'forbidden');
        }

        return $user;
    }

    /**
     * Restricts access to emergency responders, security officers, or clinic medics.
     */
    public static function requireResponder(): array
    {
        $user = AuthMiddleware::authenticate();

        $canRespond = (!empty($user['can_respond']) && (int)$user['can_respond'] === 1) ||
                      in_array($user['role_id'] ?? '', ['admin', 'security', 'medical'], true);

        if (!$canRespond) {
            fail('Access forbidden: Campus responder or security privileges required.', 403, 'forbidden');
        }

        return $user;
    }

    /**
     * Checks if the authenticated user has any of the listed roles.
     */
    public static function requireRole(string ...$roles): array
    {
        $user = AuthMiddleware::authenticate();

        if (!in_array($user['role_id'] ?? '', $roles, true)) {
            fail('Access forbidden: Your campus account role does not have permission for this resource.', 403, 'forbidden');
        }

        return $user;
    }
}
