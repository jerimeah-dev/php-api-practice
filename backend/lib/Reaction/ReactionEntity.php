<?php

namespace lib\Reaction;

class ReactionEntity
{
    public string $id;
    public string $postId;
    public string $userId;
    public string $type; // like | love | haha | wow | sad | angry
    public int $createdAt;
}
