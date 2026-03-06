<?php

require_once __DIR__ . '/vendor/autoload.php';

header('Content-Type: application/json');

try {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input || empty($input['method'])) {
        throw new \Exception('method is required');
    }

    [$domain, $method] = explode('.', trim($input['method']), 2);

    $class = 'lib\\' . ucfirst($domain) . '\\' . ucfirst($domain) . 'Controller';

    (new $class())->$method($input);
} catch (\Throwable $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
