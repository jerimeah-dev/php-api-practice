<?php

namespace lib\Utils;

use PDO;

class Database
{
    static public $path =  './database/database.db';
    public function __construct()
    {
        // Ensure the database directory exists
        $dir = dirname(self::$path);
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }
    }

    static public function get(): PDO
    {
        $db = new PDO('sqlite:' . self::$path);
        $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return $db;
    }
}
