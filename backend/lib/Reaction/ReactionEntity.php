<?php

namespace lib\Reaction;

class ReactionEntity
{
    public string $userId;
    public string $targetType; // 'post' | 'comment'
    public string $targetId;
    public string $type;       // 'Like'|'Love'|'Haha'|'Wow'|'Sad'|'Angry'
    public int    $createdAt;
}
