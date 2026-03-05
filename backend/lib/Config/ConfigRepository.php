<?php

namespace lib\Config;

use lib\Utils\Database;
use PDO;

class ConfigRepository
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::get();
    }

    // ---------------- TABLE INSTALL ----------------
    public function installTable(): bool
    {
        $this->db->exec("DROP TABLE IF EXISTS configs");
        $this->db->exec("
            CREATE TABLE configs (
                id TEXT PRIMARY KEY,
                `key` TEXT UNIQUE NOT NULL,
                `value` TEXT
            )
        ");
        return true;
    }

    // ---------------- CREATE ----------------
    public function create(ConfigEntity $config): bool
    {
        if (!$config->id) {
            $config->id = bin2hex(random_bytes(8));
        }

        $stmt = $this->db->prepare(
            "INSERT INTO configs (id, `key`, `value`) VALUES (?, ?, ?)"
        );

        return $stmt->execute([
            $config->id,
            $config->key,
            $config->value
        ]);
    }

    // ---------------- FIND BY KEY ----------------
    public function findByKey(string $key): ?ConfigEntity
    {
        $stmt = $this->db->prepare("SELECT * FROM configs WHERE `key` = ?");
        $stmt->execute([$key]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$row) return null;

        $entity = new ConfigEntity();
        $entity->id = $row['id'];
        $entity->key = $row['key'];
        $entity->value = $row['value'];
        return $entity;
    }

    // ---------------- UPDATE BY KEY ----------------
    public function updateByKey(ConfigEntity $config): bool
    {
        $stmt = $this->db->prepare(
            "UPDATE configs SET `value` = ? WHERE `key` = ?"
        );

        return $stmt->execute([
            $config->value,
            $config->key
        ]);
    }

    // ---------------- LIST ALL ----------------
    public function getAll(): array
    {
        $stmt = $this->db->query("SELECT * FROM configs");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // ---------------- UPSERT ----------------
    public function upsert(string $key, string $value): ConfigEntity
    {
        $existing = $this->findByKey($key);

        $entity = $existing ?? new ConfigEntity();
        $entity->key = $key;
        $entity->value = $value;

        if ($existing) {
            $this->updateByKey($entity);
        } else {
            $this->create($entity);
        }

        return $this->findByKey($key);
    }
}