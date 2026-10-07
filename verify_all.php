<?php
require_once __DIR__ . '/backend/api/config/database.php';

try {
    $pdo = db();
    echo "=== DATABASE VERIFICATION ===\n";
    echo "[OK] Connected to database: " . $pdo->query("SELECT DATABASE()")->fetchColumn() . "\n";
    
    $users = $pdo->query("SELECT id, full_name, email, role_code, created_at FROM vw_user_profile")->fetchAll();
    echo "[OK] Total registered users in MySQL: " . count($users) . "\n";
    foreach ($users as $u) {
        echo "     #{$u['id']} - {$u['full_name']} ({$u['email']}) [{$u['role_code']}]\n";
    }
} catch (Throwable $e) {
    echo "[FAIL] " . $e->getMessage() . "\n";
}
