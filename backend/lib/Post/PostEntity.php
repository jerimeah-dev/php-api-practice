<?php

namespace lib\Post;

class PostEntity
{
    public string $id;
    public string $userId;
    public string $content;
    public array  $imageUrls = [];
    public int    $createdAt;
    public int    $updatedAt;
}
