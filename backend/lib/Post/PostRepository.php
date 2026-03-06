<?php

namespace lib\Post;

use lib\Core\Repository;

class PostRepository extends Repository
{
    public function __construct()
    {
        parent::__construct();
        $this->createTable();
    }

    private function createTable(): void
    {
        $this->db->exec("CREATE TABLE IF NOT EXISTS posts (
            id        TEXT    PRIMARY KEY,
            userId    TEXT    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            content   TEXT    NOT NULL,
            imageUrls TEXT    NOT NULL DEFAULT '[]',
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL
        )");
        try { $this->db->exec("ALTER TABLE posts ADD COLUMN imageUrls TEXT NOT NULL DEFAULT '[]'"); } catch (\Throwable) {}
        try { $this->db->exec("ALTER TABLE posts ADD COLUMN updatedAt INTEGER NOT NULL DEFAULT 0"); } catch (\Throwable) {}
    }

    public function create(PostEntity $post): bool
    {
        return (bool) $this->execute(
            "INSERT INTO posts (id, userId, content, imageUrls, createdAt, updatedAt)
             VALUES (?, ?, ?, ?, ?, ?)",
            [$post->id, $post->userId, $post->content,
             json_encode($post->imageUrls), $post->createdAt, $post->updatedAt]
        );
    }

    public function findById(string $id): ?array
    {
        return $this->fetch(
            "SELECT p.*, COALESCE(u.name,'') as authorName, COALESCE(u.avatarUrl,'') as authorAvatarUrl
             FROM posts p LEFT JOIN users u ON p.userId = u.id WHERE p.id = ?",
            [$id]
        );
    }

    public function existsById(string $id): bool
    {
        return (bool) $this->fetch("SELECT id FROM posts WHERE id = ?", [$id]);
    }

    public function list(int $limit, int $offset, ?string $authorId): array
    {
        if ($authorId) {
            return $this->fetchAll(
                "SELECT p.*, COALESCE(u.name,'') as authorName, COALESCE(u.avatarUrl,'') as authorAvatarUrl
                 FROM posts p LEFT JOIN users u ON p.userId = u.id
                 WHERE p.userId = ? ORDER BY p.createdAt DESC LIMIT ? OFFSET ?",
                [$authorId, $limit, $offset]
            );
        }
        return $this->fetchAll(
            "SELECT p.*, COALESCE(u.name,'') as authorName, COALESCE(u.avatarUrl,'') as authorAvatarUrl
             FROM posts p LEFT JOIN users u ON p.userId = u.id
             ORDER BY p.createdAt DESC LIMIT ? OFFSET ?",
            [$limit, $offset]
        );
    }

    public function countAll(?string $authorId): int
    {
        $row = $authorId
            ? $this->fetch("SELECT COUNT(*) as cnt FROM posts WHERE userId = ?", [$authorId])
            : $this->fetch("SELECT COUNT(*) as cnt FROM posts");
        return (int) ($row['cnt'] ?? 0);
    }

    public function updateById(PostEntity $post): bool
    {
        return (bool) $this->execute(
            "UPDATE posts SET content = ?, imageUrls = ?, updatedAt = ? WHERE id = ?",
            [$post->content, json_encode($post->imageUrls), $post->updatedAt, $post->id]
        );
    }

    public function deleteById(string $id): bool
    {
        return (bool) $this->execute("DELETE FROM posts WHERE id = ?", [$id]);
    }
}
