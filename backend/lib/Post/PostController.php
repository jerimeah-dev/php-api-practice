<?php

namespace lib\Post;

use lib\Utils\Controller;

class PostController extends Controller
{
    private PostService $service;

    public function __construct()
    {
        $this->service = new PostService();
    }

    public function create(array $input)
    {
        return $this->json($this->service->create($input));
    }

    public function getById(array $input)
    {
        return $this->json($this->service->getById($input));
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

    public function listByUser(array $input)
    {
        return $this->json($this->service->listByUser($input));
    }
}
