# CLAUDE.md

## Project Overview

A semi-social media / forum app. Users create profiles, write posts and comments, reply to comments (one level deep), and react to posts or comments with Facebook-style reactions. Images are URL-only (no file uploads).

- **Backend:** Vanilla PHP 8.x, SQLite 3 via PDO, PSR-4 autoload with Composer
- **Frontend:** Flutter, `provider` (ChangeNotifier), `go_router`, `dio`

---

## Backend Architecture

### Directory Structure

```
backend/
  api.php
  lib/
    {Domain}/
      {Domain}Controller.php   # HTTP adapter (one-liners only)
      {Domain}Service.php      # Validation + business logic + JSend response
      {Domain}Repository.php   # SQL queries only
      {Domain}Entity.php       # Typed data container
    Core/
      Controller.php           # abstract — json() output only
      Repository.php           # abstract — PDO helpers (fetch, execute, fetchAll)
      Database.php             # Singleton PDO instance
      Jsend.php                # Static JSend builder (used by Services)
```

### Routing

- ALL requests: `POST /api.php` with JSON body `{"method": "domain.methodName", ...params}`
- `api.php` splits the method string → `lib\{Domain}\{Domain}Controller::{methodName}(array $input)`
- No URL parameters. All input via JSON body.

---

### Database

- SQLite at `./database/database.db`.
- `Database::get()` returns a **singleton** PDO instance (one connection per request).
- **`PRAGMA foreign_keys = ON`** is executed inside `Database::get()` — cascades are enforced.
- Always prepared statements — never interpolate values into SQL.
- IDs: `bin2hex(random_bytes(8))` — 16-char hex, collision-checked with `existsById`.
- Timestamps: Unix integers (`time()`). `updatedAt` is set to `time()` on create AND on every update.
- Array columns: stored as JSON text. Service decodes on read; Repository encodes on write.

### Database Schema

```sql
CREATE TABLE IF NOT EXISTS users (
    id             TEXT    PRIMARY KEY,
    email          TEXT    NOT NULL UNIQUE,
    password       TEXT    NOT NULL,
    name           TEXT    NOT NULL DEFAULT '',
    -- avatarUrl: denormalized. Always synced to profileImages[0].url by UserService.
    avatarUrl      TEXT    NOT NULL DEFAULT '',
    -- profileImages: full history, newest-first. Each entry: {"url":"...","createdAt":unix}
    profileImages  TEXT    NOT NULL DEFAULT '[]',
    createdAt      INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS posts (
    id         TEXT    PRIMARY KEY,
    userId     TEXT    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content    TEXT    NOT NULL,
    -- imageUrls: JSON array of URL strings. [] = no images.
    imageUrls  TEXT    NOT NULL DEFAULT '[]',
    createdAt  INTEGER NOT NULL,
    updatedAt  INTEGER NOT NULL
);

-- Single-level nesting only. parentId NULL = comment; non-NULL = reply.
CREATE TABLE IF NOT EXISTS comments (
    id         TEXT    PRIMARY KEY,
    userId     TEXT    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    postId     TEXT    NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    parentId   TEXT             REFERENCES comments(id) ON DELETE CASCADE,
    content    TEXT    NOT NULL,
    -- imageUrls: JSON array of URL strings. [] = no images.
    imageUrls  TEXT    NOT NULL DEFAULT '[]',
    createdAt  INTEGER NOT NULL,
    updatedAt  INTEGER NOT NULL
);

-- One reaction per user per target. targetType = 'post' | 'comment'.
CREATE TABLE IF NOT EXISTS reactions (
    userId     TEXT    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    targetType TEXT    NOT NULL,
    targetId   TEXT    NOT NULL,
    type       TEXT    NOT NULL,  -- 'Like'|'Love'|'Haha'|'Wow'|'Sad'|'Angry'
    createdAt  INTEGER NOT NULL,
    UNIQUE(userId, targetType, targetId)
);
```

**Migration pattern** — add columns to existing tables safely:
```php
try {
    $db->exec("ALTER TABLE posts ADD COLUMN updatedAt INTEGER NOT NULL DEFAULT 0");
} catch (\Throwable) { /* already exists */ }
```

---

