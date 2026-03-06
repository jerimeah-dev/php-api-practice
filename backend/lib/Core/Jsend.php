<?php

namespace lib\Core;

class Jsend
{
    public static function success(array $data): array
    {
        return ['status' => 'success', 'data' => $data];
    }

    public static function fail(array $data): array
    {
        return ['status' => 'fail', 'data' => $data];
    }

    public static function error(string $msg): array
    {
        return ['status' => 'error', 'message' => $msg];
    }
}
