<?php

namespace lib\Reaction;

class ReactionService
{
    private ReactionRepository $repo;

    private const VALID_TYPES = ['like', 'love', 'haha', 'wow', 'sad', 'angry'];

    public function __construct()
    {
        $this->repo = new ReactionRepository();
    }

    // ---------------- TOGGLE ----------------
    public function toggle(array $input): array
    {
        $postId = trim($input['postId'] ?? '');
        $userId = trim($input['userId'] ?? '');
        $type   = trim($input['type'] ?? '');

        if (!$postId || !$userId)
            return ['status' => 'fail', 'data' => ['postId' => 'postId and userId required']];

        if (!in_array($type, self::VALID_TYPES))
            return ['status' => 'fail', 'data' => ['type' => 'Invalid reaction type']];

        $userReaction   = $this->repo->toggle($postId, $userId, $type);
        $reactionCounts = $this->repo->getCountsForPost($postId);

        return ['status' => 'success', 'data' => [
            'reactionCounts' => $reactionCounts,
            'userReaction'   => $userReaction,
        ]];
    }

    // ---------------- GET FOR POST ----------------
    public function getForPost(array $input): array
    {
        $postId = $input['postId'] ?? '';
        $userId = $input['userId'] ?? '';

        if (!$postId)
            return ['status' => 'fail', 'data' => ['postId' => 'postId required']];

        $reactionCounts = $this->repo->getCountsForPost($postId);
        $userReaction   = $userId
            ? ($this->repo->findByPostAndUser($postId, $userId)['type'] ?? null)
            : null;

        return ['status' => 'success', 'data' => [
            'reactionCounts' => $reactionCounts,
            'userReaction'   => $userReaction,
        ]];
    }
}
