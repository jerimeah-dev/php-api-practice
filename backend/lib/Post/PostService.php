<?php

namespace lib\Post;

class PostService
{
    public PostRepository $repo;

    public function __construct()
    {
        $this->repo = new PostRepository();
    }

    // ---------------- CREATE ----------------
    public function create(array $input): array
    {
        $userId = trim($input['userId'] ?? '');
        $title = trim($input['title'] ?? '');
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

        $entity = new PostEntity();
        $entity->id = $id;
        $entity->userId = $userId;
        $entity->title = $title;
        $entity->content = $content;
        $entity->imageUrls = isset($input['imageUrls'])
            ? (is_string($input['imageUrls']) ? json_decode($input['imageUrls'], true) ?? [] : $input['imageUrls'])
            : [];
        $entity->createdAt = time();
        $entity->updatedAt = time();

        $this->repo->create($entity);
        $row = $this->repo->findById($id);

        return ['status' => 'success', 'data' => ['post' => $row]];
    }

    // ---------------- GET BY ID ----------------
    public function getById(array $input): array
    {
        $id = $input['id'] ?? '';
        $row = $this->repo->findById($id);

        if (!$row)
            return ['status' => 'fail', 'data' => ['id' => 'Post not found']];

        return ['status' => 'success', 'data' => ['post' => $row]];
    }

    // ---------------- UPDATE BY ID ----------------
    public function updateById(array $input): array
    {
        $id = $input['id'] ?? '';
        $userId = $input['userId'] ?? '';
        $existing = $this->repo->findById($id);

        if (!$existing)
            return ['status' => 'fail', 'data' => ['id' => 'Post not found']];

        if ($existing['userId'] !== $userId)
            return ['status' => 'fail', 'data' => ['userId' => 'Not authorized']];

        $title = trim($input['title'] ?? $existing['title']);
        $content = trim($input['content'] ?? $existing['content']);

        if (!$title)
            return ['status' => 'fail', 'data' => ['title' => 'Title required']];
        if (!$content)
            return ['status' => 'fail', 'data' => ['content' => 'Content required']];

        $entity = new PostEntity();
        $entity->id = $id;
        $entity->userId = $existing['userId'];
        $entity->title = $title;
        $entity->content = $content;
        $entity->imageUrls = isset($input['imageUrls'])
            ? (is_string($input['imageUrls']) ? json_decode($input['imageUrls'], true) ?? [] : $input['imageUrls'])
            : json_decode($existing['imageUrls'] ?? '[]', true) ?? [];
        $entity->createdAt = (int) $existing['createdAt'];
        $entity->updatedAt = time();

        $this->repo->updateById($entity);
        $row = $this->repo->findById($id);

        return ['status' => 'success', 'data' => ['post' => $row]];
    }

    // ---------------- DELETE BY ID ----------------
    public function deleteById(array $input): array
    {
        $id = $input['id'] ?? '';
        $userId = $input['userId'] ?? '';
        $existing = $this->repo->findById($id);

        if (!$existing)
            return ['status' => 'fail', 'data' => ['id' => 'Post not found']];

        if ($existing['userId'] !== $userId)
            return ['status' => 'fail', 'data' => ['userId' => 'Not authorized']];

        $this->repo->deleteById($id);
        return ['status' => 'success', 'data' => ['message' => 'Post deleted']];
    }

    // ---------------- LIST ALL ----------------
    public function listAll(): array
    {
        return ['status' => 'success', 'data' => ['posts' => $this->repo->getAll()]];
    }

    // ---------------- LIST BY USER ----------------
    public function listByUser(array $input): array
    {
        $userId = $input['userId'] ?? '';
        if (!$userId)
            return ['status' => 'fail', 'data' => ['userId' => 'User ID required']];

        return ['status' => 'success', 'data' => ['posts' => $this->repo->getAllByUserId($userId)]];
    }
}
