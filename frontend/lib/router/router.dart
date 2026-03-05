import 'package:flutter/material.dart';
import 'package:frontend/models/post/post.model.dart';
import 'package:frontend/screens/auth/login/auth.login.screen.dart';
import 'package:frontend/screens/auth/register/auth.register.screen.dart';
import 'package:frontend/screens/home/home.screen.dart';
import 'package:frontend/screens/post/detail/post.detail.screen.dart';
import 'package:frontend/screens/post/form/post.form.screen.dart';
import 'package:frontend/screens/profile/profile.screen.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey();
BuildContext get globalContext => globalNavigatorKey.currentContext!;

/// GoRouter
final router = GoRouter(
  navigatorKey: globalNavigatorKey,
  routes: [
    GoRoute(
      path: HomeScreen.routeName,
      name: HomeScreen.routeName,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: LoginScreen.routeName,
      name: LoginScreen.routeName,
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: RegisterScreen.routeName,
      name: RegisterScreen.routeName,
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: ProfileScreen.routeName,
      name: ProfileScreen.routeName,
      builder: (context, state) => ProfileScreen(),
    ),
    GoRoute(
      path: PostFormScreen.routePathCreate,
      builder: (context, state) => const PostFormScreen(),
    ),
    GoRoute(
      path: PostDetailScreen.routePath,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PostDetailScreen(postId: id);
      },
    ),
    GoRoute(
      path: PostFormScreen.routePathEdit,
      builder: (context, state) {
        final post = state.extra as PostModel?;
        return PostFormScreen(post: post);
      },
    ),
  ],
);
