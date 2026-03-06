<?php

namespace lib\User;

use lib\Core\Controller;

class UserController extends Controller
{
    private UserService $service;

    public function __construct()
    {
        $this->service = new UserService();
    }

    public function register(array $input)   { $this->json($this->service->register($input)); }
    public function login(array $input)      { $this->json($this->service->login($input)); }
    public function findById(array $input)   { $this->json($this->service->findById($input)); }
    public function updateById(array $input) { $this->json($this->service->updateById($input)); }
    public function deleteById(array $input) { $this->json($this->service->deleteById($input)); }
}
