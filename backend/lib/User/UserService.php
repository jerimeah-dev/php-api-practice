<?php

namespace lib\User;

class UserService
{
    public UserRepository $repo;

    public function __construct()
    {
        $this->repo = new UserRepository();
    }

    // ---------------- REGISTER ----------------
    public function register(array $input): array
    {
        $email = trim($input['email'] ?? '');
        $password = $input['password'] ?? '';
        $name = $input['name'] ?? null;

        if (!$email || !$password)
            return ['status' => 'fail', 'data' => ['email' => 'Email and password required']];

        if (!filter_var($email, FILTER_VALIDATE_EMAIL))
            return ['status' => 'fail', 'data' => ['email' => 'Invalid email format']];

        if ($this->repo->existsByEmail($email))
            return ['status' => 'fail', 'data' => ['email' => 'Email already registered']];

        do {
            $id = bin2hex(random_bytes(8));
        } while ($this->repo->existsById($id));

        $user = new UserEntity();
        $user->id = $id;
        $user->email = $email;
        $user->password = password_hash($password, PASSWORD_DEFAULT);
        $user->name = $name;
        $user->createdAt = time();

        $this->repo->create($user);
        $row = $this->repo->findById($id);
        unset($row['password']);

        return ['status' => 'success', 'data' => ['user' => $row]];
    }

    // ---------------- LOGIN ----------------
    public function login(array $input): array
    {
        $email = $input['email'] ?? '';
        $password = $input['password'] ?? '';

        $row = $this->repo->findByEmail($email);

        if (!$row || !password_verify($password, $row['password']))
            return ['status' => 'fail', 'data' => ['email' => 'Invalid credentials']];

        unset($row['password']);
        return ['status' => 'success', 'data' => ['user' => $row]];
    }

    // ---------------- FIND BY ID ----------------
    public function findById(array $input): array
    {
        $id = $input['id'] ?? '';
        $row = $this->repo->findById($id);

        if (!$row)
            return ['status' => 'fail', 'data' => ['id' => 'User not found']];

        unset($row['password']);
        return ['status' => 'success', 'data' => ['user' => $row]];
    }

    // ---------------- FIND BY EMAIL ----------------
    public function findByEmail(array $input): array
    {
        $email = $input['email'] ?? '';
        $row = $this->repo->findByEmail($email);

        if (!$row)
            return ['status' => 'fail', 'data' => ['email' => 'User not found']];

        unset($row['password']);
        return ['status' => 'success', 'data' => ['user' => $row]];
    }

    // ---------------- UPDATE BY ID ----------------
    public function updateById(array $input): array
    {
        $id = $input['id'] ?? '';
        $existing = $this->repo->findById($id);

        if (!$existing)
            return ['status' => 'fail', 'data' => ['id' => 'User not found']];

        $entity = new UserEntity();
        $entity->id = $id;
        $entity->email = $input['email'] ?? $existing['email'];
        $entity->name = $input['name'] ?? $existing['name'];
        $entity->password = isset($input['password'])
            ? password_hash($input['password'], PASSWORD_DEFAULT)
            : $existing['password'];
        $entity->bio = $input['bio'] ?? $existing['bio'];
        $entity->websiteUrl = $input['websiteUrl'] ?? $existing['websiteUrl'];
        $entity->followersCount = $input['followersCount'] ?? $existing['followersCount'];
        $entity->followingCount = $input['followingCount'] ?? $existing['followingCount'];
        $entity->postsCount = $input['postsCount'] ?? $existing['postsCount'];

        // Birthday validation
        $entity->birthday = $existing['birthday'] ?? null;
        if (isset($input['birthday'])) {
            $birthday = $input['birthday'];
            if (!is_int($birthday) || $birthday <= 0)
                return ['status' => 'fail', 'data' => ['birthday' => 'Invalid birthday timestamp']];

            $age = (int)((time() - $birthday) / (365.25 * 24 * 60 * 60));
            if ($age < 0 || $age > 120)
                return ['status' => 'fail', 'data' => ['birthday' => 'Birthday out of range']];

            $entity->birthday = $birthday;
        }

        // Arrays: entity holds decoded PHP arrays; repo json_encodes on write
        $entity->education = isset($input['education'])
            ? (is_string($input['education']) ? json_decode($input['education'], true) ?? [] : $input['education'])
            : json_decode($existing['education'] ?? '[]', true) ?? [];

        $entity->workExperience = isset($input['workExperience'])
            ? (is_string($input['workExperience']) ? json_decode($input['workExperience'], true) ?? [] : $input['workExperience'])
            : json_decode($existing['workExperience'] ?? '[]', true) ?? [];

        $entity->profileImages = isset($input['profileImages'])
            ? (is_string($input['profileImages']) ? json_decode($input['profileImages'], true) ?? [] : $input['profileImages'])
            : json_decode($existing['profileImages'] ?? '[]', true) ?? [];

        // Sync currentAvatarUrl from the image marked isCurrent
        $currentImgs = array_values(array_filter($entity->profileImages, fn($img) => ($img['isCurrent'] ?? false) === true));
        $entity->currentAvatarUrl = !empty($currentImgs) ? ($currentImgs[0]['url'] ?? '') : ($existing['currentAvatarUrl'] ?? '');

        $this->repo->updateById($entity);
        $row = $this->repo->findById($id);
        unset($row['password']);

        return ['status' => 'success', 'data' => ['user' => $row]];
    }

    // ---------------- DELETE BY ID ----------------
    public function deleteById(array $input): array
    {
        $id = $input['id'] ?? '';
        if (!$this->repo->existsById($id))
            return ['status' => 'fail', 'data' => ['id' => 'User not found']];

        $this->repo->deleteById($id);
        return ['status' => 'success', 'data' => ['message' => 'User deleted']];
    }

    // ---------------- LIST ALL ----------------
    public function listAll(): array
    {
        $rows = $this->repo->getAll();
        foreach ($rows as &$row) {
            unset($row['password']);
        }
        return ['status' => 'success', 'data' => ['users' => $rows]];
    }
}
