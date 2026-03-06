<?php

namespace lib\Core;

use PDO;

class Database
{
    private static ?PDO $instance = null;

    public static function get(): PDO
    {
        if (self::$instance === null) {
            $path = __DIR__ . '/../../database/database.db';
            $dir  = dirname($path);
            if (!is_dir($dir)) {
                mkdir($dir, 0755, true);
            }
            self::$instance = new PDO('sqlite:' . $path);
            self::$instance->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            self::$instance->exec('PRAGMA foreign_keys = ON');
        }
        return self::$instance;
    }
}
