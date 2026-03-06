<?php

namespace lib\Comment;

use lib\Core\Controller;

class CommentController extends Controller
{
    private CommentService $service;

    public function __construct()
    {
        $this->service = new CommentService();
    }

    public function list(array $input)       { $this->json($this->service->list($input)); }
    public function create(array $input)     { $this->json($this->service->create($input)); }
    public function updateById(array $input) { $this->json($this->service->updateById($input)); }
    public function deleteById(array $input) { $this->json($this->service->deleteById($input)); }
}
