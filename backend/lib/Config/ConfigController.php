<?php

namespace lib\Config;

use lib\Utils\Controller;

class ConfigController extends Controller
{
    private ConfigService $service;

    public function __construct()
    {
        $this->service = new ConfigService();
    }

    public function install()
    {
        return $this->json($this->service->install());
    }

    public function getAll(array $input)
    {
        return $this->json($this->service->getAll());
    }

    public function set(array $input)
    {
        return $this->json($this->service->set($input));
    }
}