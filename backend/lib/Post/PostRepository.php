<?php

namespace lib\Post;

use lib\Utils\Database;
use PDO;

class PostRepository
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::get();
        $this->db->exec("
            CREATE TABLE IF NOT EXISTS posts (
                id TEXT PRIMARY KEY,
                userId TEXT NOT NULL,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                imageUrls TEXT NOT NULL DEFAULT '[]',
                createdAt INTEGER NOT NULL,
                updatedAt INTEGER NOT NULL,
                FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
            )
        ");
        // Migrate existing tables that predate the imageUrls column
        try {
            $this->db->exec("ALTER TABLE posts ADD COLUMN imageUrls TEXT NOT NULL DEFAULT '[]'");
        } catch (\Throwable $e) {
            // Column already exists
        }
    }

    public function create(PostEntity $post): bool
    {
        $stmt = $this->db->prepare(
            "INSERT INTO posts (id, userId, title, content, imageUrls, createdAt, updatedAt)
             VALUES (?, ?, ?, ?, ?, ?, ?)"
        );
        return $stmt->execute([
            $post->id,
            $post->userId,
            $post->title,
            $post->content,
            json_encode($post->imageUrls),
            $post->createdAt,
            $post->updatedAt,
        ]);
    }

    public function findById(string $id): ?array
    {
        $stmt = $this->db->prepare(
            "SELECT p.*, COALESCE(u.name, '') as authorName
             FROM posts p
             LEFT JOIN users u ON p.userId = u.id
             WHERE p.id = ?"
        );
        $stmt->execute([$id]);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    public function existsById(string $id): bool
    {
        $stmt = $this->db->prepare("SELECT id FROM posts WHERE id = ?");
        $stmt->execute([$id]);
        return (bool) $stmt->fetch();
    }

    public function updateById(PostEntity $post): bool
    {
        $stmt = $this->db->prepare(
            "UPDATE posts SET title = ?, content = ?, imageUrls = ?, updatedAt = ? WHERE id = ?"
        );
        return $stmt->execute([
            $post->title,
            $post->content,
            json_encode($post->imageUrls),
            $post->updatedAt,
            $post->id,
        ]);
    }

    public function deleteById(string $id): bool
    {
        $stmt = $this->db->prepare("DELETE FROM posts WHERE id = ?");
        return $stmt->execute([$id]);
    }

    public function getAll(): array
    {
        $stmt = $this->db->query(
            "SELECT p.*, COALESCE(u.name, '') as authorName
             FROM posts p
             LEFT JOIN users u ON p.userId = u.id
             ORDER BY p.createdAt DESC"
        );
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getAllByUserId(string $userId): array
    {
        $stmt = $this->db->prepare(
            "SELECT p.*, COALESCE(u.name, '') as authorName
             FROM posts p
             LEFT JOIN users u ON p.userId = u.id
             WHERE p.userId = ?
             ORDER BY p.createdAt DESC"
        );
        $stmt->execute([$userId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