### Core Base Classes

#### Core\Database — Singleton PDO

```php
class Database
{
    private static ?PDO $instance = null;

    public static function get(): PDO
    {
        if (self::$instance === null) {
            self::$instance = new PDO('sqlite:' . __DIR__ . '/../../database/database.db');
            self::$instance->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            self::$instance->exec('PRAGMA foreign_keys = ON');
        }
        return self::$instance;
    }
}
```

#### Core\Repository — abstract PDO helpers

```php
abstract class Repository
{
    protected PDO $db;

    public function __construct() { $this->db = Database::get(); }

    protected function execute(string $sql, array $params = []): \PDOStatement
    {
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt;
    }

    protected function fetch(string $sql, array $params = []): ?array
    {
        return $this->execute($sql, $params)->fetch(\PDO::FETCH_ASSOC) ?: null;
    }

    protected function fetchAll(string $sql, array $params = []): array
    {
        return $this->execute($sql, $params)->fetchAll(\PDO::FETCH_ASSOC);
    }
}
```

#### Core\Controller — HTTP output only

```php
abstract class Controller
{
    protected function json(array $data): void
    {
        header('Content-Type: application/json');
        echo json_encode($data);
    }
}
```

#### Core\Jsend — static response builder (used by Services)

```php
class Jsend
{
    public static function success(array $data): array { return ['status' => 'success', 'data' => $data]; }
    public static function fail(array $data): array    { return ['status' => 'fail',    'data' => $data]; }
    public static function error(string $msg): array   { return ['status' => 'error',   'message' => $msg]; }
}
```

---

### Abstraction Principles

```
Request → Controller → Service → Repository → Database
            (HTTP)     (Logic)     (SQL)        (PDO)
```

| Principle | Application |
|---|---|
| **Loose coupling** | Swap a Repository without touching the Service. |
| **Code reuse** | `Core\Repository` provides PDO helpers — zero boilerplate in domain repos. |
| **Enforced contracts** | Abstract base classes guarantee structure across all domains. |
| **Single responsibility** | Entity = data. Repository = SQL. Service = logic. Controller = HTTP. |
| **Testability** | Inject a test PDO into `Database`; mock repositories in unit tests. |

**Hard rules:**
- A layer MUST NOT skip levels. Controller → Service → Repository. Never Controller → Repository.
- All domain repositories MUST extend `Core\Repository`.
- All domain controllers MUST extend `Core\Controller`.
- Services are standalone — they do NOT extend any base class. They use `Jsend::` for responses.
- Cross-cutting concerns (logging, auth) go into `Core/` — never into domain classes.

---

### Layer Responsibilities

#### Entity — typed data container only

```php
class PostEntity
{
    public string $id;
    public string $userId;
    public string $content;
    public array  $imageUrls = [];  // decoded PHP array; Repository JSON-encodes on write
    public int    $createdAt;
    public int    $updatedAt;
}
```

Rules:
- Public typed properties only. No methods, no validation, no logic.
- Array properties hold decoded PHP arrays. Repository JSON-encodes on write.

---

#### Repository — SQL queries only

```php
class PostRepository extends Repository
{
    public function __construct() { parent::__construct(); $this->createTable(); }

    private function createTable(): void
    {
        $this->db->exec("CREATE TABLE IF NOT EXISTS posts (...)");
        // Run ALTER TABLE migrations here too
    }

    public function create(PostEntity $post): bool { /* INSERT */ }
    public function findById(string $id): ?array   { /* SELECT + JOIN users */ }
    public function list(int $limit, int $offset, ?string $authorId): array { /* SELECT + JOIN */ }
    public function countAll(?string $authorId): int { /* SELECT COUNT */ }
    public function updateById(PostEntity $post): bool { /* UPDATE */ }
    public function deleteById(string $id): bool  { /* DELETE */ }
    public function existsById(string $id): bool  { /* SELECT */ }
}
```

Rules:
- Extends `Core\Repository`. Use `$this->execute()`, `$this->fetch()`, `$this->fetchAll()`.
- Returns raw types: `?array`, `array`, `bool`, `int`. Never a JSend response.
- JOINs with `users` table are done here when authorName/authorAvatarUrl are needed.
- JSON-encode array columns on write: `json_encode($entity->imageUrls)`.
- Returns raw SQLite row data — array columns are still JSON strings at this point.

