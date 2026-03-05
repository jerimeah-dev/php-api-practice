<?php

namespace lib\User;

class UserEntity
{
    public string $id;           
    public string $email;      
    public string $password;
    public ?string $name = '';
    public ?int $birthday = null; 
    public ?string $bio = '';
    public ?string $websiteUrl = '';

    public int $followersCount = 0;
    public int $followingCount = 0;
    public int $postsCount = 0;
    public int $createdAt; 

    public string $currentAvatarUrl = '';
    public array $education = [];
    public array $workExperience = [];
    public array $profileImages = [];
}