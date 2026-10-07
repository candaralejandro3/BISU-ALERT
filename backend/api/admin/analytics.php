<?php
/**
 * Admin Incident Analytics API Endpoint
 * ----------------------------------------------------------------------------
 * Delegates to AdminController::analytics()
 */

declare(strict_types=1);

require_once __DIR__ . '/../../controllers/AdminController.php';
AdminController::analytics();
