<?php

namespace lib\Core;

use PDO;

abstract class Repository
{
    protected PDO $db;

    public function __construct()
    {
        $this->db = Database::get();
    }

    protected function execute(string $sql, array $params = []): \PDOStatement
    {
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt;
    }

    protected function fetch(string $sql, array $params = []): ?array
    {
        return $this->execute($sql, $params)->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    protected function fetchAll(string $sql, array $params = []): array
    {
        return $this->execute($sql, $params)->fetchAll(PDO::FETCH_ASSOC);
    }
}
