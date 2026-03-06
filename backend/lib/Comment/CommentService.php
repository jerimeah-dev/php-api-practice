<?php

namespace lib\Comment;

use lib\Core\Jsend;
use lib\Reaction\ReactionRepository;

class CommentService
{
    private CommentRepository  $repo;
    private ReactionRepository $reactionRepo;

    public function __construct()
    {
        $this->repo         = new CommentRepository();
        $this->reactionRepo = new ReactionRepository();
    }

    public function list(array $input): array
    {
        $postId   = $input['postId']   ?? '';
        $viewerId = $input['viewerId'] ?? '';
        $limit    = max(1, (int) ($input['limit']  ?? 100));
        $offset   = max(0, (int) ($input['offset'] ?? 0));

        if (!$postId) return Jsend::fail(['postId' => 'postId is required']);

        $all   = $this->repo->listByPostId($postId);
        $total = count($all);
        $page  = array_slice($all, $offset, $limit);

        $ids          = array_column($page, 'id');
        $counts       = $this->reactionRepo->getCountsBatch('comment', $ids);
        $userReactions = $viewerId
            ? $this->reactionRepo->getUserReactionsBatch('comment', $ids, $viewerId)
            : [];

        foreach ($page as &$row) {
            $row['imageUrls']      = json_decode($row['imageUrls'] ?? '[]', true) ?? [];
            $row['reactionCounts'] = $counts[$row['id']] ?? [];
            $row['userReaction']   = $userReactions[$row['id']] ?? null;
        }

        return Jsend::success([
            'comments' => $page,
            'hasMore'  => ($offset + count($page)) < $total,
        ]);
    }

    public function create(array $input): array
    {
        $userId   = trim($input['userId']   ?? '');
        $postId   = trim($input['postId']   ?? '');
        $content  = trim($input['content']  ?? '');
        $parentId = $input['parentId'] ?? null;

        if (!$userId || !$postId || !$content)
            return Jsend::fail(['content' => 'userId, postId and content are required']);

        if ($parentId) {
            $parent = $this->repo->findById($parentId);
            if (!$parent)
                return Jsend::fail(['parentId' => 'Parent comment not found']);
            if ($parent['parentId'] !== null)
                return Jsend::fail(['parentId' => 'Replies cannot be nested']);
        }

        $imageUrls = json_decode($input['imageUrls'] ?? '[]', true) ?? [];

        do { $id = bin2hex(random_bytes(8)); } while ($this->repo->existsById($id));

        $entity            = new CommentEntity();
        $entity->id        = $id;
        $entity->userId    = $userId;
        $entity->postId    = $postId;
        $entity->parentId  = $parentId ?: null;
        $entity->content   = $content;
        $entity->imageUrls = $imageUrls;
        $entity->createdAt = time();
        $entity->updatedAt = time();

        $this->repo->create($entity);
        $row                   = $this->repo->findById($id);
        $row['imageUrls']      = json_decode($row['imageUrls'] ?? '[]', true) ?? [];
        $row['reactionCounts'] = $this->reactionRepo->getCountsForTarget('comment', $id);
        $row['userReaction']   = $this->reactionRepo->getUserReaction('comment', $id, $userId);

        return Jsend::success(['comment' => $row]);
    }

    public function updateById(array $input): array
    {
        $id       = $input['id'] ?? '';
        $existing = $this->repo->findById($id);
        if (!$existing) return Jsend::fail(['id' => 'Comment not found']);

        $entity            = new CommentEntity();
        $entity->id        = $id;
        $entity->userId    = $existing['userId'];
        $entity->postId    = $existing['postId'];
        $entity->parentId  = $existing['parentId'];
        $entity->content   = trim($input['content'] ?? $existing['content']);
        $entity->imageUrls = isset($input['imageUrls'])
            ? (is_string($input['imageUrls']) ? json_decode($input['imageUrls'], true) ?? [] : $input['imageUrls'])
            : json_decode($existing['imageUrls'] ?? '[]', true) ?? [];
        $entity->createdAt = (int) $existing['createdAt'];
        $entity->updatedAt = time();

        $this->repo->updateById($entity);
        $row                   = $this->repo->findById($id);
        $row['imageUrls']      = json_decode($row['imageUrls'] ?? '[]', true) ?? [];
        $row['reactionCounts'] = $this->reactionRepo->getCountsForTarget('comment', $id);
        $row['userReaction']   = null;

        return Jsend::success(['comment' => $row]);
    }

    public function deleteById(array $input): array
    {
        $id = $input['id'] ?? '';
        if (!$this->repo->existsById($id)) return Jsend::fail(['id' => 'Comment not found']);
        $this->repo->deleteById($id);
        return Jsend::success(['message' => 'Comment deleted']);
    }
}
