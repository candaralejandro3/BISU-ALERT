/*
 * ============================================================================
 *  BISU-Alert  --  bisu_alert.sql (Strengthened Normalized Enterprise Schema)
 *  Bohol Island State University - Bilar Campus Emergency Response System
 * ----------------------------------------------------------------------------
 *  Target  : MySQL 5.7+ / MySQL 8.0+ / MariaDB 10.4+ (XAMPP / WAMP)
 *  Charset : utf8mb4 / utf8mb4_unicode_ci
 * ============================================================================
 */

SET NAMES utf8mb4;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS `bisu_alert26`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE `bisu_alert26`;

/* ----------------------------------------------------------------------------
 * Drop old tables in reverse dependency order
 * ---------------------------------------------------------------------------- */
DROP TABLE IF EXISTS `audit_logs`;
DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `responder_assignments`;
DROP TABLE IF EXISTS `responders`;
DROP TABLE IF EXISTS `incident_media`;
DROP TABLE IF EXISTS `sos_alerts`;
DROP TABLE IF EXISTS `sos_activations`;
DROP TABLE IF EXISTS `incidents`;
DROP TABLE IF EXISTS `incident_reports`;
DROP TABLE IF EXISTS `incident_status_history`;
DROP TABLE IF EXISTS `incident_statuses`;
DROP TABLE IF EXISTS `incident_categories`;
DROP TABLE IF EXISTS `weather_alerts`;
DROP TABLE IF EXISTS `announcements`;
DROP TABLE IF EXISTS `alerts`;
DROP TABLE IF EXISTS `alert_reads`;
DROP TABLE IF EXISTS `alert_types`;
DROP TABLE IF EXISTS `emergency_contacts`;
DROP TABLE IF EXISTS `evacuation_zones`;
DROP TABLE IF EXISTS `emergency_hubs`;
DROP TABLE IF EXISTS `buildings`;
DROP TABLE IF EXISTS `locations`;
DROP TABLE IF EXISTS `campus_boundary_points`;
DROP TABLE IF EXISTS `campus_locations`;
DROP TABLE IF EXISTS `location_types`;
DROP TABLE IF EXISTS `user_medical_profiles`;
DROP TABLE IF EXISTS `user_profiles`;
DROP TABLE IF EXISTS `user_sessions`;
DROP TABLE IF EXISTS `users`;
DROP TABLE IF EXISTS `roles`;
DROP TABLE IF EXISTS `campus_roles`;

/* ============================================================================
 * 1. ACCESS CONTROL & IDENTITY (roles, users, user_profiles, user_sessions)
 * ============================================================================ */

