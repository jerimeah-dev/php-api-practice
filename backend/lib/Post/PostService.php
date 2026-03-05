<?php

namespace lib\Post;

use lib\User\UserRepository;
use lib\Reaction\ReactionRepository;

class PostService
{
    public PostRepository $repo;
    private UserRepository $userRepo;
    private ReactionRepository $reactionRepo;

    public function __construct()
    {
        $this->repo         = new PostRepository();
        $this->userRepo     = new UserRepository();
        $this->reactionRepo = new ReactionRepository();
    }

    // ---------------- CREATE ----------------
    public function create(array $input): array
    {
        $userId  = trim($input['userId'] ?? '');
        $title   = trim($input['title'] ?? '');
        $content = trim($input['content'] ?? '');

        if (!$userId)
            return ['status' => 'fail', 'data' => ['userId' => 'User ID required']];
        if (!$title)
            return ['status' => 'fail', 'data' => ['title' => 'Title required']];
        if (!$content)
            return ['status' => 'fail', 'data' => ['content' => 'Content required']];

        do {
            $id = bin2hex(random_bytes(8));
        } while ($this->repo->existsById($id));

        $entity            = new PostEntity();
        $entity->id        = $id;
        $entity->userId    = $userId;
        $entity->title     = $title;
        $entity->content   = $content;
        $entity->imageUrls = isset($input['imageUrls'])
            ? (is_string($input['imageUrls']) ? json_decode($input['imageUrls'], true) ?? [] : $input['imageUrls'])
            : [];
        $entity->createdAt = time();
        $entity->updatedAt = time();

        $this->repo->create($entity);
        $this->userRepo->incrementPostsCount($userId);
        $row = $this->repo->findById($id);
        $row = $this->attachSingleReaction($row, $userId);

        return ['status' => 'success', 'data' => ['post' => $row]];
    }

    // ---------------- GET BY ID ----------------
    public function getById(array $input): array
    {
        $id     = $input['id'] ?? '';
        $userId = $input['userId'] ?? '';
        $row    = $this->repo->findById($id);

        if (!$row)
            return ['status' => 'fail', 'data' => ['id' => 'Post not found']];

        $row = $this->attachSingleReaction($row, $userId);
        return ['status' => 'success', 'data' => ['post' => $row]];
    }

    // ---------------- UPDATE BY ID ----------------
    public function updateById(array $input): array
    {
        $id     = $input['id'] ?? '';
        $userId = $input['userId'] ?? '';
        $existing = $this->repo->findById($id);

        if (!$existing)
            return ['status' => 'fail', 'data' => ['id' => 'Post not found']];

        if ($existing['userId'] !== $userId)
            return ['status' => 'fail', 'data' => ['userId' => 'Not authorized']];

        $title   = trim($input['title'] ?? $existing['title']);
        $content = trim($input['content'] ?? $existing['content']);

        if (!$title)
            return ['status' => 'fail', 'data' => ['title' => 'Title required']];
        if (!$content)
            return ['status' => 'fail', 'data' => ['content' => 'Content required']];

        $entity            = new PostEntity();
        $entity->id        = $id;
        $entity->userId    = $existing['userId'];
        $entity->title     = $title;
        $entity->content   = $content;
        $entity->imageUrls = isset($input['imageUrls'])
            ? (is_string($input['imageUrls']) ? json_decode($input['imageUrls'], true) ?? [] : $input['imageUrls'])
            : json_decode($existing['imageUrls'] ?? '[]', true) ?? [];
        $entity->createdAt = (int) $existing['createdAt'];
        $entity->updatedAt = time();

        $this->repo->updateById($entity);
        $row = $this->repo->findById($id);
        $row = $this->attachSingleReaction($row, $userId);

        return ['status' => 'success', 'data' => ['post' => $row]];
    }

    // ---------------- DELETE BY ID ----------------
    public function deleteById(array $input): array
    {
        $id     = $input['id'] ?? '';
        $userId = $input['userId'] ?? '';
        $existing = $this->repo->findById($id);

        if (!$existing)
            return ['status' => 'fail', 'data' => ['id' => 'Post not found']];

        if ($existing['userId'] !== $userId)
            return ['status' => 'fail', 'data' => ['userId' => 'Not authorized']];

        $this->repo->deleteById($id);
        $this->userRepo->decrementPostsCount($existing['userId']);
        return ['status' => 'success', 'data' => ['message' => 'Post deleted']];
    }

    // ---------------- LIST ALL ----------------
    public function listAll(array $input): array
    {
        $userId = $input['userId'] ?? '';
        $rows   = $this->repo->getAll();
        $rows   = $this->attachReactionsBatch($rows, $userId);
        return ['status' => 'success', 'data' => ['posts' => $rows]];
    }

    // ---------------- LIST BY USER ----------------
    public function listByUser(array $input): array
    {
        $userId = $input['userId'] ?? '';
        if (!$userId)
            return ['status' => 'fail', 'data' => ['userId' => 'User ID required']];

        $rows = $this->repo->getAllByUserId($userId);
        $rows = $this->attachReactionsBatch($rows, $userId);
        return ['status' => 'success', 'data' => ['posts' => $rows]];
    }

    // ---------------- HELPERS ----------------

    /** Attach reactionCounts + userReaction to a batch of post rows (2 queries total). */
    private function attachReactionsBatch(array $rows, string $userId): array
    {
        if (empty($rows)) return $rows;
        $postIds      = array_column($rows, 'id');
        $counts       = $this->reactionRepo->getCountsBatch($postIds);
        $userReactions = $userId ? $this->reactionRepo->getUserReactionsBatch($postIds, $userId) : [];

        foreach ($rows as &$row) {
            $row['reactionCounts'] = $counts[$row['id']] ?? [];
            $row['userReaction']   = $userReactions[$row['id']] ?? null;
        }
        return $rows;
    }

    /** Attach reaction data to a single post row. */
    private function attachSingleReaction(array $row, string $userId): array
    {
        $row['reactionCounts'] = $this->reactionRepo->getCountsForPost($row['id']);
        $row['userReaction']   = $userId
            ? ($this->reactionRepo->findByPostAndUser($row['id'], $userId)['type'] ?? null)
            : null;
        return $row;
    }
}
