<?php

namespace lib\User;

use lib\Utils\Controller;

class UserController extends Controller
{
    private UserService $service;

    public function __construct()
    {
        $this->service = new UserService();
    }

    public function register(array $input)
    {
        return $this->json($this->service->register($input));
    }

    public function login(array $input)
    {
        return $this->json($this->service->login($input));
    }

    public function findById(array $input)
    {
        return $this->json($this->service->findById($input));
    }

    public function findByEmail(array $input)
    {
        return $this->json($this->service->findByEmail($input));
    }

    public function updateById(array $input)
    {
        return $this->json($this->service->updateById($input));
    }

    public function deleteById(array $input)
    {
        return $this->json($this->service->deleteById($input));
    }

    public function listAll(array $input)
    {
        return $this->json($this->service->listAll());
    }
}
