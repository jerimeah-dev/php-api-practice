<?php

namespace lib\Config;

class ConfigService
{
    public ConfigRepository $repo;

    public function __construct()
    {
        $this->repo = new ConfigRepository();
    }

    // ---------------- INSTALL ----------------
    public function install(): array
    {
        try {
            $this->repo->installTable();

            return [
                'status' => 'success',
                'message' => 'Config table installed'
            ];
        } catch (\PDOException $e) {
            return [
                'status' => 'error',
                'message' => $e->getMessage()
            ];
        }
    }

    // ---------------- GET ALL ----------------
    public function getAll(): array
    {
        return [
            'status' => 'success',
            'configs' => $this->repo->getAll()
        ];
    }

    // ---------------- SET / UPSERT ----------------
    public function set(array $input): array
    {
        $key = $input['key'] ?? '';
        $value = $input['value'] ?? '';

        if (!$key) {
            return ['status' => 'error', 'message' => 'Key required'];
        }

        $config = $this->repo->upsert($key, $value);

        return [
            'status' => 'success',
            'config' => [
                'id' => $config->id,
                'key' => $config->key,
                'value' => $config->value
            ]
        ];
    }
}