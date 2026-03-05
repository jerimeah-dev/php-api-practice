# CLAUDE.md

## Project Stack

- **Backend:** Vanilla PHP (no framework), SQLite via PDO, PSR-4 autoload with Composer
- **Frontend:** Flutter, `provider` (ChangeNotifier), `go_router`, `dio`

---

## Backend Architecture

### Structure

```
backend/
  api.php
  lib/
    {Domain}/
      {Domain}Controller.php
      {Domain}Service.php
      {Domain}Repository.php
      {Domain}Entity.php
    Utils/
      Controller.php
      Database.php
```

### Routing

- ALL requests: `POST /api.php` with JSON body `{"method": "domain.methodName", ...params}`
- `api.php` splits the method string → `lib\{Domain}\{Domain}Controller::{methodName}(array $input)`
- No URL parameters. All input via JSON body.

---

### Backend Layer Responsibilities

#### Entity — typed data container only

```php
class UserEntity
{
    public string $id;
    public string $email;
    public string $password;      // always hashed before set
    public ?string $name = '';
    public ?int $birthday = null; // unix timestamp
    public int $followersCount = 0;
    public int $createdAt;
    public array $education = []; // decoded PHP array; repo JSON-encodes on write
}
```

Rules:
- Public typed properties only. No methods, no validation, no logic.
- Array properties hold decoded PHP arrays; the Repository encodes/decodes JSON.

---

#### Repository — raw DB queries only

```php
class UserRepository
{
    public function create(UserEntity $user): bool     { /* INSERT */ }
    public function findById(string $id): ?array       { /* SELECT */ }
    public function findByEmail(string $email): ?array { /* SELECT */ }
    public function existsById(string $id): bool       { /* SELECT, cast bool */ }
    public function existsByEmail(string $email): bool { /* SELECT, cast bool */ }
    public function updateById(UserEntity $user): bool { /* UPDATE */ }
    public function deleteById(string $id): bool       { /* DELETE */ }
    public function getAll(): array                    { /* SELECT * */ }
}
```

Rules:
- ONLY PDO prepared statements. No logic, no validation, no response building.
- Returns raw types: `?array`, `array`, `bool`. Never a JSend response.
- Always prepared statements — never interpolate values into SQL.
- JSON-encode array columns on write; Service decodes them on read.

---

#### Service — validation, business logic, response assembly

```php
class UserService
{
    public UserRepository $repo;

    public function register(array $input): array
    {
        $email = trim($input['email'] ?? '');
        $password = $input['password'] ?? '';

        if (!$email || !$password)
            return ['status' => 'fail', 'data' => ['email' => 'Email and password required']];

        if (!filter_var($email, FILTER_VALIDATE_EMAIL))
            return ['status' => 'fail', 'data' => ['email' => 'Invalid email format']];

        if ($this->repo->existsByEmail($email))
            return ['status' => 'fail', 'data' => ['email' => 'Email already registered']];

        do { $id = bin2hex(random_bytes(8)); } while ($this->repo->existsById($id));

        $entity = new UserEntity();
        $entity->id = $id;
        $entity->email = $email;
        $entity->password = password_hash($password, PASSWORD_DEFAULT);
        $entity->createdAt = time();

        $this->repo->create($entity);
        $row = $this->repo->findById($id);

        unset($row['password']); // never return password

        return ['status' => 'success', 'data' => ['user' => $row]];
    }
}
```

Rules:
- ALL validation and input sanitization here.
- ALL business logic here: ID generation, password hashing, merge-on-update.
- Build Entity here; pass it to Repository.
- Decode JSON columns from DB rows here: `json_decode($row['education'], true) ?? []`
- **Always `unset($row['password'])` before returning user data in a response.**
- Return JSend-shaped arrays (see API Contract below).
- Never access the DB directly — always through Repository.

---

#### Controller — HTTP adapter only

```php
class UserController extends Controller
{
    private UserService $service;
    public function __construct() { $this->service = new UserService(); }

    public function register(array $input)   { return $this->json($this->service->register($input)); }
    public function login(array $input)      { return $this->json($this->service->login($input)); }
    public function updateById(array $input) { return $this->json($this->service->updateById($input)); }
    public function deleteById(array $input) { return $this->json($this->service->deleteById($input)); }
    public function listAll(array $input)    { return $this->json($this->service->listAll()); }
    public function findById(array $input)   { return $this->json($this->service->findById($input)); }
}
```

