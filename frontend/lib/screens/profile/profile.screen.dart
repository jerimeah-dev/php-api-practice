import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/user/user.model.dart';
import 'package:frontend/services/user/user.services.dart';
import 'package:frontend/states/user/user.state.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const String routeName = '/profile';
  static Function(BuildContext ctx) push = (ctx) => ctx.push(routeName);
  static Function(BuildContext ctx) go = (ctx) => ctx.go(routeName);

  @override
  Widget build(BuildContext context) {
    return Selector<UserState, UserModel?>(
      selector: (_, s) => s.user,
      builder: (context, user, _) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _ProfileView(user: user);
      },
    );
  }
}

// ─── Main profile view ────────────────────────────────────────────────────────

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton.icon(
            onPressed: () {
              UserService.instance.logout();
              context.go('/login');
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarHeader(user: user),
            const SizedBox(height: 24),
            const _StatsRow(),
            const SizedBox(height: 24),
            _AboutSection(user: user),
            const SizedBox(height: 24),
            _PasswordSection(user: user),
            if (user.profileImages.isNotEmpty) ...[
              const SizedBox(height: 24),
              _PhotosSection(user: user),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Avatar + name + bio header ──────────────────────────────────────────────

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final currentImage = user.profileImages.isNotEmpty
        ? user.profileImages.firstWhere(
            (i) => i.isCurrent,
            orElse: () => user.profileImages.first,
          )
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        GestureDetector(
          onTap: () => _showImagesSheet(context, user),
          child: Stack(
            children: [
              _buildAvatar(currentImage?.url, user.name, 80),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.name.isNotEmpty ? user.name : 'No name',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _editField(
                      context,
                      label: 'Name',
                      initial: user.name,
                      onSave: (v) => UserService.instance.updateProfile(name: v),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Email
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      user.email,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: () => _editField(
                      context,
                      label: 'Email',
                      initial: user.email,
                      keyboardType: TextInputType.emailAddress,
                      onSave: (v) => UserService.instance.updateProfile(email: v),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Bio
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      user.bio.isNotEmpty ? user.bio : 'No bio',
                      style: const TextStyle(fontSize: 13),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: () => _editField(
                      context,
                      label: 'Bio',
                      initial: user.bio,
                      maxLines: 4,
                      onSave: (v) => UserService.instance.updateProfile(bio: v),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Stats row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Selector<UserState, (int, int, int)>(
      selector: (_, s) => (s.postsCount, s.followersCount, s.followingCount),
      builder: (_, counts, __) {
        final (posts, followers, following) = counts;
        return Row(
          children: [
            _StatTile(label: 'Posts', value: posts),
            _StatTile(label: 'Followers', value: followers),
            _StatTile(label: 'Following', value: following),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── About section ───────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.link,
          label: 'Website',
          value: user.websiteUrl.isNotEmpty ? user.websiteUrl : '—',
          onEdit: () => _editField(
            context,
            label: 'Website URL',
            initial: user.websiteUrl,
            keyboardType: TextInputType.url,
            onSave: (v) => UserService.instance.updateProfile(websiteUrl: v),
          ),
        ),
        _InfoRow(
          icon: Icons.cake_outlined,
          label: 'Birthday',
          value: user.birthday != null
              ? '${user.birthday!.day}/${user.birthday!.month}/${user.birthday!.year}'
              : '—',
          onEdit: () => _pickBirthday(context, user.birthday),
        ),
        _InfoRow(
          icon: Icons.access_time_outlined,
          label: 'Joined',
          value: '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
          onEdit: null,
        ),
        const SizedBox(height: 12),
        // Add photo URL button
        OutlinedButton.icon(
          onPressed: () => _showImagesSheet(context, user),
          icon: const Icon(Icons.add_a_photo_outlined, size: 16),
          label: const Text('Manage Photos'),
        ),
      ],
    );
  }

  void _pickBirthday(BuildContext context, DateTime? current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      await UserService.instance.updateProfile(
        birthday: picked.millisecondsSinceEpoch ~/ 1000,
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 16),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

// ─── Password section ────────────────────────────────────────────────────────

class _PasswordSection extends StatelessWidget {
  const _PasswordSection({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _changePassword(context),
          icon: const Icon(Icons.lock_outline, size: 16),
          label: const Text('Change Password'),
        ),
      ],
    );
  }

  void _changePassword(BuildContext context) {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Change Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (newPassCtrl.text.length < 6) {
                      setState(() => error = 'Min 6 characters');
                      return;
                    }
                    if (newPassCtrl.text != confirmCtrl.text) {
                      setState(() => error = 'Passwords do not match');
                      return;
                    }
                    Navigator.pop(ctx);
                    await UserService.instance.updateProfile(password: newPassCtrl.text);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Photos section ──────────────────────────────────────────────────────────

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
              onPressed: () => _showImagesSheet(context, user),
              child: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: user.profileImages.length,
          itemBuilder: (context, index) {
            final img = user.profileImages[index];
            return GestureDetector(
              onTap: () => _setAsCurrent(img, user),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: img.url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  if (img.isCurrent)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _setAsCurrent(ProfileImageModel selected, UserModel user) {
    final updated = user.profileImages.map((img) {
      return ProfileImageModel(
        url: img.url,
        albumName: img.albumName,
        uploadedAt: img.uploadedAt,
        isCurrent: img.url == selected.url,
      );
    }).toList();
    UserService.instance.updateProfile(profileImages: updated);
  }
}

// ─── Manage images bottom sheet ──────────────────────────────────────────────

void _showImagesSheet(BuildContext context, UserModel user) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ImagesSheet(user: user),
  );
}

class _ImagesSheet extends StatefulWidget {
  const _ImagesSheet({required this.user});
  final UserModel user;

  @override
  State<_ImagesSheet> createState() => _ImagesSheetState();
}

class _ImagesSheetState extends State<_ImagesSheet> {
  late List<ProfileImageModel> _images;
  final _urlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.user.profileImages);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _addImage() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _images.add(ProfileImageModel(
        url: url,
        albumName: '',
        uploadedAt: DateTime.now(),
        isCurrent: _images.isEmpty,
      ));
      _urlCtrl.clear();
    });
  }

  void _removeImage(int index) {
    setState(() {
      final wasActive = _images[index].isCurrent;
      _images.removeAt(index);
      if (wasActive && _images.isNotEmpty) {
        _images[0] = ProfileImageModel(
          url: _images[0].url,
          albumName: _images[0].albumName,
          uploadedAt: _images[0].uploadedAt,
          isCurrent: true,
        );
      }
    });
  }

  void _setCurrent(int index) {
    setState(() {
      _images = _images.asMap().entries.map((e) {
        return ProfileImageModel(
          url: e.value.url,
          albumName: e.value.albumName,
          uploadedAt: e.value.uploadedAt,
          isCurrent: e.key == index,
        );
      }).toList();
    });
  }

  Future<void> _save() async {
    Navigator.pop(context);
    await UserService.instance.updateProfile(profileImages: _images);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Manage Photos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
          const SizedBox(height: 16),
          // Add URL field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _addImage, child: const Text('Add')),
            ],
          ),
          const SizedBox(height: 16),
          if (_images.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No photos yet', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _images.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final img = _images[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: CachedNetworkImage(
                          imageUrl: img.url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey[200]),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      img.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: img.isCurrent
                        ? const Text('Current avatar',
                            style: TextStyle(color: Colors.blue, fontSize: 11))
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!img.isCurrent)
                          TextButton(
                            onPressed: () => _setCurrent(index),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const Text('Set avatar', style: TextStyle(fontSize: 12)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _removeImage(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

/// Google-style circle avatar: shows cached image or colored initial
Widget _buildAvatar(String? imageUrl, String name, double size) {
  if (imageUrl != null && imageUrl.isNotEmpty) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => _initialsAvatar(name, size),
        errorWidget: (_, _, _) => _initialsAvatar(name, size),
      ),
    );
  }
  return _initialsAvatar(name, size);
}

Widget _initialsAvatar(String name, double size) {
  final initials = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
  final color = _avatarColor(name);
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.4,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Color _avatarColor(String name) {
  const colors = [
    Color(0xFF1A73E8),
    Color(0xFF34A853),
    Color(0xFFEA4335),
    Color(0xFFFBBC05),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
  ];
  if (name.isEmpty) return colors[0];
  return colors[name.codeUnitAt(0) % colors.length];
}

/// Generic single-field edit bottom sheet
void _editField(
  BuildContext context, {
  required String label,
  required String initial,
  required Future<UserModel?> Function(String) onSave,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
}) {
  final ctrl = TextEditingController(text: initial);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit $label',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            maxLines: maxLines,
            autofocus: true,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await onSave(ctrl.text.trim());
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    ),
  );
}
