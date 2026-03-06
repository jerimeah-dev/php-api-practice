<?php

namespace lib\Core;

abstract class Controller
{
    protected function json(array $data): void
    {
        header('Content-Type: application/json');
        echo json_encode($data);
    }
}