Rules:
- Each method is ONE line: call service method, wrap in `$this->json()`, return.
- No validation, no conditionals, no business logic.
- Never call `$this->service->repo` directly — always call a service method.

---

### Response Format — JSend Standard

**Success:**
```json
{ "status": "success", "data": { "user": { "id": "...", "email": "..." } } }
```

**Fail** (client error — bad input, duplicate, not found):
```json
{ "status": "fail", "data": { "email": "Email already registered" } }
```

**Error** (server fault — unexpected exception):
```json
{ "status": "error", "message": "An unexpected error occurred" }
```

Rules:
- All success payload inside `"data"` — never at the top level.
- `"fail"` `data` = map of field → reason.
- `"error"` has `message`, no `data`.
- Never return `password` in any response.

---

### Database

- SQLite at `./database/database.db`. `Database::get()` returns new PDO each call.
- Always prepared statements.
- IDs: `bin2hex(random_bytes(8))` — 16-char hex, collision-checked with `existsById`.
- Timestamps: Unix integers (`time()`).
- Array columns: JSON text in DB. Service decodes on read with `json_decode($val, true) ?? []`.

### Auth

- Passwords: `password_hash($p, PASSWORD_DEFAULT)` / `password_verify()`.
- No JWT/sessions currently. Credential-based per request.

### PHP Naming

- camelCase methods and properties.
- CRUD: `create`, `findById`, `findByEmail`, `existsById`, `updateById`, `deleteById`, `getAll`.
- Business: `register`, `login`, `listAll`.

---

## Frontend Architecture

### Structure

```
frontend/lib/
  main.dart
  router/
    router.dart              # GoRouter + globalNavigatorKey + globalContext
  api/
    api.client.dart          # Singleton Dio wrapper
  models/
    {domain}/
      {domain}.model.dart
  repositories/
    {domain}/
      {domain}.repository.dart
  services/
    {domain}/
      {domain}.services.dart
  states/
    {domain}/
      {domain}.state.dart
  screens/
    {domain}/                         # Single-screen domain
      {domain}.screen.dart
    {domain}/                         # Multi-screen domain
      {action}/
        {domain}.{action}.screen.dart
    widgets/
```

**Screen file naming:**
- Single screen: `screens/home/home.screen.dart` → class `HomeScreen`
- Multi screen: `screens/auth/login/auth.login.screen.dart` → class `LoginScreen`
- Multi screen: `screens/post/detail/post.detail.screen.dart` → class `PostDetailScreen`

### File & Class Naming

- Files: `{name}.{type}.dart` — e.g. `user.model.dart`, `api.client.dart`.
- Classes: `{Name}{Type}` — e.g. `UserModel`, `UserService`, `UserState`, `UserRepository`, `ApiClient`.

### Images

- **Always use `CachedNetworkImage`** for all network images — never `Image.network`.
- Always provide `placeholder` and `errorWidget` builders.
- Wrap in `ClipOval` for circular avatars, `ClipRRect` for rounded rectangles.
- When no image is set, show a Google-style initials avatar: colored circle + first letter of name.

---

### Frontend Layer Responsibilities

#### Models — pure data structures only

```dart
class UserModel {
  final String id;
  final String email;
  final String name;
  final DateTime? birthday;
  final int followersCount;
  final DateTime createdAt;
  final List<EducationModel> education;

  const UserModel({required this.id, required this.email, ...});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    // Timestamps: backend sends Unix seconds → multiply by 1000
    birthday: json['birthday'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['birthday'] * 1000)
        : null,
    createdAt: DateTime.fromMillisecondsSinceEpoch((json['createdAt'] ?? 0) * 1000),
    // Arrays: already decoded by Service before fromJson is called
    education: (json['education'] as List? ?? [])
        .map((e) => EducationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'birthday': birthday != null ? birthday!.millisecondsSinceEpoch ~/ 1000 : null,
    'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
    'education': education.map((e) => e.toJson()).toList(),
  };
}
```

Rules:
- `final` fields — models are immutable. `const` constructor.
- Only `fromJson` factory and `toJson` method — no other logic.
- Timestamps: backend = Unix seconds. Convert with `DateTime.fromMillisecondsSinceEpoch(ts * 1000)`.
- Array fields receive already-decoded `List` — Service handles JSON string decoding before calling `fromJson`.
- Nested model classes may live in the same file (EducationModel, WorkExperienceModel, etc).
- No state access, no API calls, no dependencies.

---

