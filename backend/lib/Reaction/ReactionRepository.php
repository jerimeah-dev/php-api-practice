<?php

namespace lib\Reaction;

use lib\Core\Repository;

class ReactionRepository extends Repository
{
    public function __construct()
    {
        parent::__construct();
        $this->createTable();
    }

    private function createTable(): void
    {
        $this->db->exec("CREATE TABLE IF NOT EXISTS reactions (
            userId     TEXT    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            targetType TEXT    NOT NULL,
            targetId   TEXT    NOT NULL,
            type       TEXT    NOT NULL,
            createdAt  INTEGER NOT NULL,
            UNIQUE(userId, targetType, targetId)
        )");
        // Migrate old schema (postId-based) to new (targetType/targetId)
        try { $this->db->exec("ALTER TABLE reactions ADD COLUMN targetType TEXT NOT NULL DEFAULT 'post'"); } catch (\Throwable) {}
        try { $this->db->exec("ALTER TABLE reactions ADD COLUMN targetId TEXT NOT NULL DEFAULT ''"); } catch (\Throwable) {}
    }

    /** Toggle reaction; returns 'added' | 'removed' | 'changed' */
    public function toggle(string $userId, string $targetType, string $targetId, string $type): string
    {
        $existing = $this->getUserReaction($targetType, $targetId, $userId);

        if ($existing !== null) {
            if ($existing === $type) {
                $this->execute(
                    "DELETE FROM reactions WHERE userId = ? AND targetType = ? AND targetId = ?",
                    [$userId, $targetType, $targetId]
                );
                return 'removed';
            }
            $this->execute(
                "UPDATE reactions SET type = ? WHERE userId = ? AND targetType = ? AND targetId = ?",
                [$type, $userId, $targetType, $targetId]
            );
            return 'changed';
        }

        $this->execute(
            "INSERT INTO reactions (userId, targetType, targetId, type, createdAt) VALUES (?, ?, ?, ?, ?)",
            [$userId, $targetType, $targetId, $type, time()]
        );
        return 'added';
    }

    public function getUserReaction(string $targetType, string $targetId, string $userId): ?string
    {
        $row = $this->fetch(
            "SELECT type FROM reactions WHERE userId = ? AND targetType = ? AND targetId = ?",
            [$userId, $targetType, $targetId]
        );
        return $row ? $row['type'] : null;
    }

    public function getCountsForTarget(string $targetType, string $targetId): array
    {
        $rows = $this->fetchAll(
            "SELECT type, COUNT(*) as cnt FROM reactions WHERE targetType = ? AND targetId = ? GROUP BY type",
            [$targetType, $targetId]
        );
        $result = [];
        foreach ($rows as $row) $result[$row['type']] = (int) $row['cnt'];
        return $result;
    }

    public function getCountsBatch(string $targetType, array $targetIds): array
    {
        if (empty($targetIds)) return [];
        $ph   = implode(',', array_fill(0, count($targetIds), '?'));
        $rows = $this->fetchAll(
            "SELECT targetId, type, COUNT(*) as cnt FROM reactions
             WHERE targetType = ? AND targetId IN ($ph) GROUP BY targetId, type",
            [$targetType, ...$targetIds]
        );
        $result = [];
        foreach ($rows as $row) $result[$row['targetId']][$row['type']] = (int) $row['cnt'];
        return $result;
    }

    public function getUserReactionsBatch(string $targetType, array $targetIds, string $userId): array
    {
        if (empty($targetIds) || !$userId) return [];
        $ph   = implode(',', array_fill(0, count($targetIds), '?'));
        $rows = $this->fetchAll(
            "SELECT targetId, type FROM reactions
             WHERE targetType = ? AND targetId IN ($ph) AND userId = ?",
            [$targetType, ...$targetIds, $userId]
        );
        $result = [];
        foreach ($rows as $row) $result[$row['targetId']] = $row['type'];
        return $result;
    }
}
