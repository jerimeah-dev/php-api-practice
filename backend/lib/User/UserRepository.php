<?php

namespace lib\User;

use lib\Utils\Database;
use PDO;

class UserRepository
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::get();
        $this->db->exec("CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            name TEXT,
            birthday INTEGER,
            bio TEXT,
            websiteUrl TEXT,
            followersCount INTEGER NOT NULL DEFAULT 0,
            followingCount INTEGER NOT NULL DEFAULT 0,
            postsCount INTEGER NOT NULL DEFAULT 0,
            createdAt INTEGER NOT NULL,
            education TEXT NOT NULL DEFAULT '[]',
            workExperience TEXT NOT NULL DEFAULT '[]',
            profileImages TEXT NOT NULL DEFAULT '[]'
        )");
    }

    // ✅ CREATE
    public function create(UserEntity $user): bool
    {
        $stmt = $this->db->prepare(
            "INSERT INTO users 
            (id, email, password, name, birthday, bio, websiteUrl, followersCount, followingCount, postsCount, createdAt, education, workExperience, profileImages)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        );

        return $stmt->execute([
            $user->id,
            $user->email,
            $user->password,
            $user->name,
            $user->birthday,
            $user->bio,
            $user->websiteUrl,
            $user->followersCount,
            $user->followingCount,
            $user->postsCount,
            $user->createdAt,
            json_encode($user->education),
            json_encode($user->workExperience),
            json_encode($user->profileImages)
        ]);
    }

    // ✅ FIND BY ID
    public function findById(string $id): ?array
    {
        $stmt = $this->db->prepare("SELECT * FROM users WHERE id = ?");
        $stmt->execute([$id]);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    // ✅ FIND BY EMAIL
    public function findByEmail(string $email): ?array
    {
        $stmt = $this->db->prepare("SELECT * FROM users WHERE email = ?");
        $stmt->execute([$email]);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    // ✅ CHECK EXISTENCE
    public function existsById(string $id): bool
    {
        $stmt = $this->db->prepare("SELECT id FROM users WHERE id = ?");
        $stmt->execute([$id]);
        return (bool)$stmt->fetch();
    }

    public function existsByEmail(string $email): bool
    {
        $stmt = $this->db->prepare("SELECT email FROM users WHERE email = ?");
        $stmt->execute([$email]);
        return (bool)$stmt->fetch();
    }

    // ✅ UPDATE BY ID
    public function updateById(UserEntity $user): bool
    {
        $stmt = $this->db->prepare(
            "UPDATE users SET 
            email = ?, password = ?, name = ?, birthday = ?, bio = ?, websiteUrl = ?, 
            followersCount = ?, followingCount = ?, postsCount = ?, education = ?, workExperience = ?, profileImages = ? 
            WHERE id = ?"
        );

        return $stmt->execute([
            $user->email,
            $user->password,
            $user->name,
            $user->birthday,
            $user->bio,
            $user->websiteUrl,
            $user->followersCount,
            $user->followingCount,
            $user->postsCount,
            json_encode($user->education),
            json_encode($user->workExperience),
            json_encode($user->profileImages),
            $user->id
        ]);
    }

    // ✅ DELETE BY ID
    public function deleteById(string $id): bool
    {
        $stmt = $this->db->prepare("DELETE FROM users WHERE id = ?");
        return $stmt->execute([$id]);
    }

    // ✅ LIST ALL USERS
    public function getAll(): array
    {
        $stmt = $this->db->query("SELECT * FROM users");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}