#### ApiClient — centralized HTTP config only

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
    // Add interceptors here: logging, auth header injection, etc.
  }

  late final Dio _dio;

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await _dio.post(path, data: body);
    return res.data as Map<String, dynamic>;
  }
}
```

Rules:
- Repositories NEVER import or instantiate Dio.
- ALL base URL, timeout, header, interceptor config ONLY here.
- Adding auth tokens later? One interceptor here — never in repositories.

---

#### Repositories — pure API calls only

```dart
class UserRepository {
  static final instance = UserRepository._();
  UserRepository._();

  Future<Map<String, dynamic>> login({required String email, required String password}) =>
    ApiClient.instance.post('/api.php', {
      'method': 'user.login',
      'email': email,
      'password': password,
    });

  Future<Map<String, dynamic>> updateById({
    required String id,
    String? name,
    String? bio,
    List<Map<String, dynamic>>? education,
  }) =>
    ApiClient.instance.post('/api.php', {
      'method': 'user.updateById',
      'id': id,
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (education != null) 'education': jsonEncode(education),
    });
}
```

Rules:
- ONLY build request body and call `ApiClient.instance.post('/api.php', {...})`.
- Named parameters for all method signatures.
- `if (x != null) 'key': x` spread syntax for optional fields.
- JSON-encode array fields before including them in the request map.
- Return raw `Future<Map<String, dynamic>>` — no parsing, no status checking.
- No error handling, no validation, no state access.

---

#### Services — logic, orchestration, state updates

```dart
class UserService {
  static final instance = UserService._();
  UserService._();

  final _repo = UserRepository.instance;
  final _state = UserState.instance;

  Future<bool> login({required String email, required String password}) async {
    _state.setLoading(true);
    final res = await _repo.login(email: email, password: password);
    final user = _parseUser(res);
    if (user != null) _state.setUser(user);
    _state.setLoading(false);
    return user != null;
  }

  void logout() => _state.clearUser();

  // ---- Private helpers ----

  /// Parse a UserModel from a JSend success response.
  /// Expects: res['status'] == 'success' and res['data']['user'] != null
  UserModel? _parseUser(Map<String, dynamic> res) {
    if (res['status'] != 'success' || res['data']?['user'] == null) return null;
    final map = Map<String, dynamic>.from(res['data']['user']);
    // Decode JSON-string arrays returned by the backend (SQLite stores them as text)
    map['education'] = _decodeList(map['education']);
    map['workExperience'] = _decodeList(map['workExperience']);
    map['profileImages'] = _decodeList(map['profileImages']);
    return UserModel.fromJson(map);
  }

  /// Handles both raw List and JSON-encoded String (from SQLite TEXT column).
  List<Map<String, dynamic>> _decodeList(dynamic value) {
    if (value == null) return [];
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (value is List) {
      return value.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }
}
```

Rules:
- ALL business logic and validation here.
- Check `res['status'] == 'success'` before reading data.
- Read success payload from `res['data']['key']` — never from top-level keys.
- Decode JSON-string array columns with `_decodeList` before passing map to `fromJson`.
- Services are the ONLY layer that calls state mutation methods.
- Wrap async calls with `_state.setLoading(true/false)`.

---

#### States — pure state values only

```dart
class UserState extends ChangeNotifier {
  static final instance = UserState._();
  UserState._();

  String _id = '';
  String get id => _id;

  String _name = '';
  String get name => _name;

  bool _loading = false;
  bool get loading => _loading;

  void setUser(UserModel? u) {
    _user = u;
    if (u == null) { clearUser(); return; }
    _id = u.id;
    _name = u.name;
    // ... hydrate all individual fields
    notifyListeners();
  }

  void clearUser() {
    _id = '';
    _name = '';
    // ... reset all fields to defaults
    notifyListeners();
  }

  void setLoading(bool val) { _loading = val; notifyListeners(); }