---

#### Service — validation, business logic, response assembly

```php
class PostService
{
    private PostRepository $repo;
    private ReactionRepository $reactionRepo;

    public function __construct()
    {
        $this->repo = new PostRepository();
        $this->reactionRepo = new ReactionRepository();
    }

    public function create(array $input): array
    {
        $userId  = trim($input['userId'] ?? '');
        $content = trim($input['content'] ?? '');
        if (!$userId || !$content)
            return Jsend::fail(['content' => 'userId and content are required']);

        $imageUrls = json_decode($input['imageUrls'] ?? '[]', true) ?? [];

        $entity = new PostEntity();
        $entity->id        = bin2hex(random_bytes(8));
        $entity->userId    = $userId;
        $entity->content   = $content;
        $entity->imageUrls = $imageUrls;
        $entity->createdAt = time();
        $entity->updatedAt = time();

        $this->repo->create($entity);
        $row = $this->repo->findById($entity->id);
        return Jsend::success(['post' => $this->preparePost($row, $userId)]);
    }

    private function preparePost(array $row, string $viewerId): array
    {
        $row['imageUrls']     = json_decode($row['imageUrls'], true) ?? [];
        $row['reactionCounts'] = $this->reactionRepo->getCountsForTarget('post', $row['id']);
        $row['userReaction']  = $viewerId ? $this->reactionRepo->getUserReaction('post', $row['id'], $viewerId) : null;
        return $row;
    }
}
```

Rules:
- ALL validation and input sanitization here.
- ALL business logic: ID generation, password hashing, merge-on-update, `updatedAt = time()`.
- Build Entity here; pass to Repository.
- **Decode all JSON array columns** from raw DB rows before building response:
  - `json_decode($row['imageUrls'], true) ?? []`
  - `json_decode($row['profileImages'], true) ?? []`
- **Attach reaction data** to every post/comment row before returning (use batch queries for lists).
- `unset($row['password'])` before returning any user data.
- Return responses via `Jsend::success([...])` / `Jsend::fail([...])` / `Jsend::error('...')`.
- Never access DB directly — always through Repository.
- **Image URL validation:** `filter_var($url, FILTER_VALIDATE_URL)`. Optionally `get_headers()` check — if headers fail (bot blocking), allow anyway. Frontend `errorWidget` handles broken images.
- `updatedAt` rule: set to `time()` on CREATE (same value as `createdAt`). Update to `time()` on every UPDATE.

---

#### Controller — HTTP adapter only

```php
class PostController extends Controller
{
    private PostService $service;
    public function __construct() { $this->service = new PostService(); }

    public function create(array $input)     { $this->json($this->service->create($input)); }
    public function list(array $input)       { $this->json($this->service->list($input)); }
    public function getById(array $input)    { $this->json($this->service->getById($input)); }
    public function updateById(array $input) { $this->json($this->service->updateById($input)); }
    public function deleteById(array $input) { $this->json($this->service->deleteById($input)); }
}
```

Rules:
- Each method is ONE line: call service, wrap in `$this->json()`.
- No validation, no conditionals, no business logic.
- Never call `$this->service->repo` — always call a service method.

---

### Response Format — JSend Standard

```json
{ "status": "success", "data": { "post": {...} } }
{ "status": "fail",    "data": { "content": "Content is required" } }
{ "status": "error",   "message": "An unexpected error occurred" }
```

- All success payload inside `"data"`.
- `"fail"` data = `{ fieldName: "reason" }`.
- `"error"` has `message` only, no `data`.
- Never return `password`.

---

### Auth

- `password_hash($p, PASSWORD_DEFAULT)` / `password_verify()`.
- No JWT/sessions. `userId` is sent in the body of every protected request.

### PHP Naming

- camelCase methods and properties.
- CRUD: `create`, `findById`, `existsById`, `updateById`, `deleteById`.
- Paginated fetch: `list(array $input)`.
- Business: `register`, `login`.

---

## API Contract

All requests: `POST /api.php` with JSON body `{"method": "domain.action", ...params}`.

