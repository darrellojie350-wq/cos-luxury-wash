import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/colors.dart';
import 'theme/theme.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tracking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const CosApp());
}

class CosApp extends StatelessWidget {
  const CosApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "CO's Luxury Wash",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkLuxury,
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
    GoRoute(path: '/login', builder: (_, __) => const AuthScreen(isLogin: true)),
    GoRoute(path: '/signup', builder: (_, __) => const AuthScreen(isLogin: false)),
    ShellRoute(
      builder: (_, state, child) => _Shell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
        GoRoute(path: '/book', builder: (_, __) => const BookingScreen()),
        GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
    GoRoute(path: '/track/:id', builder: (_, s) => TrackingScreen(orderId: s.pathParameters['id']!)),
  ],
);

class _Shell extends StatefulWidget {
  const _Shell({required this.location, required this.child});
  final String location;
  final Widget child;
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index() {
    if (widget.location.startsWith('/home')) return 0;
    if (widget.location.startsWith('/orders')) return 1;
    if (widget.location.startsWith('/book')) return 2;
    if (widget.location.startsWith('/wallet')) return 3;
    if (widget.location.startsWith('/profile')) return 4;
    return 0;
  }

  static const _dest = [Icons.home_rounded, Icons.receipt_long_rounded, Icons.add_circle_rounded, Icons.account_balance_wallet_rounded, Icons.person_rounded];
  static const _label = ['Home', 'Orders', 'Book', 'Wallet', 'Profile'];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: widget.child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index(),
      onDestinationSelected: (i) => context.go(['/home', '/orders', '/book', '/wallet', '/profile'][i]),
      height: 74,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [for (var i = 0; i < 5; i++) NavigationDestination(icon: Icon(_dest[i], size: 24), label: _label[i])],
    ),
  );
}