  void updateField<T>(T value, void Function(UserState s, T v) updater) {
    updater(this, value);
    notifyListeners();
  }
}
```

Rules:
- Holds values only — no logic, no API calls, no model parsing.
- Every field: private with `_` prefix + public getter.
- `setUser()` hydrates ALL individual fields from the model (enables fine-grained `Selector`).
- `clearUser()` resets all fields to safe defaults and calls `notifyListeners()`.
- `notifyListeners()` called in EVERY setter without exception.

---

## API Contract — Backend ↔ Frontend Alignment

This section is the source of truth. Backend response shapes and frontend parsing MUST match exactly.

### Field naming
- All field names: **camelCase** in both PHP and Dart (e.g. `followersCount`, `websiteUrl`, `workExperience`).

### Timestamps
- Backend sends: **Unix seconds** integer (e.g. `1709123456`).
- Frontend reads: `DateTime.fromMillisecondsSinceEpoch(ts * 1000)`.
- Frontend sends back: `dateTime.millisecondsSinceEpoch ~/ 1000`.

### Array columns (education, workExperience, profileImages)
- Backend stores as JSON text in SQLite.
- Backend returns raw JSON string from DB row (e.g. `"education": "[{...}]"`).
- Frontend Service decodes with `_decodeList()` (handles both String and List).
- Frontend Repository sends encoded: `jsonEncode(list)` in the request body.
- Backend Service decodes received JSON: `json_decode($input['education'], true) ?? []`.

### Password
- Never returned in any API response. Service always `unset($row['password'])` before building `data`.

### JSend contract per endpoint

| Method | Success `data` shape | Fail `data` shape |
|---|---|---|
| `user.register` | `{"user": {...}}` | `{"email": "reason"}` |
| `user.login` | `{"user": {...}}` | `{"email": "Invalid credentials"}` |
| `user.findById` | `{"user": {...}}` | `{"id": "User not found"}` |
| `user.findByEmail` | `{"user": {...}}` | `{"email": "User not found"}` |
| `user.updateById` | `{"user": {...}}` | `{"id": "reason"}` |
| `user.deleteById` | `{"message": "User deleted"}` | `{"id": "User not found"}` |
| `user.listAll` | `{"users": [...]}` | — |

Frontend parses user from: `res['data']['user']`
Frontend parses list from: `res['data']['users']`
Frontend checks delete success: `res['status'] == 'success'`

---

## State Management Rules

- **ONLY** `provider` with `ChangeNotifier`. No Riverpod, BLoC, GetX.
- Registered in `main.dart`: `ChangeNotifierProvider(create: (_) => UserState.instance, ...)`.

#### ABSOLUTE RULE: Never use `watch` or `Consumer`

- **NEVER** `context.watch<T>()` or `Consumer<T>`.
- **ALWAYS** `Selector<StateClass, FieldType>` scoped to the minimum field:
  ```dart
  Selector<UserState, String>(
    selector: (_, state) => state.name,
    builder: (context, name, _) => Text(name),
  )
  ```

---

## Routing Rules

- GoRouter defined in `router/router.dart` as top-level `final router`.
- `globalNavigatorKey` and `globalContext` getter defined in `router.dart`.
- `NoTransitionPage` for auth screens (login, register). Regular `builder` for all others.

#### Every screen MUST have these three static members:

```dart
class HomeScreen extends StatelessWidget {
  static const String routeName = '/';
  static Function(BuildContext ctx) go = (ctx) => ctx.go(routeName);
  static Function(BuildContext ctx) push = (ctx) => ctx.push(routeName);
}
```

- Navigate ONLY via the screen's static `go` or `push` — never with raw strings.
- `go` replaces the stack. `push` layers on top.
- Add the new route to `router/router.dart` when creating any new screen.

---

## Widget Rules

- Stateful only for local UI state (form controllers, loading flags, toggles).
- Stateless for all other widgets.
- Global state only via Service → State → Selector. No direct `setState` for shared state.

---

## General Rules

- No external UI libraries unless approved. Use Material Design.
- No code generation (Freezed, build_runner, json_serializable) unless approved.
- Minimal dependencies — only add clearly necessary packages.
- All Dart code must be null-safe.
- Comments only where logic is genuinely non-obvious.
- No error handling for impossible scenarios — validate only at system boundaries.

---

## Verification Checklist

### New backend domain
- [ ] Controller, Service, Repository, Entity created
- [ ] Controller methods are one-liners — zero logic
- [ ] All validation and business logic in Service
- [ ] Repository contains only prepared statements
- [ ] Responses follow JSend: `{"status": ..., "data": {...}}`
- [ ] `password` field removed with `unset` before building response data

### New frontend screen/domain
- [ ] Screen has `routeName`, `go`, `push` static members
- [ ] Route added to `router/router.dart`
- [ ] No `watch` or `Consumer` — only `Selector`
- [ ] Repository uses `ApiClient.instance.post()` — no Dio import
- [ ] Service reads `res['data']['key']` (not top-level) after checking `res['status'] == 'success'`
- [ ] State class holds values only — `setUser()` hydrates all individual fields
