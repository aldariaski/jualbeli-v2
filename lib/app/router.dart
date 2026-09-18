import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/cart/presentation/pages/cart_page.dart';
import '../features/orders/presentation/pages/orders_page.dart';
import '../features/product/presentation/pages/post_product_page.dart';
import '../features/navigation/presentation/pages/main_navigation_page.dart';

class AppRouter {
  AppRouter._();
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashPage()),
      GoRoute(path: login, builder: (context, state) => LoginPage()),
      GoRoute(path: register, builder: (context, state) => RegisterPage()),
      GoRoute(
        path: home,
        builder: (context, state) => const MainNavigationPage(),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
      GoRoute(path: '/orders', builder: (context, state) => const OrdersPage()),
      GoRoute(
        path: '/products/add',
        builder: (context, state) => const PostProductPage(),
      ),
    ],
  );
}