### Endpoints

| Method | Params | Success `data` shape |
|---|---|---|
| `user.register` | email, password, name? | `{"user": {...}}` |
| `user.login` | email, password | `{"user": {...}}` |
| `user.findById` | id | `{"user": {...}}` |
| `user.updateById` | id, name?, profileImages? | `{"user": {...}}` |
| `user.deleteById` | id | `{"message": "User deleted"}` |
| `post.list` | viewerId, limit, offset, authorId? | `{"posts": [...], "total": 42, "hasMore": true}` |
| `post.getById` | id, viewerId | `{"post": {...}}` |
| `post.create` | userId, content, imageUrls? | `{"post": {...}}` |
| `post.updateById` | id, content?, imageUrls? | `{"post": {...}}` |
| `post.deleteById` | id | `{"message": "Post deleted"}` |
| `comment.list` | postId, viewerId, limit, offset | `{"comments": [...], "hasMore": false}` |
| `comment.create` | userId, postId, content, parentId?, imageUrls? | `{"comment": {...}}` |
| `comment.updateById` | id, content?, imageUrls? | `{"comment": {...}}` |
| `comment.deleteById` | id | `{"message": "Comment deleted"}` |
| `reaction.toggle` | userId, targetType, targetId, type | `{"action": "added"/"removed"/"changed", "reactionCounts": {...}, "userReaction": "Like"/null}` |

**Param notes:**
- `viewerId` — logged-in user's ID. Backend uses it to compute `userReaction` on each item. Pass `""` for unauthenticated (userReaction will be `null`).
- `authorId` (optional on `post.list`) — filter to a specific user's posts. Omit for global feed.
- `parentId` (optional on `comment.create`) — creates a reply if provided; top-level comment if omitted/null.
- `imageUrls` — JSON-encoded string: `jsonEncode(["https://..."])`. Send `"[]"` to clear images.
- `profileImages` — JSON-encoded string of full replacement array.

### Reaction types (exact strings, case-sensitive)
`Like`, `Love`, `Haha`, `Wow`, `Sad`, `Angry`

### Pagination
```json
{ "status": "success", "data": { "posts": [...], "total": 42, "hasMore": true } }
```
- `total`: total matching rows.
- `hasMore`: `true` when `offset + len(page) < total`.

### Comment / Reply rules
- `parentId = null` → top-level comment.
- `parentId = <commentId>` → reply to that comment.
- Backend **rejects** if target parent already has a non-null `parentId` (no 3rd-level): returns `fail {"parentId": "Replies cannot be nested"}`.
- `comment.list` returns a **flat array** of ALL comments and replies for the post, sorted `createdAt ASC`. Frontend groups them: collect replies where `reply.parentId == comment.id`.

### Data Shapes

**User** (password never returned):
```json
{
  "id": "abc123",
  "email": "alice@example.com",
  "name": "Alice",
  "avatarUrl": "https://...",
  "profileImages": [
    { "url": "https://img-new.jpg", "createdAt": 1709123456 },
    { "url": "https://img-old.jpg", "createdAt": 1700000000 }
  ],
  "createdAt": 1700000000
}
```
- `profileImages`: full history, newest first. Frontend manages ordering.
- `avatarUrl`: always `profileImages[0].url`, synced by `UserService` on every update. Never set directly.
- `profileImages` on `user.updateById`: frontend sends the **complete replacement array** (JSON-encoded). Backend stores it as-is and syncs `avatarUrl`.

**Post** (includes denormalized author):
```json
{
  "id": "abc123",
  "userId": "user1",
  "authorName": "Alice",
  "authorAvatarUrl": "https://...",
  "content": "Hello world",
  "imageUrls": ["https://img1.jpg", "https://img2.jpg"],
  "reactionCounts": { "Like": 3, "Love": 1 },
  "userReaction": "Like",
  "createdAt": 1709123456,
  "updatedAt": 1709123456
}
```

**Comment** (includes denormalized author):
```json
{
  "id": "cmt1",
  "postId": "abc123",
  "parentId": null,
  "userId": "user1",
  "authorName": "Alice",
  "authorAvatarUrl": "https://...",
  "content": "Great post!",
  "imageUrls": ["https://img.jpg"],
  "reactionCounts": { "Like": 2 },
  "userReaction": null,
  "createdAt": 1709123456,
  "updatedAt": 1709123456
}
```

