<?php

namespace lib\Reaction;

use lib\Utils\Controller;

class ReactionController extends Controller
{
    private ReactionService $service;

    public function __construct()
    {
        $this->service = new ReactionService();
    }

    public function toggle(array $input)     { return $this->json($this->service->toggle($input)); }
    public function getForPost(array $input) { return $this->json($this->service->getForPost($input)); }
}
