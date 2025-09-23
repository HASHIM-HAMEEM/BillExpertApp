import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/invoice/invoices_screen.dart';
import '../../features/invoice/invoice_detail_screen.dart';
import '../../features/invoice/invoice_wizard_sheet.dart';
import '../../features/clients/clients_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../core/models/merchant.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final box = Hive.box<MerchantProfile>('merchant');
      final profile = box.get('profile');
      final loggingIn = state.matchedLocation == '/onboarding';
      if (profile == null && !loggingIn) return '/onboarding';
      if (profile != null && loggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppScaffold(shell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/invoices',
              name: 'invoices',
              builder: (context, state) => const InvoicesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/clients',
              name: 'clients',
              builder: (context, state) => const ClientsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),

      // Invoice Creation Flow - Full screen routes
      GoRoute(
        path: '/invoice/create',
        name: 'invoice_create',
        builder: (context, state) => const InvoiceCreationScreen(),
      ),
      GoRoute(
        path: '/invoice/items',
        name: 'invoice_items',
        builder: (context, state) => const InvoiceItemsScreen(),
      ),
      GoRoute(
        path: '/invoice/review',
        name: 'invoice_review',
        builder: (context, state) => const InvoiceReviewScreen(),
      ),
      GoRoute(
        path: '/invoice/edit/:id',
        name: 'invoice_edit',
        builder: (context, state) {
          final invoiceId = state.pathParameters['id']!;
          return InvoiceCreationScreen(existingId: invoiceId);
        },
      ),
      GoRoute(
        path: '/invoice/:id',
        name: 'invoice_detail',
        builder: (context, state) {
          final invoiceId = state.pathParameters['id']!;
          return InvoiceDetailRouteScreen(invoiceId: invoiceId);
        },
      ),
    ],
  );
});