Backend JOINs `users` on all post/comment queries to include `authorName` and `authorAvatarUrl`.

### Critical: reactionCounts empty-state

PHP `json_encode([])` produces `[]` (JSON array), not `{}` (JSON object). When there are no reactions the backend returns `"reactionCounts": []`. Dart parses `[]` as `List`, not `Map`.

**Frontend Service MUST normalize before `Model.fromJson`:**
```dart
final rc = map['reactionCounts'];
if (rc == null || rc is List) map['reactionCounts'] = <String, dynamic>{};
```

### Array columns — wire format

| Direction | What happens |
|---|---|
| **Backend → Frontend** | Service decodes JSON string columns (`json_decode($row['imageUrls'], true) ?? []`) before building response. `json_encode()` of the full response turns PHP arrays into proper JSON arrays. Frontend receives `[...]` not `"[...]"`. |
| **Frontend → Backend** | Repository sends JSON-encoded string: `'imageUrls': jsonEncode(urls)`. Backend Service decodes: `json_decode($input['imageUrls'] ?? '[]', true) ?? []`. |

Frontend `_decodeList` is a **defensive type-cast helper**, not a JSON string decoder:
```dart
/// Converts dynamic (List or null) → List<Map<String,dynamic>>.
/// Handles String as a safety net in case backend forgot to decode.
List<Map<String, dynamic>> _decodeList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  if (value is String && value.isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is List) return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
}
```

For `imageUrls` (List<String>, not List<Map>), cast directly in `fromJson`:
```dart
imageUrls: (json['imageUrls'] as List? ?? []).cast<String>(),
```

---

## Frontend Architecture

### Directory Structure

```
frontend/lib/
  main.dart
  router/
    router.dart              # GoRouter config + globalNavigatorKey + globalContext
  api/
    api.client.dart          # Singleton Dio wrapper
  models/
    user/user.model.dart
    post/post.model.dart
    comment/comment.model.dart
  repositories/
    user/user.repository.dart
    post/post.repository.dart
    comment/comment.repository.dart
    reaction/reaction.repository.dart
  services/
    user/user.services.dart
    post/post.services.dart
    comment/comment.services.dart
    reaction/reaction.services.dart
  states/
    user/user.state.dart
    post/post.state.dart
    comment/comment.state.dart
  screens/
    home/
      home.screen.dart
    auth/
      login/auth.login.screen.dart
      register/auth.register.screen.dart
    profile/
      profile.screen.dart
    post/
      detail/post.detail.screen.dart
      form/post.form.screen.dart
  widgets/
    post_author_avatar.dart
    reaction_bar.dart
    post_image_grid.dart
```

### Screens & Navigation

| Screen | Route | Class |
|---|---|---|
| Home (global feed) | `/` | `HomeScreen` |
| Login | `/login` | `LoginScreen` |
| Register | `/register` | `RegisterScreen` |
| Profile | `/profile/:id` | `ProfileScreen` |
| Post detail | `/post/:id` | `PostDetailScreen` |
| Post create/edit | `/post/form` | `PostFormScreen` |

**Navigation flow:**
- App start → `UserState.id.isEmpty` → redirect to `/login`, else `/`.
- Home: FAB creates post → `PostFormScreen.push`. Tap post card → `PostDetailScreen.push`. Tap author → `ProfileScreen.push`.
- PostDetail: shows post body + image gallery + reaction bar + paginated comments with inline replies.
- Profile: two tabs — **Posts** (infinite scroll, `post.list` with `authorId`) and **Photos** (grid of `profileImages` entries). Own profile shows Edit button.
- Login/Register use `NoTransitionPage`. All others use standard `builder`.

**Static screen members (required on every screen):**
```dart
class HomeScreen extends StatelessWidget {
  static const String routeName = '/';
  static void go(BuildContext ctx)   => ctx.go(routeName);
  static void push(BuildContext ctx) => ctx.push(routeName);
}
```
Navigate ONLY via `ScreenName.go(ctx)` or `ScreenName.push(ctx)` — never with raw strings.

