<?php

namespace lib\User;

use lib\Core\Jsend;

class UserService
{
    private UserRepository $repo;

    public function __construct()
    {
        $this->repo = new UserRepository();
    }

    public function register(array $input): array
    {
        $email    = trim($input['email'] ?? '');
        $password = $input['password'] ?? '';
        $name     = trim($input['name'] ?? '');

        if (!$email || !$password)
            return Jsend::fail(['email' => 'Email and password required']);
        if (!filter_var($email, FILTER_VALIDATE_EMAIL))
            return Jsend::fail(['email' => 'Invalid email format']);
        if ($this->repo->existsByEmail($email))
            return Jsend::fail(['email' => 'Email already registered']);

        do { $id = bin2hex(random_bytes(8)); } while ($this->repo->existsById($id));

        $entity                = new UserEntity();
        $entity->id            = $id;
        $entity->email         = $email;
        $entity->password      = password_hash($password, PASSWORD_DEFAULT);
        $entity->name          = $name;
        $entity->avatarUrl     = '';
        $entity->profileImages = [];
        $entity->createdAt     = time();

        $this->repo->create($entity);
        return Jsend::success(['user' => $this->prepareUser($this->repo->findById($id))]);
    }

    public function login(array $input): array
    {
        $email    = trim($input['email'] ?? '');
        $password = $input['password'] ?? '';
        $row      = $this->repo->findByEmail($email);

        if (!$row || !password_verify($password, $row['password']))
            return Jsend::fail(['email' => 'Invalid credentials']);

        return Jsend::success(['user' => $this->prepareUser($row)]);
    }

    public function findById(array $input): array
    {
        $row = $this->repo->findById($input['id'] ?? '');
        if (!$row) return Jsend::fail(['id' => 'User not found']);
        return Jsend::success(['user' => $this->prepareUser($row)]);
    }

    public function updateById(array $input): array
    {
        $id       = $input['id'] ?? '';
        $existing = $this->repo->findById($id);
        if (!$existing) return Jsend::fail(['id' => 'User not found']);

        $profileImages = isset($input['profileImages'])
            ? (is_string($input['profileImages']) ? json_decode($input['profileImages'], true) ?? [] : $input['profileImages'])
            : json_decode($existing['profileImages'] ?? '[]', true) ?? [];

        $entity                = new UserEntity();
        $entity->id            = $id;
        $entity->email         = $existing['email'];
        $entity->password      = $existing['password'];
        $entity->name          = trim($input['name'] ?? $existing['name'] ?? '');
        $entity->profileImages = $profileImages;
        $entity->avatarUrl     = !empty($profileImages) ? ($profileImages[0]['url'] ?? '') : '';

        $this->repo->updateById($entity);
        return Jsend::success(['user' => $this->prepareUser($this->repo->findById($id))]);
    }

    public function deleteById(array $input): array
    {
        $id = $input['id'] ?? '';
        if (!$this->repo->existsById($id)) return Jsend::fail(['id' => 'User not found']);
        $this->repo->deleteById($id);
        return Jsend::success(['message' => 'User deleted']);
    }

    private function prepareUser(array $row): array
    {
        unset($row['password']);
        $row['profileImages'] = json_decode($row['profileImages'] ?? '[]', true) ?? [];
        return $row;
    }
}
