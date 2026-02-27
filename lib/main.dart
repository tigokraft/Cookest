import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'src/features/auth/data/auth_repository.dart';
import 'src/features/auth/presentation/login_page.dart';
import 'src/features/home/presentation/home_page.dart';
import 'src/features/recipes/presentation/recipes_page.dart';
import 'src/features/recipes/presentation/recipe_detail_page.dart';
import 'src/features/meal_plan/presentation/meal_plan_page.dart';
import 'src/features/pantry/presentation/pantry_page.dart';
import 'src/features/chat/presentation/chat_list_page.dart';
import 'src/features/chat/presentation/chat_page.dart';
import 'src/features/profile/presentation/profile_page.dart';
import 'src/shared/theme/shadcn_theme.dart';
import 'src/shared/widgets/app_shell.dart';

void main() {
  runApp(const ProviderScope(child: CookestApp()));
}

class CookestApp extends ConsumerStatefulWidget {
  const CookestApp({super.key});

  @override
  ConsumerState<CookestApp> createState() => _CookestAppState();
}

class _CookestAppState extends ConsumerState<CookestApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final authState = ref.read(authNotifierProvider);
        final onLogin = state.uri.path == '/login';

        if (authState is AuthLoading || authState is AuthInitial) return null;
        if (authState is AuthUnauthenticated && !onLogin) return '/login';
        if (authState is AuthAuthenticated && onLogin) return '/';
        return null;
      },
      refreshListenable: _AuthStateListenable(ref),
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginPage(),
        ),
        ShellRoute(
          builder: (_, __, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HomePage()),
            GoRoute(
              path: '/recipes',
              builder: (_, __) => const RecipesPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => RecipeDetailPage(
                    id: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
            GoRoute(path: '/meal-plan', builder: (_, __) => const MealPlanPage()),
            GoRoute(path: '/pantry', builder: (_, __) => const PantryPage()),
            GoRoute(
              path: '/chat',
              builder: (_, __) => const ChatListPage(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (_, __) => const ChatPage(sessionId: -1),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => ChatPage(
                    sessionId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
            GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cookest',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Makes GoRouter re-evaluate redirect when auth state changes
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(ProviderRef _ref) {
    _ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}
