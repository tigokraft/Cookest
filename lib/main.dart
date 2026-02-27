import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'src/features/auth/presentation/auth_state.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final onLogin = state.uri.path == '/login';

      return switch (authState) {
        AuthInitial() || AuthLoading() => null,
        AuthError() => onLogin ? null : '/login',
        AuthSuccess() => onLogin ? '/' : null,
      };
    },
    refreshListenable: _AuthStateListenable(ref),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/recipes',
            builder: (context, state) => const RecipesPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => RecipeDetailPage(
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(path: '/meal-plan', builder: (context, state) => const MealPlanPage()),
          GoRoute(path: '/pantry', builder: (context, state) => const PantryPage()),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatListPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ChatPage(sessionId: -1),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => ChatPage(
                  sessionId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
        ],
      ),
    ],
  );
});

class CookestApp extends ConsumerWidget {
  const CookestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Cookest',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Makes GoRouter re-evaluate redirect when auth state changes
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) => notifyListeners());
  }
}