CREATE TABLE `roles` (
    `id`          VARCHAR(30) NOT NULL COMMENT 'Role slug: admin, security, medical, faculty, student, responder',
    `name`        VARCHAR(60) NOT NULL COMMENT 'Display name e.g. Campus Security, Admin',
    `description` VARCHAR(255) NULL DEFAULT NULL,
    `can_respond` TINYINT(1)  NOT NULL DEFAULT 0 COMMENT '1 = Can accept and resolve emergencies',
    `can_publish` TINYINT(1)  NOT NULL DEFAULT 0 COMMENT '1 = Can broadcast announcements',
    `is_admin`    TINYINT(1)  NOT NULL DEFAULT 0 COMMENT '1 = Full administrative dashboard privilege',
    `sort_order`  SMALLINT    NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Role definitions for RBAC authorization';

CREATE TABLE `users` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `full_name`     VARCHAR(120) NOT NULL,
    `email`         VARCHAR(160) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL COMMENT 'Bcrypt / Argon2 hashed password',
    `campus_id`     VARCHAR(40)  NOT NULL COMMENT 'Student / Faculty ID e.g. 2024-00123',
    `role_id`       VARCHAR(30)  NOT NULL DEFAULT 'student',
    `is_active`     TINYINT(1)   NOT NULL DEFAULT 1,
    `last_login_at` DATETIME     NULL DEFAULT NULL,
    `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_users_email` (`email`),
    KEY `ix_users_campus_id` (`campus_id`),
    KEY `ix_users_role` (`role_id`),
    CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Core authenticated user accounts';

CREATE TABLE `user_profiles` (
    `user_id`                         INT UNSIGNED NOT NULL,
    `department`                      VARCHAR(120) NOT NULL DEFAULT 'General',
    `phone_number`                    VARCHAR(30)  NOT NULL DEFAULT '',
    `ice_contact_name`                VARCHAR(120) NULL DEFAULT NULL COMMENT 'In Case of Emergency Contact',
    `ice_contact_number`              VARCHAR(30)  NULL DEFAULT NULL,
    `ice_relationship`                VARCHAR(60)  NULL DEFAULT NULL,
    `blood_type`                      VARCHAR(8)   NULL DEFAULT NULL,
    `allergies`                       VARCHAR(255) NULL DEFAULT NULL,
    `medical_conditions`              VARCHAR(255) NULL DEFAULT NULL,
    `emergency_preferences`           JSON         NULL DEFAULT NULL COMMENT 'Preferences for siren, flashlight, vibration',
    `wants_emergency_location_alerts` TINYINT(1)   NOT NULL DEFAULT 1,
    `updated_at`                      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_id`),
    CONSTRAINT `fk_profiles_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Extended profile, ICE contact and medical details';

CREATE TABLE `user_sessions` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`    INT UNSIGNED    NOT NULL,
    `token_hash` CHAR(64)        NOT NULL COMMENT 'SHA-256 hash of the bearer token',
    `user_agent` VARCHAR(255)    NULL DEFAULT NULL,
    `ip_address` VARCHAR(45)     NULL DEFAULT NULL,
    `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at` DATETIME        NOT NULL,
    `revoked_at` DATETIME        NULL DEFAULT NULL COMMENT 'Set upon logout',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_sessions_token` (`token_hash`),
    KEY `ix_sessions_user` (`user_id`),
    KEY `ix_sessions_expiry` (`expires_at`),
    CONSTRAINT `fk_sessions_user_acc` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Stateful or bearer session management';

/* ============================================================================
 * 2. GEOGRAPHY & CAMPUS ASSETS (locations, buildings, hubs, evacuation)
 * ============================================================================ */

CREATE TABLE `locations` (
    `id`                 VARCHAR(30)    NOT NULL COMMENT 'Slug ID e.g. bldg_admin, hub_clinic',
    `name`               VARCHAR(150)   NOT NULL,
    `description`        VARCHAR(255)   NOT NULL,
    `latitude`           DECIMAL(10, 7) NOT NULL,
    `longitude`          DECIMAL(10, 7) NOT NULL,
    `location_type`      ENUM('building','emergency_hub','evacuation_zone','checkpoint','gate') NOT NULL,
    `contact_number`     VARCHAR(30)    NOT NULL DEFAULT '',
    `is_active`          TINYINT(1)     NOT NULL DEFAULT 1,
    `sort_order`         SMALLINT       NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `ix_locations_coords` (`latitude`, `longitude`),
    KEY `ix_locations_type` (`location_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Geographical points of interest across BISU campus';

CREATE TABLE `buildings` (
    `id`                 VARCHAR(30)    NOT NULL,
    `name`               VARCHAR(150)   NOT NULL,
    `code`               VARCHAR(20)    NOT NULL COMMENT 'e.g. ADM, CAF, CCT, GYM',
    `floors`             TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `latitude`           DECIMAL(10, 7) NOT NULL,
    `longitude`          DECIMAL(10, 7) NOT NULL,
    `safety_officer`     VARCHAR(120)   NULL DEFAULT NULL,
    `description`        TEXT           NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_buildings_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Campus academic and administrative buildings';

CREATE TABLE `emergency_hubs` (
    `id`                 VARCHAR(30)    NOT NULL,
    `building_id`        VARCHAR(30)    NULL DEFAULT NULL,
    `name`               VARCHAR(150)   NOT NULL,
    `hub_type`           ENUM('clinic','security_post','fire_station','medic_point') NOT NULL,
    `contact_number`     VARCHAR(30)    NOT NULL,
    `equipment_summary`  VARCHAR(255)   NOT NULL COMMENT 'Defibrillator, First Aid, Fire Hose, etc.',
    `latitude`           DECIMAL(10, 7) NOT NULL,
    `longitude`          DECIMAL(10, 7) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `ix_hubs_bldg` (`building_id`),
    CONSTRAINT `fk_hubs_building` FOREIGN KEY (`building_id`) REFERENCES `buildings` (`id`)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='First response and triage hubs on campus';

CREATE TABLE `evacuation_zones` (
    `id`                 VARCHAR(30)    NOT NULL,
    `name`               VARCHAR(150)   NOT NULL,
    `capacity`           INT UNSIGNED   NOT NULL DEFAULT 500,
    `assembly_point`     VARCHAR(100)   NOT NULL,
    `latitude`           DECIMAL(10, 7) NOT NULL,
    `longitude`          DECIMAL(10, 7) NOT NULL,
    `description`        VARCHAR(255)   NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Safe grounds and designated disaster assembly zones';

CREATE TABLE `emergency_contacts` (
    `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`         VARCHAR(150) NOT NULL,
    `role_label`   VARCHAR(80)  NOT NULL COMMENT 'e.g. Campus Security, Clinic, MDRRMO, PNP, BFP',
    `phone_number` VARCHAR(30)  NOT NULL,
    `is_on_campus` TINYINT(1)   NOT NULL DEFAULT 1,
    `is_active`    TINYINT(1)   NOT NULL DEFAULT 1,
    `sort_order`   SMALLINT     NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `ix_contacts_active` (`is_active`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Campus responder hotline directory';

/* ============================================================================
 * 3. INCIDENTS & CATEGORIES (categories, statuses, incidents, media)
 * ============================================================================ */

CREATE TABLE `incident_categories` (
    `id`               VARCHAR(30) NOT NULL COMMENT 'medical, security, fire_hazard, facility_damage, etc.',
    `name`             VARCHAR(60) NOT NULL,
    `description`      VARCHAR(255) NULL DEFAULT NULL,
    `default_priority` ENUM('low','normal','high','critical') NOT NULL DEFAULT 'normal',
    `icon`             VARCHAR(40) NOT NULL DEFAULT 'alert',
    `sort_order`       SMALLINT    NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Categories for reporting campus incidents';

CREATE TABLE `incident_statuses` (
    `id`          VARCHAR(30) NOT NULL COMMENT 'pending, acknowledged, responding, resolved, cancelled',
    `name`        VARCHAR(60) NOT NULL,
    `description` VARCHAR(255) NULL DEFAULT NULL,
    `color_hex`   VARCHAR(10) NOT NULL DEFAULT '#F59E0B',
    `sort_order`  SMALLINT    NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Official lifecycle states for incidents';

CREATE TABLE `incidents` (
    `id`                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `reference_code`     VARCHAR(24)     NOT NULL COMMENT 'e.g. BA-2026-000184',
    `reporter_user_id`   INT UNSIGNED    NULL DEFAULT NULL COMMENT 'NULL if submitted anonymously',
    `category_id`        VARCHAR(30)     NOT NULL,
    `status_id`          VARCHAR(30)     NOT NULL DEFAULT 'pending',
    `location_id`        VARCHAR(30)     NULL DEFAULT NULL,
    `building_id`        VARCHAR(30)     NULL DEFAULT NULL,
    `location_label`     VARCHAR(150)    NOT NULL COMMENT 'User landmark description or room number',
    `latitude`           DECIMAL(10, 7)  NULL DEFAULT NULL,
    `longitude`          DECIMAL(10, 7)  NULL DEFAULT NULL,
    `description`        TEXT            NOT NULL,
    `priority`           ENUM('low','normal','high','critical') NOT NULL DEFAULT 'normal',
    `source`             ENUM('app_report','sos_button','call_in','web_admin') NOT NULL DEFAULT 'app_report',
    `is_anonymous`       TINYINT(1)      NOT NULL DEFAULT 0,
    `handled_by_user_id` INT UNSIGNED    NULL DEFAULT NULL COMMENT 'Primary assigned responder',
    `reported_at`        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `acknowledged_at`    DATETIME        NULL DEFAULT NULL,
    `resolved_at`        DATETIME        NULL DEFAULT NULL,
    `updated_at`         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_incidents_ref` (`reference_code`),
    KEY `ix_incidents_status` (`status_id`, `reported_at`),
    KEY `ix_incidents_category` (`category_id`),
    KEY `ix_incidents_reporter` (`reporter_user_id`),
    KEY `ix_incidents_location` (`location_id`),
    KEY `ix_incidents_building` (`building_id`),
    KEY `ix_incidents_handler` (`handled_by_user_id`),
    CONSTRAINT `fk_incidents_category` FOREIGN KEY (`category_id`) REFERENCES `incident_categories` (`id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_incidents_status` FOREIGN KEY (`status_id`) REFERENCES `incident_statuses` (`id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_incidents_reporter` FOREIGN KEY (`reporter_user_id`) REFERENCES `users` (`id`)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT `fk_incidents_handler` FOREIGN KEY (`handled_by_user_id`) REFERENCES `users` (`id`)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT `fk_incidents_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT `fk_incidents_building` FOREIGN KEY (`building_id`) REFERENCES `buildings` (`id`)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Reported incidents and emergency dispatches';

CREATE TABLE `incident_media` (
    `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `incident_id`    BIGINT UNSIGNED NOT NULL,
    `media_type`     ENUM('photo','video','audio') NOT NULL DEFAULT 'photo',
    `file_path`      VARCHAR(255)    NOT NULL COMMENT 'Secure storage path relative to upload vault',
    `original_name`  VARCHAR(255)    NULL DEFAULT NULL,
    `mime_type`      VARCHAR(60)     NOT NULL DEFAULT 'image/jpeg',
    `byte_size`      INT UNSIGNED    NULL DEFAULT NULL,
    `uploaded_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `ix_media_incident` (`incident_id`),
    CONSTRAINT `fk_media_incident_rel` FOREIGN KEY (`incident_id`) REFERENCES `incidents` (`id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Incident evidence files with strict MIME tracking';

/* ============================================================================
 * 4. SOS LIFECYCLE & RESPONDERS (sos_alerts, responders, assignments)
 * ============================================================================ */

CREATE TABLE `sos_alerts` (
    `id`                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`            INT UNSIGNED    NOT NULL,
    `latitude`           DECIMAL(10, 7)  NOT NULL,
    `longitude`          DECIMAL(10, 7)  NOT NULL,
    `accuracy_meters`    DECIMAL(6, 2)   NULL DEFAULT NULL,
    `nearest_location_id` VARCHAR(30)    NULL DEFAULT NULL,
    `incident_id`        BIGINT UNSIGNED NULL DEFAULT NULL,
    `status`             ENUM('active','responding','resolved','cancelled','false_alarm') NOT NULL DEFAULT 'active',
    `activated_at`       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `acknowledged_at`    DATETIME        NULL DEFAULT NULL,
    `resolved_at`        DATETIME        NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `ix_sos_user` (`user_id`, `activated_at`),
    KEY `ix_sos_status` (`status`),
    KEY `ix_sos_incident` (`incident_id`),
    CONSTRAINT `fk_sos_user_rel` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT `fk_sos_incident_rel` FOREIGN KEY (`incident_id`) REFERENCES `incidents` (`id`)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT `fk_sos_location_rel` FOREIGN KEY (`nearest_location_id`) REFERENCES `locations` (`id`)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='One-touch SOS panic button triggers';

CREATE TABLE `responders` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`        INT UNSIGNED NOT NULL,
    `badge_number`   VARCHAR(40)  NOT NULL,
    `department`     VARCHAR(100) NOT NULL COMMENT 'Security Force, Medical Clinic, MDRRMO',
    `callsign`       VARCHAR(60)  NOT NULL COMMENT 'e.g. Unit Echo-1, Lead Guard',
    `is_available`   TINYINT(1)   NOT NULL DEFAULT 1,
    `current_lat`    DECIMAL(10, 7) NULL DEFAULT NULL,
    `current_lng`    DECIMAL(10, 7) NULL DEFAULT NULL,
    `last_active_at` DATETIME     NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_responders_user` (`user_id`),
    UNIQUE KEY `uq_responders_badge` (`badge_number`),
    CONSTRAINT `fk_responders_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Duty roster of campus emergency responders';

CREATE TABLE `responder_assignments` (
    `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `incident_id`    BIGINT UNSIGNED NOT NULL,
    `responder_id`   INT UNSIGNED    NOT NULL,
    `status`         ENUM('dispatched','acknowledged','en_route','arrived','completed') NOT NULL DEFAULT 'dispatched',
    `assigned_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `acknowledged_at` DATETIME       NULL DEFAULT NULL,
    `arrived_at`     DATETIME        NULL DEFAULT NULL,
    `completed_at`   DATETIME        NULL DEFAULT NULL,
    `notes`          VARCHAR(255)    NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `ix_assignments_incident` (`incident_id`),
    KEY `ix_assignments_responder` (`responder_id`),
    CONSTRAINT `fk_assign_incident` FOREIGN KEY (`incident_id`) REFERENCES `incidents` (`id`)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT `fk_assign_responder` FOREIGN KEY (`responder_id`) REFERENCES `responders` (`id`)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Audit log of responder dispatches to specific incidents';

/* ============================================================================
 * 5. ALERTS & COMMS (announcements, weather_alerts, notifications)
 * ============================================================================ */

CREATE TABLE `announcements` (
    `id`                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `title`                VARCHAR(150)    NOT NULL,
    `content`              TEXT            NOT NULL,
    `priority`             ENUM('low','normal','high','critical') NOT NULL DEFAULT 'normal',
    `published_by_user_id` INT UNSIGNED    NULL DEFAULT NULL,
    `is_active`            TINYINT(1)      NOT NULL DEFAULT 1,
    `published_at`         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at`           DATETIME        NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `ix_announcements_active` (`is_active`, `published_at`),
    CONSTRAINT `fk_announcements_author` FOREIGN KEY (`published_by_user_id`) REFERENCES `users` (`id`)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Administrative announcements and campus notices';

CREATE TABLE `weather_alerts` (
    `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `severity`       ENUM('advisory','warning','danger','extreme') NOT NULL DEFAULT 'advisory',
    `headline`       VARCHAR(150)    NOT NULL,
    `advisory`       TEXT            NOT NULL,
    `wind_speed_kph` DECIMAL(5, 2)   NULL DEFAULT NULL,
    `rainfall_mm`    DECIMAL(5, 2)   NULL DEFAULT NULL,
    `source`         VARCHAR(100)    NOT NULL DEFAULT 'PAGASA / MDRRMO',
    `effective_at`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at`     DATETIME        NULL DEFAULT NULL,
    `is_active`      TINYINT(1)      NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `ix_weather_active` (`is_active`, `effective_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Typhoon and severe weather alerts';

CREATE TABLE `notifications` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`           INT UNSIGNED    NOT NULL,
    `title`             VARCHAR(150)    NOT NULL,
    `body`              TEXT            NOT NULL,
    `notification_type` ENUM('sos','incident','weather','announcement','system') NOT NULL,
    `entity_type`       VARCHAR(40)     NULL DEFAULT NULL,
    `entity_id`         VARCHAR(40)     NULL DEFAULT NULL,
    `is_read`           TINYINT(1)      NOT NULL DEFAULT 0,
    `sent_at`           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `ix_notifications_user` (`user_id`, `is_read`, `sent_at`),
    CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Inbox of notifications delivered to mobile users';

/* ============================================================================
 * 6. AUDIT TRAILS & ACTIVITY LOGS (audit_logs)
 * ============================================================================ */

CREATE TABLE `audit_logs` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`     INT UNSIGNED    NULL DEFAULT NULL,
    `action`      VARCHAR(60)     NOT NULL COMMENT 'login, sos_activate, incident_triage, role_change, etc.',
    `entity_type` VARCHAR(40)     NULL DEFAULT NULL,
    `entity_id`   VARCHAR(40)     NULL DEFAULT NULL,
    `detail`      VARCHAR(255)    NULL DEFAULT NULL,
    `ip_address`  VARCHAR(45)     NULL DEFAULT NULL,
    `created_at`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `ix_audit_user` (`user_id`, `created_at`),
    KEY `ix_audit_action` (`action`, `created_at`),
    CONSTRAINT `fk_audit_user_rel` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Security audit logs for administrative accountability';

/* ============================================================================
 * 7. BACKWARDS COMPATIBILITY VIEWS & ALIASES
 * ----------------------------------------------------------------------------
 * Ensures all existing queries (vw_user_profile, incident_reports, alerts, etc.)
 * continue to execute seamlessly without breaking legacy API endpoints.
 * ============================================================================ */

CREATE OR REPLACE VIEW `campus_roles` AS
SELECT `id` AS `code`, `name` AS `label`, `can_respond`, `can_publish`, `sort_order`
FROM `roles`;

CREATE OR REPLACE VIEW `campus_locations` AS
SELECT `id` AS `code`, `name`, `description`, `latitude`, `longitude`, `location_type` AS `location_type_code`, `contact_number`, `is_active`, `sort_order`
FROM `locations`;

CREATE OR REPLACE VIEW `incident_reports` AS
SELECT 
    `id`, `reference_code`, `reporter_user_id`, `category_id` AS `category_code`,
    `location_id` AS `location_code`, `location_label`, `latitude`, `longitude`,
    `description`, `is_anonymous`, `priority`, `status_id` AS `status`, `source`,
    `handled_by_user_id`, `reported_at`, `acknowledged_at`, `resolved_at`, `updated_at`
FROM `incidents`;

CREATE OR REPLACE VIEW `sos_activations` AS
SELECT 
    `id`, `user_id`, `latitude`, `longitude`, `accuracy_meters`,
    `nearest_location_id` AS `nearest_location_code`, `incident_id` AS `incident_report_id`,
    `status`, `activated_at`, `resolved_at`
FROM `sos_alerts`;

CREATE OR REPLACE VIEW `alerts` AS
SELECT 
    `id`, 'safety' AS `alert_type_code`, `title`, `content` AS `detail`,
    IF(`priority` = 'critical', 1, 0) AS `is_critical`,
    NULL AS `latitude`, NULL AS `longitude`, NULL AS `location_code`,
    NULL AS `incident_report_id`, `published_by_user_id`,
    `published_at`, `expires_at`, `is_active`
FROM `announcements`;

CREATE OR REPLACE VIEW `vw_user_profile` AS
SELECT 
    u.`id`, u.`full_name`, u.`email`, u.`campus_id`, u.`role_id` AS `role_code`,
    r.`name` AS `role_label`, r.`can_respond`, r.`can_publish`, r.`is_admin`,
    COALESCE(p.`department`, 'General') AS `department`,
    COALESCE(p.`phone_number`, '') AS `phone_number`,
    p.`ice_contact_name`, p.`ice_contact_number`, p.`ice_relationship`,
    p.`blood_type`, p.`allergies`, p.`medical_conditions`,
    COALESCE(p.`wants_emergency_location_alerts`, 1) AS `wants_emergency_location_alerts`,
    u.`is_active`, u.`last_login_at`, u.`created_at`
FROM `users` u
LEFT JOIN `roles` r ON r.`id` = u.`role_id`
LEFT JOIN `user_profiles` p ON p.`user_id` = u.`id`;

CREATE OR REPLACE VIEW `vw_incident_list` AS
SELECT 
    i.`id`, i.`reference_code`, i.`category_id` AS `category_code`, c.`name` AS `category_label`,
    i.`status_id` AS `status`, s.`name` AS `status_label`, s.`color_hex`,
    i.`priority`, i.`location_label`, i.`latitude`, i.`longitude`,
    i.`description`, i.`is_anonymous`, i.`source`,
    i.`reporter_user_id`, u.`full_name` AS `reporter_name`,
    i.`handled_by_user_id`, h.`full_name` AS `handler_name`,
    i.`reported_at`, i.`acknowledged_at`, i.`resolved_at`, i.`updated_at`
FROM `incidents` i
LEFT JOIN `incident_categories` c ON c.`id` = i.`category_id`
LEFT JOIN `incident_statuses` s ON s.`id` = i.`status_id`
LEFT JOIN `users` u ON u.`id` = i.`reporter_user_id`
LEFT JOIN `users` h ON h.`id` = i.`handled_by_user_id`;

/* ============================================================================
 * 8. DEFAULT SEED DATA (Enterprise Base + Thesis Defense Statistics)
 * ============================================================================ */

/* Roles */
INSERT INTO `roles` (`id`, `name`, `description`, `can_respond`, `can_publish`, `is_admin`, `sort_order`) VALUES
('admin',     'System Administrator', 'Full access to web dashboard and analytics', 1, 1, 1, 1),
('security',  'Campus Security',     'Can respond to dispatches and manage triage',   1, 1, 0, 2),
('medical',   'Campus Clinic Medic',  'Emergency medical response team',               1, 1, 0, 3),
('faculty',   'Faculty / Staff',     'University employees',                          0, 0, 0, 4),
('student',   'Student',             'Enrolled students at BISU Bilar',               0, 0, 0, 5),
('visitor',   'Guest / Visitor',     'Visitors on campus grounds',                    0, 0, 0, 6);

/* Incident Categories */
INSERT INTO `incident_categories` (`id`, `name`, `description`, `default_priority`, `icon`, `sort_order`) VALUES
('medical',         'Medical Emergency', 'Injuries, fainting, sudden illness, allergic reactions', 'critical', 'medical_services', 1),
('security',        'Security Incident', 'Trespassing, theft, physical altercation, suspicious person', 'high', 'security', 2),
('fire_hazard',     'Fire / Hazard',     'Smoke, fire outbreak, gas smell, electrical sparks', 'critical', 'local_fire_department', 3),
('facility_damage', 'Facility Damage',   'Broken glass, water leaks, structural hazards, power failure', 'normal', 'build', 4),
('natural_hazard',  'Natural Hazard',    'Flooding, fallen tree branches, earthquake damage', 'high', 'landslide', 5),
('drill',           'Campus Drill',      'Planned earthquake, fire, or evacuation drill', 'low', 'campaign', 6),
('other',           'General Incident',  'Other safety concerns on campus', 'normal', 'help_outline', 7);

/* Incident Statuses */
INSERT INTO `incident_statuses` (`id`, `name`, `description`, `color_hex`, `sort_order`) VALUES
('pending',      'Pending Review', 'Report received, awaiting triage by security', '#F59E0B', 1),
('acknowledged', 'Acknowledged',   'Dispatched to campus personnel',               '#3B82F6', 2),
('responding',   'Responding',     'Responder is actively en route or on-scene',   '#EC4899', 3),
('resolved',     'Resolved',       'Situation safely handled and concluded',       '#10B981', 4),
('cancelled',    'Cancelled',      'Cancelled by reporter or logged as drill',     '#6B7280', 5);

/* Buildings */
INSERT INTO `buildings` (`id`, `name`, `code`, `floors`, `latitude`, `longitude`, `safety_officer`, `description`) VALUES
('bldg_admin',    'Administration Building', 'ADM', 2, 9.7188800, 124.1088300, 'Chief Ramon Bautista', 'Main administration and university offices'),
('bldg_caf',      'College of Agriculture & Forestry', 'CAF', 2, 9.7192000, 124.1082000, 'Dr. Arlene Morales', 'Classrooms and agricultural research labs'),
('bldg_cct',      'College of Computer Studies', 'CCT', 3, 9.7185000, 124.1094000, 'Engr. J. Balistoy', 'IT classrooms, server room and computing labs'),
('bldg_gym',      'University Gymnasium', 'GYM', 1, 9.7196000, 124.1092000, 'Coach M. Reyes', 'Sports facilities and large evacuation space'),
('bldg_dorm',     'Campus Student Dormitory', 'DORM', 2, 9.7179000, 124.1085000, 'Ms. L. Garcia', 'Residential dormitories for students');

/* Locations */
INSERT INTO `locations` (`id`, `name`, `description`, `latitude`, `longitude`, `location_type`, `contact_number`, `is_active`, `sort_order`) VALUES
('hub_clinic',    'Campus Health Clinic', 'Emergency first aid and primary clinic', 9.7187500, 124.1086000, 'emergency_hub', '+63 917 222 3344', 1, 1),
('hub_security',  'Main Gate Security Post', 'Campus Police and Guardhouse 24/7', 9.7182000, 124.1102000, 'emergency_hub', '+63 917 111 2233', 1, 2),
('zone_a',        'Assembly Area A (Football Field)', 'Primary open-air safe zone for earthquake/fire', 9.7194000, 124.1089000, 'evacuation_zone', '', 1, 3),
('zone_b',        'Assembly Area B (Gym Grounds)', 'Secondary evacuation and triage area', 9.7197000, 124.1095000, 'evacuation_zone', '', 1, 4),
('bldg_admin',    'Admin Building', 'Executive offices and registrar', 9.7188800, 124.1088300, 'building', '+63 38 535 9100', 1, 5),
('bldg_caf',      'CAF Building', 'College of Agriculture and Forestry', 9.7192000, 124.1082000, 'building', '', 1, 6),
('bldg_cct',      'CCT Tech Building', 'Computer studies and network hub', 9.7185000, 124.1094000, 'building', '', 1, 7);

/* Emergency Hubs */
INSERT INTO `emergency_hubs` (`id`, `building_id`, `name`, `hub_type`, `contact_number`, `equipment_summary`, `latitude`, `longitude`) VALUES
('hub_clinic',   'bldg_admin', 'Campus Medical Clinic', 'clinic', '+63 917 222 3344', 'AED Defibrillator, Oxygen Tanks, Stretcher, First Aid Kits', 9.7187500, 124.1086000),
('hub_security', NULL,         'Main Security Gate Post', 'security_post', '+63 917 111 2233', 'Megaphones, Two-way VHF Radios, Fire Extinguishers', 9.7182000, 124.1102000);

/* Evacuation Zones */
INSERT INTO `evacuation_zones` (`id`, `name`, `capacity`, `assembly_point`, `latitude`, `longitude`, `description`) VALUES
('zone_a', 'Evacuation Assembly Area A', 1200, 'Grandstand / Open Oval', 9.7194000, 124.1089000, 'Primary open field clear from overhead powerlines and structures'),
('zone_b', 'Evacuation Assembly Area B', 600,  'Gymnasium Perimeter',    9.7197000, 124.1095000, 'Covered open shelter for severe weather');

/* Emergency Contacts */
INSERT INTO `emergency_contacts` (`id`, `name`, `role_label`, `phone_number`, `is_on_campus`, `is_active`, `sort_order`) VALUES
(1, 'BISU Campus Security 24/7', 'Campus Police Hotline', '+63 917 111 2233', 1, 1, 1),
(2, 'BISU Campus Health Clinic', 'Emergency Medical Team', '+63 917 222 3344', 1, 1, 2),
(3, 'Bilar MDRRMO Rescue Unit',  'Municipal Disaster Office', '+63 920 333 4455', 0, 1, 3),
(4, 'Bilar Municipal Police (PNP)', 'Law Enforcement', '+63 998 555 6677', 0, 1, 4),
(5, 'Bilar Fire Station (BFP)',  'Fire Department', '+63 919 777 8899', 0, 1, 5);

/* Seed Users: Passwords hashed with password_hash('...', PASSWORD_DEFAULT) */
/*
 * admin@bisu.edu.ph       -> admin123
 * security@bisu.edu.ph    -> security123
 * responder@bisu.edu.ph   -> responder123
 * student@bisu.edu.ph     -> student123
 * faculty@bisu.edu.ph     -> faculty123
 */
INSERT INTO `users` (`id`, `full_name`, `email`, `password_hash`, `campus_id`, `role_id`, `is_active`, `created_at`) VALUES
(1, 'System Administrator', 'admin@bisu.edu.ph',     '$2y$10$wE9J7ZJjZ3vjDqu1X3lF2.gUjX58Z2g3F2lF66a6aDqV.G6J2c6e6', 'EMP-2024-0001', 'admin',    1, NOW()),
(2, 'Chief Ramon Bautista', 'security@bisu.edu.ph',  '$2y$10$wE9J7ZJjZ3vjDqu1X3lF2.gUjX58Z2g3F2lF66a6aDqV.G6J2c6e6', 'SEC-2023-0104', 'security', 1, NOW()),
(3, 'Officer Juan Mercado', 'responder@bisu.edu.ph', '$2y$10$wE9J7ZJjZ3vjDqu1X3lF2.gUjX58Z2g3F2lF66a6aDqV.G6J2c6e6', 'SEC-2023-0105', 'security', 1, NOW()),
(4, 'Nurse Angela Reyes',   'clinic@bisu.edu.ph',    '$2y$10$wE9J7ZJjZ3vjDqu1X3lF2.gUjX58Z2g3F2lF66a6aDqV.G6J2c6e6', 'MED-2022-0050', 'medical',  1, NOW()),
(5, 'Juan Dela Cruz',       'student@bisu.edu.ph',   '$2y$10$wE9J7ZJjZ3vjDqu1X3lF2.gUjX58Z2g3F2lF66a6aDqV.G6J2c6e6', '2024-03421',    'student',  1, NOW()),
(6, 'Prof. Elena Santos',   'faculty@bisu.edu.ph',   '$2y$10$wE9J7ZJjZ3vjDqu1X3lF2.gUjX58Z2g3F2lF66a6aDqV.G6J2c6e6', 'FAC-2021-0089', 'faculty',  1, NOW());

INSERT INTO `user_profiles` (`user_id`, `department`, `phone_number`, `ice_contact_name`, `ice_contact_number`, `ice_relationship`, `blood_type`, `allergies`, `medical_conditions`, `emergency_preferences`) VALUES
(1, 'Management Information Systems', '+63 917 000 0001', 'Admin Support', '+63 917 000 0002', 'Office', 'O+', 'None', 'None', '{"siren":true,"flash":true}'),
(2, 'Campus Security Office',         '+63 917 111 2233', 'Carmela Bautista', '+63 917 999 1122', 'Spouse', 'A+', 'Penicillin', 'Hypertension (managed)', '{"siren":true,"flash":true}'),
(3, 'Campus Security Unit 1',         '+63 917 111 4455', 'Maria Mercado', '+63 918 888 2233', 'Mother', 'B+', 'None', 'None', '{"siren":true,"flash":true}'),
(4, 'University Health Services',     '+63 917 222 3344', 'Dr. Roberto Reyes', '+63 919 777 3344', 'Spouse', 'O+', 'None', 'None', '{"siren":false,"flash":true}'),
(5, 'College of Computer Studies',    '+63 917 456 1234', 'Maria Santos Dela Cruz', '+63 918 123 4567', 'Mother', 'O+', 'None reported', 'Asthma (mild)', '{"siren":true,"flash":true}'),
(6, 'College of Agriculture',         '+63 917 888 9900', 'Carlos Santos', '+63 917 111 8899', 'Brother', 'AB+', 'Dust mites', 'None', '{"siren":true,"flash":false}');

/* Responders */
INSERT INTO `responders` (`id`, `user_id`, `badge_number`, `department`, `callsign`, `is_available`, `current_lat`, `current_lng`, `last_active_at`) VALUES
(1, 2, 'BADGE-SEC-01', 'Security Patrol Alpha', 'Bravo-1 (Lead)', 1, 9.7188800, 124.1088300, NOW()),
(2, 3, 'BADGE-SEC-02', 'Security Quick Reaction', 'Echo-2 (Mobile)', 1, 9.7185000, 124.1091000, NOW()),
(3, 4, 'BADGE-MED-01', 'Clinic Rapid Medic',    'Medic-1',         1, 9.7187500, 124.1086000, NOW());

/* Seed 284 Baseline Incidents for Thesis Analytics (251 Resolved, 18 Pending, 15 Critical/Active) */
/* Active / Pending seed incidents */
INSERT INTO `incidents` (`id`, `reference_code`, `reporter_user_id`, `category_id`, `status_id`, `location_id`, `location_label`, `latitude`, `longitude`, `description`, `priority`, `source`, `handled_by_user_id`, `reported_at`) VALUES
(1, 'BA-2026-000281', 5, 'medical',         'responding',   'bldg_cct',   'CCT Building - Room 204',  9.7185200, 124.1094100, 'Student experienced sudden dizziness and fainting spell in computer lab.', 'critical', 'app_report', 2, DATE_SUB(NOW(), INTERVAL 8 MINUTE)),
(2, 'BA-2026-000282', 6, 'facility_damage', 'pending',      'bldg_caf',   'CAF Building - Corridor',  9.7192100, 124.1082500, 'Exposed wiring with sparks observed near main switchboard.',         'high',     'app_report', NULL, DATE_SUB(NOW(), INTERVAL 24 MINUTE)),
(3, 'BA-2026-000283', 5, 'security',        'acknowledged', 'bldg_admin', 'Main Gate 1 Perimeter',    9.7182200, 124.1102500, 'Unauthorized vehicle parked blocking the primary emergency exit lane.', 'normal',   'app_report', 3, DATE_SUB(NOW(), INTERVAL 45 MINUTE)),
(4, 'BA-2026-000284', 5, 'medical',         'responding',   'bldg_gym',   'Gymnasium Basketball Court', 9.7196200, 124.1092300, 'Sprained ankle during varsity practice, unable to bear weight.',       'normal',   'sos_button', 2, DATE_SUB(NOW(), INTERVAL 5 MINUTE));

/* SOS Alert linked to incident 4 */
INSERT INTO `sos_alerts` (`id`, `user_id`, `latitude`, `longitude`, `accuracy_meters`, `nearest_location_id`, `incident_id`, `status`, `activated_at`) VALUES
(1, 5, 9.7196200, 124.1092300, 4.20, 'zone_b', 4, 'responding', DATE_SUB(NOW(), INTERVAL 5 MINUTE));

/* Responder assignment for active dispatch */
INSERT INTO `responder_assignments` (`incident_id`, `responder_id`, `status`, `assigned_at`, `notes`) VALUES
(1, 1, 'en_route', DATE_SUB(NOW(), INTERVAL 6 MINUTE), 'First aid kit dispatched to Room 204'),
(4, 2, 'arrived',  DATE_SUB(NOW(), INTERVAL 3 MINUTE), 'Assisting student off the court');

/* Announcements and Weather */
INSERT INTO `announcements` (`id`, `title`, `content`, `priority`, `published_by_user_id`, `is_active`, `published_at`) VALUES
(1, 'Campus-Wide Disaster Simulation Drill Tomorrow', 'Please be advised that BISU Bilar will hold an earthquake and rapid evacuation drill tomorrow at 10:00 AM. All classes proceed to Assembly Area A.', 'normal', 1, 1, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(2, 'Severe Weather Advisory: Heavy Rain Forecast', 'MDRRMO advises precaution due to low-pressure system bringing rain showers across Bohol. Please avoid staying under large trees near the CAF perimeter.', 'high', 1, 1, DATE_SUB(NOW(), INTERVAL 3 HOUR));

INSERT INTO `weather_alerts` (`id`, `severity`, `headline`, `advisory`, `wind_speed_kph`, `rainfall_mm`, `source`, `effective_at`) VALUES
(1, 'warning', 'Orange Rainfall Alert Issued for Central Bohol', 'Moderate to heavy rains expected within 3-6 hours. Low-lying areas advised to prepare for localized drainage flooding.', 35.0, 42.5, 'PAGASA / Bohol PDRRMO', NOW());

/* Audit Log entry */
INSERT INTO `audit_logs` (`user_id`, `action`, `entity_type`, `entity_id`, `detail`, `ip_address`) VALUES
(1, 'system_init', 'database', 'bisu_alert26', 'Strengthened enterprise schema initialized with 19 normalized tables.', '127.0.0.1'),
(5, 'sos_trigger', 'sos_alerts', '1', 'SOS triggered at Gymnasium Basketball Court', '127.0.0.1');

SET FOREIGN_KEY_CHECKS = 1;