---

### File & Class Naming

- Files: `{name}.{type}.dart` — e.g. `user.model.dart`, `post.services.dart`.
- Classes: `{Name}{Type}` — e.g. `UserModel`, `PostService`, `CommentState`, `ReactionRepository`.

### Images

- **Always `CachedNetworkImage`** — never `Image.network`.
- Always provide `placeholder` and `errorWidget`.
- `errorWidget`: colored container with broken-image icon. Never blank, never crash.
- Circular avatars: `ClipOval`. Rounded rect images: `ClipRRect`.
- Empty `avatarUrl`: show Google-style initials avatar (colored circle + first letter of name).

---

### Frontend Models

#### UserModel
```dart
class UserModel {
  final String id;
  final String email;
  final String name;
  final String avatarUrl;
  final List<ProfileImageModel> profileImages;  // full history, newest first
  final DateTime createdAt;
}

class ProfileImageModel {
  final String url;
  final DateTime createdAt;
}
```

#### PostModel
```dart
class PostModel {
  final String id;
  final String userId;
  final String authorName;
  final String authorAvatarUrl;
  final String content;
  final List<String> imageUrls;
  final Map<String, int> reactionCounts;  // e.g. {"Like": 3, "Love": 1}
  final String? userReaction;             // null = no reaction from viewer
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### CommentModel
```dart
class CommentModel {
  final String id;
  final String postId;
  final String? parentId;    // null = top-level comment; non-null = reply
  final String userId;
  final String authorName;
  final String authorAvatarUrl;
  final String content;
  final List<String> imageUrls;
  final Map<String, int> reactionCounts;
  final String? userReaction;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

Model rules:
- `final` fields — immutable. `const` constructor.
- Only `fromJson` factory and `toJson` — no other logic.
- Timestamps: Unix seconds from backend → `DateTime.fromMillisecondsSinceEpoch(ts * 1000)`.
- `imageUrls`: `(json['imageUrls'] as List? ?? []).cast<String>()`
- `reactionCounts`: after Service normalizes `[]` → `{}`, use `Map<String,dynamic>.from(json['reactionCounts'] ?? {}).map((k, v) => MapEntry(k, v as int))`
- `profileImages`: after Service calls `_decodeList`, use standard `List.map(ProfileImageModel.fromJson)`

---

### Frontend Layer Responsibilities

#### ApiClient — HTTP config only

```dart
class ApiClient {
  static final instance = ApiClient._();
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1:12345',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ));
  }
  late final Dio _dio;
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await _dio.post(path, data: body);
    return res.data as Map<String, dynamic>;
  }
}
```

Rules: Repositories NEVER import Dio. All config here only.

---

#### Repositories — raw API calls only

Rules:
- ONLY build request body + call `ApiClient.instance.post('/api.php', {...})`.
- Named parameters. `if (x != null) 'key': x` spread for optional fields.
- JSON-encode array fields: `'imageUrls': jsonEncode(urls)`.
- Return raw `Future<Map<String, dynamic>>`. No parsing, no status checks.

---

#### Services — logic, state updates, response parsing

Rules:
- Check `res['status'] == 'success'` before reading data.
- Read from `res['data']['key']` — never top-level keys.
- Only layer that calls state mutation methods.
- Wrap with `_state.setLoading(true/false)`.

**Parsing helpers (define in each Service that needs them):**
```dart
// For List<Map> columns (profileImages)
List<Map<String, dynamic>> _decodeList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  if (value is String && value.isNotEmpty) {
    final d = jsonDecode(value);
    if (d is List) return d.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
}

// Applied before Model.fromJson:
PostModel _parsePost(Map<String, dynamic> raw) {
  final map = Map<String, dynamic>.from(raw);
  // reactionCounts: normalize PHP [] → {}
  final rc = map['reactionCounts'];
  if (rc == null || rc is List) map['reactionCounts'] = <String, dynamic>{};
  // imageUrls arrives as List<dynamic> — fromJson handles cast<String>()
  // No decodeList needed for imageUrls (it's List<String>, not List<Map>)
  return PostModel.fromJson(map);
}

UserModel _parseUser(Map<String, dynamic> raw) {
  final map = Map<String, dynamic>.from(raw);
  map['profileImages'] = _decodeList(map['profileImages']);
  return UserModel.fromJson(map);
}
```

**Optimistic UI for reactions:**
```dart
Future<void> toggleReaction({required String targetType, required String targetId, required String type}) async {
  final prev = _state.getReactionSnapshot(targetId);
  _state.applyOptimisticReaction(targetId: targetId, type: type);
  final res = await _repo.toggleReaction(
    userId: _userState.id, targetType: targetType, targetId: targetId, type: type);
  if (res['status'] == 'success') {
    final rc = res['data']['reactionCounts'];
    final ur = res['data']['userReaction'] as String?;
    _state.applyReactionResult(targetId: targetId, reactionCounts: Map<String,int>.from(rc is List ? {} : rc), userReaction: ur);
  } else {
    _state.rollbackReaction(targetId: targetId, snapshot: prev);
  }
}
```

---

#### States — values only

Rules:
- No logic, no API calls, no model parsing.
- Every field: private `_` prefix + public getter.
- Setter methods hydrate ALL individual fields from model.
- `notifyListeners()` in EVERY setter without exception.

**Selector for list state:** when items in a list update (e.g. reaction count on one post), update the specific item and replace the list reference so Selector detects the change:
```dart
void updatePost(PostModel updated) {
  _posts = _posts.map((p) => p.id == updated.id ? updated : p).toList();
  notifyListeners();
}
```

---

### UI/UX Patterns

#### Post image grid (`PostImageGrid` widget)

| Count | Layout |
|---|---|
| 1 | Full-width, fixed height (260px) |
| 2 | Two equal columns side by side |
| 3 | Top: full-width; bottom row: two equal columns |
| 4+ | 2×2 grid; bottom-right cell shows `+N` overlay for remaining count |

Tap any image → push fullscreen `PageView` viewer with `InteractiveViewer` (pinch to zoom).

#### Reaction bars (`reaction_bar.dart`)

- **`CompactReactionBar`** — used on post cards in feed AND on comments/replies:
  - Shows top 2 emoji + total count + "React" pill button.
  - Tap React → bottom sheet with 6 emoji circles.
- **`FullReactionBar`** — used on `PostDetailScreen` for the post only:
  - Shows all 6 reaction buttons inline with per-type counts.

#### Comments + Replies (on PostDetailScreen)

- Comments section lives at the bottom of `PostDetailScreen`, below the post body.
- `comment.list` returns a flat list. Frontend groups:
  ```dart
  final topLevel = comments.where((c) => c.parentId == null).toList();
  List<CommentModel> repliesFor(String commentId) =>
    comments.where((c) => c.parentId == commentId).toList();
  ```
- Replies are visually indented (16px left padding + vertical line or avatar offset).
- Each comment row:
  - Author avatar + name + timestamp
  - Content text
  - Image grid (if `imageUrls` non-empty)
  - `CompactReactionBar`
  - "Reply" text button → shows inline reply input field
- Reply input: appears below the target comment (not at the bottom of the screen). On submit: calls `comment.create` with `parentId` set. On success: inserts the new reply into the local flat list and regroups.
- Both comments and replies can be reacted to (same `reaction.toggle` with `targetType: 'comment'`).

#### Profile screen sections

`ProfileScreen` has two tabs:
1. **Posts** — `ListView` with infinite scroll. Uses `post.list` with `authorId = profileUserId`. Same `PostCard` as home feed.
2. **Photos** — `GridView` (3 columns) of all `profileImages` entries. Tap → fullscreen viewer. Newest first.

Own profile (when `profileUserId == UserState.instance.id`): shows Edit Profile button in AppBar.

---

### Pagination — Infinite Scroll

```dart
_scrollController.addListener(() {
  final pos = _scrollController.position;
  if (pos.pixels >= pos.maxScrollExtent * 0.8) {
    service.loadNextPage();  // no-op if loading or !hasMore
  }
});
```

**State accumulation:**
```dart
void appendPosts(List<PostModel> page, bool hasMore) {
  _posts = [..._posts, ...page];
  _hasMore = hasMore;
  notifyListeners();
}
```

**Pull-to-refresh:**
```dart
Future<void> refresh() async {
  _state.clearPosts();       // resets list + offset to 0
  await _loadPage(offset: 0);
}
```

---

## State Management Rules

- **ONLY** `provider` with `ChangeNotifier`. No Riverpod, BLoC, GetX.
- Registered in `main.dart` with `MultiProvider`.

#### ABSOLUTE RULE: Never use `watch` or `Consumer`

- **NEVER** `context.watch<T>()` or `Consumer<T>`.
- **ALWAYS** `Selector<StateClass, FieldType>` scoped to the minimum field:
  ```dart
  Selector<UserState, String>(
    selector: (_, s) => s.name,
    builder: (context, name, _) => Text(name),
  )
  ```
- Multiple primitives → record tuple:
  ```dart
  Selector<PostState, (int, bool)>(
    selector: (_, s) => (s.postCount, s.hasMore),
    builder: (context, val, _) => Text('${val.$1} posts'),
  )
  ```
- For list rebuilds, select the list itself (Selector compares by `==`; replacing the list reference triggers rebuild):
  ```dart
  Selector<PostState, List<PostModel>>(
    selector: (_, s) => s.posts,
    builder: (context, posts, _) => ListView(...),
  )
  ```

---

## Routing Rules

- GoRouter defined in `router/router.dart` as top-level `final router`.
- `globalNavigatorKey` and `globalContext` getter defined in `router.dart`.
- `NoTransitionPage` for auth screens. Regular `builder` for all others.
- Add every new screen to `router.dart` when created.

---

## Widget Rules

- Stateful only for local UI state (form controllers, scroll controllers, loading flags, toggles, reply input visibility).
- Stateless for everything else.
- Global state only via Service → State → Selector.
- Shared widgets live in `frontend/lib/widgets/`.

---

## General Rules

- No external UI libraries unless approved. Material Design.
- No code generation (Freezed, build_runner, json_serializable) unless approved.
- Minimal dependencies — only clearly necessary packages.
- All Dart code must be null-safe.
- Comments only where logic is non-obvious.
- No error handling for impossible scenarios — validate only at system boundaries.

---

## Verification Checklist

### New backend domain
- [ ] Controller, Service, Repository, Entity created
- [ ] Repository extends `Core\Repository`; uses `$this->fetch()` / `$this->execute()` / `$this->fetchAll()`
- [ ] Controller methods are one-liners — `$this->json($this->service->method($input))`
- [ ] All validation and business logic in Service; Service uses `Jsend::` for responses
- [ ] `updatedAt = time()` set on create and on every update
- [ ] All JSON array columns decoded (`json_decode($row['col'], true) ?? []`) before building response
- [ ] `reactionCounts` attached to every post/comment via ReactionRepository (batch query for lists)
- [ ] `password` removed with `unset` before any user response
- [ ] `PRAGMA foreign_keys = ON` enforced via `Database::get()` singleton

### New frontend screen/domain
- [ ] Screen has `static routeName`, `static go`, `static push`
- [ ] Route added to `router/router.dart`
- [ ] No `watch` or `Consumer` — only `Selector`
- [ ] Repository uses `ApiClient.instance.post()` — no Dio import
- [ ] Service reads `res['data']['key']` after `res['status'] == 'success'` check
- [ ] Service: `_decodeList` applied to `profileImages`; `cast<String>()` applied to `imageUrls`
- [ ] Service: `reactionCounts` normalized — `if (rc == null || rc is List) map['reactionCounts'] = {}`
- [ ] Repository JSON-encodes array fields: `jsonEncode(list)`
- [ ] State hydrates ALL individual fields in setters; `notifyListeners()` in every setter
- [ ] Infinite scroll: `ScrollController` triggers at 80%; pull-to-refresh clears state and resets offset
- [ ] Optimistic UI on reaction toggle: snapshot → apply → confirm or rollback
- [ ] `CachedNetworkImage` for all network images with `placeholder` and `errorWidget`
- [ ] Image grid uses `PostImageGrid` widget (1/2/3/4+ layouts)
- [ ] `CompactReactionBar` on cards and comments; `FullReactionBar` on post detail only
