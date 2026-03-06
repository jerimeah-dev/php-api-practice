<?php

namespace lib\Comment;

use lib\Core\Repository;

class CommentRepository extends Repository
{
    public function __construct()
    {
        parent::__construct();
        $this->createTable();
    }

    private function createTable(): void
    {
        $this->db->exec("CREATE TABLE IF NOT EXISTS comments (
            id        TEXT    PRIMARY KEY,
            userId    TEXT    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            postId    TEXT    NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
            parentId  TEXT             REFERENCES comments(id) ON DELETE CASCADE,
            content   TEXT    NOT NULL,
            imageUrls TEXT    NOT NULL DEFAULT '[]',
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL
        )");
        try { $this->db->exec("ALTER TABLE comments ADD COLUMN imageUrls TEXT NOT NULL DEFAULT '[]'"); } catch (\Throwable) {}
        try { $this->db->exec("ALTER TABLE comments ADD COLUMN updatedAt INTEGER NOT NULL DEFAULT 0"); } catch (\Throwable) {}
    }

    public function create(CommentEntity $comment): bool
    {
        return (bool) $this->execute(
            "INSERT INTO comments (id, userId, postId, parentId, content, imageUrls, createdAt, updatedAt)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            [$comment->id, $comment->userId, $comment->postId, $comment->parentId,
             $comment->content, json_encode($comment->imageUrls), $comment->createdAt, $comment->updatedAt]
        );
    }

    public function findById(string $id): ?array
    {
        return $this->fetch(
            "SELECT c.*, COALESCE(u.name,'') as authorName, COALESCE(u.avatarUrl,'') as authorAvatarUrl
             FROM comments c LEFT JOIN users u ON c.userId = u.id WHERE c.id = ?",
            [$id]
        );
    }

    public function existsById(string $id): bool
    {
        return (bool) $this->fetch("SELECT id FROM comments WHERE id = ?", [$id]);
    }

    public function listByPostId(string $postId): array
    {
        return $this->fetchAll(
            "SELECT c.*, COALESCE(u.name,'') as authorName, COALESCE(u.avatarUrl,'') as authorAvatarUrl
             FROM comments c LEFT JOIN users u ON c.userId = u.id
             WHERE c.postId = ? ORDER BY c.createdAt ASC",
            [$postId]
        );
    }

    public function updateById(CommentEntity $comment): bool
    {
        return (bool) $this->execute(
            "UPDATE comments SET content = ?, imageUrls = ?, updatedAt = ? WHERE id = ?",
            [$comment->content, json_encode($comment->imageUrls), $comment->updatedAt, $comment->id]
        );
    }

    public function deleteById(string $id): bool
    {
        return (bool) $this->execute("DELETE FROM comments WHERE id = ?", [$id]);
    }
}
