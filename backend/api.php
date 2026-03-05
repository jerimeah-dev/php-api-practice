<?php

require_once __DIR__ . '/vendor/autoload.php';

try {

    $php_input = file_get_contents('php://input');
    $input = json_decode($php_input, true);
    if ($input === null) {
        $input = $_REQUEST;
    }
    if ($input === null || empty($input['method'])) {
        throw new \Exception('No input provided');
    }

    list($_class_name, $_method_name) = explode('.', trim($input['method']));

    $class = 'lib\\' . ucfirst($_class_name) . '\\' . ucfirst($_class_name) . 'Controller';
    $method = $_method_name;

    $controller = new $class();
    $result = $controller->$method($input);

    echo $result;
} catch (\Throwable $e) {
    header('Content-Type: application/json');

    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
