<?php
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");

require_once __DIR__ . '/config/database.php';

try {
    $pdo = db();
    $dbName = $pdo->query("SELECT DATABASE()")->fetchColumn();
    $userCount = (int) $pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();

    echo json_encode([
        "success" => true,
        "message" => "MySQL connection successful",
        "database" => $dbName,
        "users_count" => $userCount
    ], JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "MySQL connection failed",
        "error" => $e->getMessage()
    ], JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
}

