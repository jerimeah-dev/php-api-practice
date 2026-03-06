<?php

namespace lib\User;

class UserEntity
{
    public string $id;
    public string $email;
    public string $password;
    public string $name          = '';
    public string $avatarUrl     = '';
    public array  $profileImages = [];
    public int    $createdAt;
}
