<?php

namespace lib\Post;

use lib\Core\Jsend;
use lib\Reaction\ReactionRepository;

class PostService
{
    private PostRepository    $repo;
    private ReactionRepository $reactionRepo;

    public function __construct()
    {
        $this->repo         = new PostRepository();
        $this->reactionRepo = new ReactionRepository();
    }

    public function list(array $input): array
    {
        $viewerId = $input['viewerId'] ?? '';
        $limit    = max(1, (int) ($input['limit']  ?? 20));
        $offset   = max(0, (int) ($input['offset'] ?? 0));
        $authorId = $input['authorId'] ?? null;

        $rows  = $this->repo->list($limit, $offset, $authorId ?: null);
        $total = $this->repo->countAll($authorId ?: null);
        $rows  = $this->attachReactionsBatch($rows, $viewerId);

        return Jsend::success([
            'posts'   => $rows,
            'total'   => $total,
            'hasMore' => ($offset + count($rows)) < $total,
        ]);
    }

    public function getById(array $input): array
    {
        $id       = $input['id'] ?? '';
        $viewerId = $input['viewerId'] ?? '';
        $row      = $this->repo->findById($id);
        if (!$row) return Jsend::fail(['id' => 'Post not found']);
        return Jsend::success(['post' => $this->preparePost($row, $viewerId)]);
    }

    public function create(array $input): array
    {
        $userId  = trim($input['userId'] ?? '');
        $content = trim($input['content'] ?? '');
        if (!$userId || !$content)
            return Jsend::fail(['content' => 'userId and content are required']);

        $title     = trim($input['title'] ?? '');
        $imageUrls = json_decode($input['imageUrls'] ?? '[]', true) ?? [];

        do { $id = bin2hex(random_bytes(8)); } while ($this->repo->existsById($id));

        $entity            = new PostEntity();
        $entity->id        = $id;
        $entity->userId    = $userId;
        $entity->title     = $title;
        $entity->content   = $content;
        $entity->imageUrls = $imageUrls;
        $entity->createdAt = time();
        $entity->updatedAt = time();

        $this->repo->create($entity);
        $row = $this->repo->findById($id);
        return Jsend::success(['post' => $this->preparePost($row, $userId)]);
    }

    public function updateById(array $input): array
    {
        $id       = $input['id'] ?? '';
        $existing = $this->repo->findById($id);
        if (!$existing) return Jsend::fail(['id' => 'Post not found']);

        $entity            = new PostEntity();
        $entity->id        = $id;
        $entity->userId    = $existing['userId'];
        $entity->title     = trim($input['title'] ?? $existing['title'] ?? '');
        $entity->content   = trim($input['content'] ?? $existing['content']);
        $entity->imageUrls = isset($input['imageUrls'])
            ? (is_string($input['imageUrls']) ? json_decode($input['imageUrls'], true) ?? [] : $input['imageUrls'])
            : json_decode($existing['imageUrls'] ?? '[]', true) ?? [];
        $entity->createdAt = (int) $existing['createdAt'];
        $entity->updatedAt = time();

        $this->repo->updateById($entity);
        $row = $this->repo->findById($id);
        return Jsend::success(['post' => $this->preparePost($row, $existing['userId'])]);
    }

    public function deleteById(array $input): array
    {
        $id = $input['id'] ?? '';
        if (!$this->repo->existsById($id)) return Jsend::fail(['id' => 'Post not found']);
        $this->repo->deleteById($id);
        return Jsend::success(['message' => 'Post deleted']);
    }

    private function preparePost(array $row, string $viewerId): array
    {
        $row['imageUrls']      = json_decode($row['imageUrls'] ?? '[]', true) ?? [];
        $row['reactionCounts'] = $this->reactionRepo->getCountsForTarget('post', $row['id']);
        $row['userReaction']   = $viewerId
            ? $this->reactionRepo->getUserReaction('post', $row['id'], $viewerId)
            : null;
        return $row;
    }

    private function attachReactionsBatch(array $rows, string $viewerId): array
    {
        if (empty($rows)) return $rows;
        $ids          = array_column($rows, 'id');
        $counts       = $this->reactionRepo->getCountsBatch('post', $ids);
        $userReactions = $viewerId
            ? $this->reactionRepo->getUserReactionsBatch('post', $ids, $viewerId)
            : [];
        foreach ($rows as &$row) {
            $row['imageUrls']      = json_decode($row['imageUrls'] ?? '[]', true) ?? [];
            $row['reactionCounts'] = $counts[$row['id']] ?? [];
            $row['userReaction']   = $userReactions[$row['id']] ?? null;
        }
        return $rows;
    }
}
