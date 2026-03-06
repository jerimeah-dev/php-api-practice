<?php

namespace lib\User;

use lib\Core\Repository;

class UserRepository extends Repository
{
    public function __construct()
    {
        parent::__construct();
        $this->createTable();
    }

    private function createTable(): void
    {
        $this->db->exec("CREATE TABLE IF NOT EXISTS users (
            id            TEXT    PRIMARY KEY,
            email         TEXT    NOT NULL UNIQUE,
            password      TEXT    NOT NULL,
            name          TEXT    NOT NULL DEFAULT '',
            avatarUrl     TEXT    NOT NULL DEFAULT '',
            profileImages TEXT    NOT NULL DEFAULT '[]',
            createdAt     INTEGER NOT NULL
        )");
        try { $this->db->exec("ALTER TABLE users ADD COLUMN avatarUrl TEXT NOT NULL DEFAULT ''"); } catch (\Throwable) {}
        try { $this->db->exec("ALTER TABLE users ADD COLUMN profileImages TEXT NOT NULL DEFAULT '[]'"); } catch (\Throwable) {}
    }

    public function create(UserEntity $user): bool
    {
        return (bool) $this->execute(
            "INSERT INTO users (id, email, password, name, avatarUrl, profileImages, createdAt)
             VALUES (?, ?, ?, ?, ?, ?, ?)",
            [$user->id, $user->email, $user->password, $user->name,
             $user->avatarUrl, json_encode($user->profileImages), $user->createdAt]
        );
    }

    public function findById(string $id): ?array
    {
        return $this->fetch("SELECT * FROM users WHERE id = ?", [$id]);
    }

    public function findByEmail(string $email): ?array
    {
        return $this->fetch("SELECT * FROM users WHERE email = ?", [$email]);
    }

    public function existsById(string $id): bool
    {
        return (bool) $this->fetch("SELECT id FROM users WHERE id = ?", [$id]);
    }

    public function existsByEmail(string $email): bool
    {
        return (bool) $this->fetch("SELECT id FROM users WHERE email = ?", [$email]);
    }

    public function updateById(UserEntity $user): bool
    {
        return (bool) $this->execute(
            "UPDATE users SET name = ?, avatarUrl = ?, profileImages = ? WHERE id = ?",
            [$user->name, $user->avatarUrl, json_encode($user->profileImages), $user->id]
        );
    }

    public function deleteById(string $id): bool
    {
        return (bool) $this->execute("DELETE FROM users WHERE id = ?", [$id]);
    }
}
