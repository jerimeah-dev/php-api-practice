<?php

namespace lib\Reaction;

use lib\Core\Jsend;

class ReactionService
{
    private ReactionRepository $repo;

    private const VALID_TYPES        = ['Like', 'Love', 'Haha', 'Wow', 'Sad', 'Angry'];
    private const VALID_TARGET_TYPES = ['post', 'comment'];

    public function __construct()
    {
        $this->repo = new ReactionRepository();
    }

    public function toggle(array $input): array
    {
        $userId     = trim($input['userId']     ?? '');
        $targetType = trim($input['targetType'] ?? '');
        $targetId   = trim($input['targetId']   ?? '');
        $type       = trim($input['type']       ?? '');

        if (!$userId || !$targetType || !$targetId)
            return Jsend::fail(['targetId' => 'userId, targetType and targetId are required']);
        if (!in_array($targetType, self::VALID_TARGET_TYPES))
            return Jsend::fail(['targetType' => 'Invalid target type']);
        if (!in_array($type, self::VALID_TYPES))
            return Jsend::fail(['type' => 'Invalid reaction type']);

        $action        = $this->repo->toggle($userId, $targetType, $targetId, $type);
        $reactionCounts = $this->repo->getCountsForTarget($targetType, $targetId);
        $userReaction  = $this->repo->getUserReaction($targetType, $targetId, $userId);

        return Jsend::success([
            'action'         => $action,
            'reactionCounts' => $reactionCounts,
            'userReaction'   => $userReaction,
        ]);
    }
}
