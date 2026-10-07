<?php
/**
 * BISU-Alert Central API Router
 * ----------------------------------------------------------------------------
 * Applies middleware pipeline (CORS, Security Headers) and dispatches incoming
 * requests to corresponding MVC controllers.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/../middleware/CorsMiddleware.php';
require_once __DIR__ . '/../middleware/SecurityMiddleware.php';
require_once __DIR__ . '/../controllers/AuthController.php';
require_once __DIR__ . '/../controllers/IncidentController.php';
require_once __DIR__ . '/../controllers/SosController.php';
require_once __DIR__ . '/../controllers/AdminController.php';
require_once __DIR__ . '/../controllers/AlertController.php';

// Apply global security and CORS headers
CorsMiddleware::handle();
SecurityMiddleware::handle();

// Resolve request path
$uri = $_SERVER['REQUEST_URI'] ?? '/';
$path = parse_url($uri, PHP_URL_PATH) ?? '/';

// Strip folder prefixes if hosted in subdirectory
$prefixes = ['/bisu-alert/backend/routes/api.php', '/backend/routes/api.php', '/api.php', '/bisu-alert/backend/api', '/backend/api'];
foreach ($prefixes as $prefix) {
    if (str_starts_with($path, $prefix)) {
        $path = substr($path, strlen($prefix));
        break;
    }
}
$path = '/' . trim($path, '/');
// Strip .php suffix if present
$path = preg_replace('/\.php$/', '', $path);

$verb = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

// Route Dispatch Table
switch ("{$verb} {$path}") {
    // Auth & Accounts
    case 'POST /auth/login':
        AuthController::login();
        break;
    case 'POST /auth/register':
        AuthController::register();
        break;
    case 'GET /auth/me':
        AuthController::me();
        break;
    case 'POST /auth/update_profile':
    case 'PATCH /auth/update_profile':
    case 'POST /users/update_profile':
        AuthController::updateProfile();
        break;
    case 'POST /auth/change_password':
        AuthController::changePassword();
        break;
    case 'POST /auth/logout':
        AuthController::logout();
        break;
    case 'POST /auth/delete_account':
    case 'DELETE /auth/delete_account':
        AuthController::deleteAccount();
        break;

    // Emergency SOS
    case 'POST /sos/activate':
        SosController::activate();
        break;
    case 'POST /sos/cancel':
        SosController::cancel();
        break;

    // Incidents
    case 'POST /incidents/create':
        IncidentController::create();
        break;
    case 'GET /incidents/list':
        IncidentController::list();
        break;
    case 'GET /incidents/my_reports':
        IncidentController::myReports();
        break;
    case 'POST /incidents/update_status':
    case 'PATCH /incidents/update_status':
        IncidentController::updateStatus();
        break;
    case 'GET /incidents/show':
        IncidentController::show();
        break;

    // Safety Broadcasts & Contacts
    case 'GET /alerts/active':
        AlertController::active();
        break;
    case 'GET /contacts':
    case 'GET /contacts/list':
        AlertController::contacts();
        break;

    // Administrative & Thesis Analytics
    case 'GET /admin/stats':
        AdminController::stats();
        break;
    case 'GET /admin/analytics':
        AdminController::analytics();
        break;
    case 'GET /admin/users':
        AdminController::users();
        break;

    default:
        // If query param action is passed, e.g. api.php?action=admin/analytics
        $action = query('action');
        if ($action === 'admin/analytics') {
            AdminController::analytics();
        } elseif ($action === 'admin/stats') {
            AdminController::stats();
        } elseif ($action === 'incidents/list') {
            IncidentController::list();
        }

        fail("Endpoint not found: {$verb} {$path}", 404, 'not_found');
}
