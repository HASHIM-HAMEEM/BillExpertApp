import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import '../../core/services/invoice_repository.dart';
import '../../core/services/merchant_repository.dart';
import '../../core/services/fx_rates_repository.dart';
import '../../core/models/invoice.dart';
import '../../core/models/fx_rates.dart';
import '../invoice/invoice_wizard_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invStream = ref.watch(invoiceRepositoryProvider).watchAll();
    final fxRepo = ref.watch(fxRatesRepositoryProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // iOS-style background
      body: SafeArea(
        child: FutureBuilder<FxRates?>(
          future: fxRepo.getFxRates(),
          builder: (context, fxSnapshot) {
            final fxRates = fxSnapshot.data;
            return StreamBuilder<List<Invoice>>(
              stream: invStream,
              builder: (context, snapshot) {
                final invoices = snapshot.data ?? const <Invoice>[];

                // Convert all amounts to base currency for dashboard totals
                double convertToBase(double amount, String? currency) {
                  if (fxRates == null || currency == null || currency == fxRates.baseCurrency) {
                    return amount;
                  }
                  final rate = fxRates.rates[currency];
                  return rate != null ? amount / rate : amount;
                }

                final revenue = invoices.where((i) => i.status == InvoiceStatus.paid).fold<double>(0, (s, i) => s + convertToBase(i.totalAmount, i.currencyCode));
                final pending = invoices.where((i) => i.status == InvoiceStatus.unpaid || i.status == InvoiceStatus.partiallyPaid).fold<double>(0, (s, i) => s + convertToBase(i.totalAmount, i.currencyCode));
                final overdue = invoices.where((i) => i.status == InvoiceStatus.overdue).fold<double>(0, (s, i) => s + convertToBase(i.totalAmount, i.currencyCode));
                final totalInvoices = invoices.length;

                final baseCurrency = fxRates?.baseCurrency ?? 'USD';

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _AnimatedSection(
                        delay: 0,
                        animationController: _animationController,
                        child: _HeaderSection(),
                      ),

                      const SizedBox(height: 24),

                      // Main Stats Card
                      _AnimatedSection(
                        delay: 100,
                        animationController: _animationController,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _MainStatsCard(
                            revenue: revenue,
                            totalInvoices: totalInvoices,
                            baseCurrency: baseCurrency,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick Stats Grid
                      _AnimatedSection(
                        delay: 200,
                        animationController: _animationController,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _QuickStatsGrid(
                            pending: pending,
                            overdue: overdue,
                            baseCurrency: baseCurrency,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions
                      _AnimatedSection(
                        delay: 300,
                        animationController: _animationController,
                        child: _QuickActionsSection(),
                      ),

                      const SizedBox(height: 24),

                      // Recent Invoices
                      if (invoices.isNotEmpty) ...[
                        _AnimatedSection(
                          delay: 400,
                          animationController: _animationController,
                          child: _RecentInvoicesSection(invoices: invoices.take(3).toList()),
                        ),
                        const SizedBox(height: 100), // Extra space for navigation
                      ] else ...[
                        _AnimatedSection(
                          delay: 400,
                          animationController: _animationController,
                          child: _EmptyState(),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  final Widget child;
  final int delay;
  final AnimationController animationController;

  const _AnimatedSection({
    required this.child,
    required this.delay,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(
              delay / 1000,
              (delay + 200) / 1000,
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: this.child,
          ),
        );
      },
      child: child,
    );
  }
}

class _HeaderSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: FutureBuilder(
        future: ref.read(merchantRepositoryProvider).getProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final name = profile?.businessName ?? 'Your Business';
          final logoPath = profile?.logoPath;

          Widget avatar = Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name.trim().split(' ').map((e) => e[0]).take(2).join() : 'B',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );

          if (logoPath != null && File(logoPath).existsSync()) {
            avatar = Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: FileImage(File(logoPath)),
                  fit: BoxFit.cover,
                ),
              ),
            );
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF8E8E93),
                  size: 24,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _MainStatsCard extends StatelessWidget {
  final double revenue;
  final int totalInvoices;
  final String baseCurrency;

  const _MainStatsCard({
    required this.revenue,
    required this.totalInvoices,
    required this.baseCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'This Month',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Total Revenue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$baseCurrency ${revenue.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.greenAccent[100],
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '12.5%',
                      style: TextStyle(
                        color: Colors.greenAccent[100],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$totalInvoices ${totalInvoices == 1 ? 'Invoice' : 'Invoices'}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStatsGrid extends StatelessWidget {
  final double pending;
  final double overdue;
  final String baseCurrency;

  const _QuickStatsGrid({
    required this.pending,
    required this.overdue,
    required this.baseCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Pending',
            value: pending.toStringAsFixed(0),
            currency: baseCurrency,
            icon: Icons.schedule_rounded,
            color: const Color(0xFFF59E0B),
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Overdue',
            value: overdue.toStringAsFixed(0),
            currency: baseCurrency,
            icon: Icons.error_outline_rounded,
            color: const Color(0xFFEF4444),
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String currency;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.currency,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$currency $value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _ActionItem(
                  icon: Icons.receipt_long_rounded,
                  title: 'Create Invoice',
                  subtitle: 'Generate a new invoice',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const InvoiceWizardSheet(),
                    );
                  },
                ),
                const Divider(height: 1, indent: 60, color: Color(0xFFE5E5E7)),
                _ActionItem(
                  icon: Icons.person_add_rounded,
                  title: 'Add Client',
                  subtitle: 'Add a new client',
                  onTap: () => context.go('/clients'),
                ),
                const Divider(height: 1, indent: 60, color: Color(0xFFE5E5E7)),
                _ActionItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'View Reports',
                  subtitle: 'Check your financial reports',
                  onTap: () => context.go('/invoices'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8E8E93),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentInvoicesSection extends StatelessWidget {
  final List<Invoice> invoices;

  const _RecentInvoicesSection({required this.invoices});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Invoices',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/invoices'),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: invoices.asMap().entries.map((entry) {
                final index = entry.key;
                final invoice = entry.value;
                return Column(
                  children: [
                    _InvoiceItem(invoice: invoice),
                    if (index < invoices.length - 1)
                      const Divider(
                        height: 1,
                        indent: 60,
                        color: Color(0xFFE5E5E7),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceItem extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceItem({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(invoice.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: _getStatusColor(invoice.status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  invoice.client.name,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${invoice.currencyCode ?? 'USD'} ${invoice.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              _StatusChip(status: invoice.status),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return const Color(0xFF10B981);
      case InvoiceStatus.unpaid:
        return const Color(0xFFF59E0B);
      case InvoiceStatus.partiallyPaid:
        return const Color(0xFF6366F1);
      case InvoiceStatus.overdue:
        return const Color(0xFFEF4444);
      case InvoiceStatus.draft:
        return const Color(0xFF6B7280);
    }
  }
}

class _StatusChip extends StatelessWidget {
  final InvoiceStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case InvoiceStatus.paid:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF10B981);
        label = 'Paid';
      case InvoiceStatus.unpaid:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFF59E0B);
        label = 'Unpaid';
      case InvoiceStatus.partiallyPaid:
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF6366F1);
        label = 'Partial';
      case InvoiceStatus.overdue:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFEF4444);
        label = 'Overdue';
      case InvoiceStatus.draft:
        bg = const Color(0xFFE5E7EB);
        fg = const Color(0xFF6B7280);
        label = 'Draft';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to your dashboard!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first invoice to see your business metrics here',
            style: TextStyle(
              fontSize: 17,
              color: Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const InvoiceWizardSheet(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Create Your First Invoice',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}