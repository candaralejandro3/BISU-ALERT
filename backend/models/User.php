<?php
/**
 * User Model
 * ----------------------------------------------------------------------------
 * Handles user identity, bcrypt password hashing, session tokens,
 * profile data, and security account operations.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/AuditLog.php';

class User
{
    public static function findByEmail(string $email): ?array
    {
        $stmt = db()->prepare('SELECT * FROM users WHERE email = ? LIMIT 1');
        $stmt->execute([strtolower(trim($email))]);
        $user = $stmt->fetch();
        return $user ?: null;
    }

    public static function findById(int $id): ?array
    {
        $stmt = db()->prepare(
            'SELECT u.*, r.name AS role_label, r.can_respond, r.can_publish, r.is_admin,
                    p.department, p.phone_number, p.ice_contact_name, p.ice_contact_number,
                    p.ice_relationship, p.blood_type, p.allergies, p.medical_conditions,
                    p.wants_emergency_location_alerts
             FROM users u
             LEFT JOIN roles r ON r.id = u.role_id
             LEFT JOIN user_profiles p ON p.user_id = u.id
             WHERE u.id = ? LIMIT 1'
        );
        $stmt->execute([$id]);
        $user = $stmt->fetch();
        return $user ?: null;
    }

    public static function register(array $data): array
    {
        $email = strtolower(trim($data['email']));
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            fail('Please provide a valid campus email address.', 422, 'invalid_email');
        }

        if (self::findByEmail($email) !== null) {
            fail('An account with this email is already registered.', 409, 'email_exists');
        }

        $password = (string)$data['password'];
        if (strlen($password) < 6) {
            fail('Password must be at least 6 characters.', 422, 'weak_password');
        }

        $passwordHash = password_hash($password, PASSWORD_DEFAULT);
        $fullName = trim($data['full_name']);
        $campusId = trim($data['campus_id'] ?? 'N/A');
        $roleId = in_array($data['role_id'] ?? 'student', ['student', 'faculty', 'staff', 'visitor'], true)
            ? $data['role_id']
            : 'student';

        $pdo = db();
        $pdo->beginTransaction();

        try {
            $stmt = $pdo->prepare(
                'INSERT INTO users (full_name, email, password_hash, campus_id, role_id, is_active, created_at)
                 VALUES (?, ?, ?, ?, ?, 1, NOW())'
            );
            $stmt->execute([$fullName, $email, $passwordHash, $campusId, $roleId]);
            $userId = (int)$pdo->lastInsertId();

            $stmtProfile = $pdo->prepare(
                'INSERT INTO user_profiles (user_id, department, phone_number, wants_emergency_location_alerts)
                 VALUES (?, ?, ?, ?)'
            );
            $stmtProfile->execute([
                $userId,
                $data['department'] ?? 'General',
                $data['phone_number'] ?? '',
                1,
            ]);

            $pdo->commit();
            AuditLog::log($userId, 'register', 'users', (string)$userId, 'Registered account ' . $email);

            return self::createSession($userId);
        } catch (Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    public static function login(string $email, string $password): array
    {
        $user = self::findByEmail($email);
        if (!$user || !password_verify($password, $user['password_hash'])) {
            fail('Invalid email or password.', 401, 'invalid_credentials');
        }

        if (empty($user['is_active'])) {
            fail('This account has been deactivated. Please contact campus security.', 403, 'account_disabled');
        }

        // Update last login
        $stmt = db()->prepare('UPDATE users SET last_login_at = NOW() WHERE id = ?');
        $stmt->execute([$user['id']]);

        AuditLog::log((int)$user['id'], 'login', 'users', (string)$user['id'], 'Signed in successfully');

        return self::createSession((int)$user['id']);
    }

    public static function createSession(int $userId): array
    {
        $token = bin2hex(random_bytes(32));
        $tokenHash = hash('sha256', $token);
        $expiresAt = date('Y-m-d H:i:s', time() + SESSION_EXPIRY_SECONDS);

        $stmt = db()->prepare(
            'INSERT INTO user_sessions (user_id, token_hash, user_agent, ip_address, expires_at)
             VALUES (?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $userId,
            $tokenHash,
            mb_substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 255),
            $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1',
            $expiresAt,
        ]);

        $profile = self::findById($userId);

        return [
            'token'      => $token,
            'expires_at' => iso($expiresAt),
            'user'       => self::formatUser($profile),
        ];
    }

    public static function updateProfile(int $userId, array $data): array
    {
        $stmt = db()->prepare(
            'INSERT INTO user_profiles (
                user_id, department, phone_number, ice_contact_name, ice_contact_number,
                ice_relationship, blood_type, allergies, medical_conditions, wants_emergency_location_alerts
             ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
                department = VALUES(department),
                phone_number = VALUES(phone_number),
                ice_contact_name = VALUES(ice_contact_name),
                ice_contact_number = VALUES(ice_contact_number),
                ice_relationship = VALUES(ice_relationship),
                blood_type = VALUES(blood_type),
                allergies = VALUES(allergies),
                medical_conditions = VALUES(medical_conditions),
                wants_emergency_location_alerts = VALUES(wants_emergency_location_alerts)'
        );

        $stmt->execute([
            $userId,
            $data['department'] ?? 'General',
            $data['phone_number'] ?? '',
            $data['ice_contact_name'] ?? null,
            $data['ice_contact_number'] ?? null,
            $data['ice_relationship'] ?? null,
            $data['blood_type'] ?? null,
            $data['allergies'] ?? null,
            $data['medical_conditions'] ?? null,
            isset($data['wants_emergency_location_alerts']) ? (int)$data['wants_emergency_location_alerts'] : 1,
        ]);

        if (!empty($data['campus_id'])) {
            $stmtUser = db()->prepare('UPDATE users SET campus_id = ? WHERE id = ?');
            $stmtUser->execute([$data['campus_id'], $userId]);
        }

        AuditLog::log($userId, 'update_profile', 'users', (string)$userId, 'Updated profile and ICE settings');

        $updated = self::findById($userId);
        return self::formatUser($updated);
    }

    public static function changePassword(int $userId, string $oldPassword, string $newPassword): void
    {
        $stmt = db()->prepare('SELECT password_hash FROM users WHERE id = ? LIMIT 1');
        $stmt->execute([$userId]);
        $row = $stmt->fetch();

        if (!$row || !password_verify($oldPassword, $row['password_hash'])) {
            fail('Your current password does not match.', 422, 'invalid_current_password');
        }

        if (strlen($newPassword) < 6) {
            fail('New password must be at least 6 characters long.', 422, 'weak_password');
        }

        $newHash = password_hash($newPassword, PASSWORD_DEFAULT);
        $update = db()->prepare('UPDATE users SET password_hash = ? WHERE id = ?');
        $update->execute([$newHash, $userId]);

        AuditLog::log($userId, 'change_password', 'users', (string)$userId, 'Password changed');
    }

    public static function deleteAccount(int $userId): void
    {
        $pdo = db();
        $pdo->beginTransaction();

        try {
            // Revoke all sessions
            $stmt1 = $pdo->prepare('DELETE FROM user_sessions WHERE user_id = ?');
            $stmt1->execute([$userId]);

            // Deactivate or soft-delete user to preserve audit trails
            $stmt2 = $pdo->prepare('UPDATE users SET is_active = 0, email = CONCAT(email, ".deleted.", UNIX_TIMESTAMP()) WHERE id = ?');
            $stmt2->execute([$userId]);

            $pdo->commit();
            AuditLog::log($userId, 'delete_account', 'users', (string)$userId, 'Account deactivated and sessions revoked');
        } catch (Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    public static function formatUser(?array $row): ?array
    {
        if (!$row) return null;
        return [
            'id'                              => (int)$row['id'],
            'full_name'                       => $row['full_name'],
            'email'                           => $row['email'],
            'campus_id'                       => $row['campus_id'] ?? '',
            'role_code'                       => $row['role_id'] ?? 'student',
            'role_label'                      => $row['role_label'] ?? ucfirst($row['role_id'] ?? 'Student'),
            'can_respond'                     => (bool)($row['can_respond'] ?? false),
            'can_publish'                     => (bool)($row['can_publish'] ?? false),
            'is_admin'                        => (bool)($row['is_admin'] ?? false),
            'department'                      => $row['department'] ?? 'General',
            'phone_number'                    => $row['phone_number'] ?? '',
            'ice_contact_name'                => $row['ice_contact_name'] ?? null,
            'ice_contact_number'              => $row['ice_contact_number'] ?? null,
            'ice_relationship'                => $row['ice_relationship'] ?? null,
            'blood_type'                      => $row['blood_type'] ?? null,
            'allergies'                       => $row['allergies'] ?? null,
            'medical_conditions'              => $row['medical_conditions'] ?? null,
            'wants_emergency_location_alerts' => (bool)($row['wants_emergency_location_alerts'] ?? true),
            'is_active'                       => (bool)($row['is_active'] ?? true),
            'created_at'                      => iso($row['created_at'] ?? null),
        ];
    }
}
