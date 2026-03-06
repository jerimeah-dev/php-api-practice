import 'package:flutter/material.dart';
import 'package:frontend/router/router.dart';
import 'package:frontend/states/comment/comment.state.dart';
import 'package:frontend/states/post/post.state.dart';
import 'package:frontend/states/user/user.state.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserState.instance),
        ChangeNotifierProvider(create: (_) => PostState.instance),
        ChangeNotifierProvider(create: (_) => CommentState.instance),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Social App',
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1877F2),
        ).copyWith(primary: const Color(0xFF1877F2)),
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF050505),
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Color(0x26000000),
          surfaceTintColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE4E6EB),
          thickness: 1,
        ),
        useMaterial3: true,
      ),
    );
  }
}
