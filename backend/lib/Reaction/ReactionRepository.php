<?php

namespace lib\Reaction;

use lib\Utils\Database;
use PDO;

class ReactionRepository
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::get();
        $this->db->exec("
            CREATE TABLE IF NOT EXISTS reactions (
                id TEXT PRIMARY KEY,
                postId TEXT NOT NULL,
                userId TEXT NOT NULL,
                type TEXT NOT NULL,
                createdAt INTEGER NOT NULL,
                UNIQUE(postId, userId),
                FOREIGN KEY (postId) REFERENCES posts(id) ON DELETE CASCADE
            )
        ");
    }

    /** Toggle a reaction. Returns the new type, or null if removed. */
    public function toggle(string $postId, string $userId, string $type): ?string
    {
        $existing = $this->findByPostAndUser($postId, $userId);

        if ($existing) {
            if ($existing['type'] === $type) {
                $this->delete($postId, $userId);
                return null;
            }
            $stmt = $this->db->prepare("UPDATE reactions SET type = ? WHERE postId = ? AND userId = ?");
            $stmt->execute([$type, $postId, $userId]);
            return $type;
        }

        $stmt = $this->db->prepare(
            "INSERT INTO reactions (id, postId, userId, type, createdAt) VALUES (?, ?, ?, ?, ?)"
        );
        $stmt->execute([bin2hex(random_bytes(8)), $postId, $userId, $type, time()]);
        return $type;
    }

    public function findByPostAndUser(string $postId, string $userId): ?array
    {
        $stmt = $this->db->prepare("SELECT * FROM reactions WHERE postId = ? AND userId = ?");
        $stmt->execute([$postId, $userId]);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    private function delete(string $postId, string $userId): void
    {
        $stmt = $this->db->prepare("DELETE FROM reactions WHERE postId = ? AND userId = ?");
        $stmt->execute([$postId, $userId]);
    }

    /** Returns ['like' => 3, 'love' => 1, ...] for a single post */
    public function getCountsForPost(string $postId): array
    {
        $stmt = $this->db->prepare(
            "SELECT type, COUNT(*) as cnt FROM reactions WHERE postId = ? GROUP BY type"
        );
        $stmt->execute([$postId]);
        $result = [];
        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $result[$row['type']] = (int) $row['cnt'];
        }
        return $result;
    }

    /** Batch: returns ['postId1' => ['like' => 3, ...], ...] */
    public function getCountsBatch(array $postIds): array
    {
        if (empty($postIds)) return [];
        $placeholders = implode(',', array_fill(0, count($postIds), '?'));
        $stmt = $this->db->prepare(
            "SELECT postId, type, COUNT(*) as cnt FROM reactions
             WHERE postId IN ($placeholders) GROUP BY postId, type"
        );
        $stmt->execute($postIds);
        $result = [];
        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $result[$row['postId']][$row['type']] = (int) $row['cnt'];
        }
        return $result;
    }

    /** Batch: returns ['postId1' => 'like', ...] for the given user */
    public function getUserReactionsBatch(array $postIds, string $userId): array
    {
        if (empty($postIds) || !$userId) return [];
        $placeholders = implode(',', array_fill(0, count($postIds), '?'));
        $stmt = $this->db->prepare(
            "SELECT postId, type FROM reactions WHERE postId IN ($placeholders) AND userId = ?"
        );
        $stmt->execute([...$postIds, $userId]);
        $result = [];
        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $result[$row['postId']] = $row['type'];
        }
        return $result;
    }
}
