<?php

namespace lib\Reaction;

use lib\Core\Controller;

class ReactionController extends Controller
{
    private ReactionService $service;

    public function __construct()
    {
        $this->service = new ReactionService();
    }

    public function toggle(array $input) { $this->json($this->service->toggle($input)); }
}
