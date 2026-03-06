<?php

namespace lib\Comment;

class CommentEntity
{
    public string  $id;
    public string  $userId;
    public string  $postId;
    public ?string $parentId  = null;
    public string  $content;
    public array   $imageUrls = [];
    public int     $createdAt;
    public int     $updatedAt;
}
