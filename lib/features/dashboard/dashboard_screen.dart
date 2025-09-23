import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import '../../app/themes/app_theme.dart';
import '../../core/services/invoice_repository.dart';
import '../../core/services/merchant_repository.dart';
import '../../core/services/currency_service.dart';
import '../../core/services/currency_cache_service.dart';
import '../../core/models/invoice.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/widgets/enhanced_ad_widget.dart';

// Shared widgets from settings page design
class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.getCardSurfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: AppTheme.getBorderColor(context),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

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
    final currencyCacheService = ref.watch(currencyCacheServiceProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context), // iOS-style background
      body: SafeArea(
        child: StreamBuilder<List<Invoice>>(
          stream: invStream,
          builder: (context, snapshot) {
            final invoices = snapshot.data ?? const <Invoice>[];

            // Convert all amounts to the user's display currency
            final displayCurrencyAsync = ref.watch(displayCurrencyFutureProvider);
            // Fallback while loading
            final displayCurrency = displayCurrencyAsync.asData?.value ?? 'USD';

            // Use optimized batch conversion for better performance
            return FutureBuilder<Map<InvoiceStatus, double>>(
              future: currencyCacheService.getStatusSums(invoices, displayCurrency),
              builder: (context, statusSumsSnapshot) {
                final statusSums = statusSumsSnapshot.data ?? {};
                final totalInvoices = invoices.length;
                final baseCurrency = displayCurrency;

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

                      SizedBox(height: context.responsiveHeight(3)),

                      // Revenue Stats
                      _AnimatedSection(
                        delay: 100,
                        animationController: _animationController,
                        child: Padding(
                          padding: context.responsiveHorizontalPadding,
                          child: _SettingsGroup(
                            title: 'Revenue Overview',
                            children: [
                              Container(
                                padding: context.responsivePadding,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.trending_up_rounded,
                                          color: AppTheme.getTextSecondaryColor(context),
                                          size: context.responsiveIconSize(),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.getBackgroundColor(context),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'This Month',
                                            style: TextStyle(
                                              color: AppTheme.getTextSecondaryColor(context),
                                              fontSize: context.responsiveFontSize(13),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: context.responsiveHeight(3)),
                                    Text(
                                      'Total Revenue',
                                      style: TextStyle(
                                        color: AppTheme.getTextSecondaryColor(context),
                                        fontSize: context.responsiveFontSize(16),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Builder(
                                      builder: (context) {
                                        final value = statusSums[InvoiceStatus.paid] ?? 0;
                                        final text = value.formatAsCurrency(baseCurrency);
                                        return Text(
                                          text,
                                          style: TextStyle(
                                            color: AppTheme.getTextPrimaryColor(context),
                                            fontSize: context.responsiveFontSize(36),
                                            fontWeight: FontWeight.w800,
                                            height: 1.1,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.arrow_upward_rounded,
                                                color: Colors.green,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '12.5%',
                                                style: TextStyle(
                                                  color: Colors.green,
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
                                            color: AppTheme.getTextSecondaryColor(context),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: context.responsiveHeight(3)),

                      // Quick Stats
                      _AnimatedSection(
                        delay: 200,
                        animationController: _animationController,
                        child: Padding(
                          padding: context.responsiveHorizontalPadding,
                          child: _SettingsGroup(
                            title: 'Outstanding',
                            children: [
                              Container(
                                padding: context.responsivePadding,
        child: Row(
                                  children: [
                                    Expanded(
                                      child: Builder(
                                        builder: (context) {
                                          final pendingAmt = statusSums[InvoiceStatus.unpaid] ?? 0;
                                          final partialAmt = statusSums[InvoiceStatus.partiallyPaid] ?? 0;
                                          final totalPending = pendingAmt + partialAmt;
                                          return _StatCard(
                                            title: 'Pending',
                                            amount: totalPending,
                                            currency: baseCurrency,
                                            currencyService: currencyService,
                                            icon: Icons.schedule_rounded,
                                            color: InvoiceStatusColors.getColor(InvoiceStatus.unpaid),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Builder(
                                        builder: (context) {
                                          final overdueAmt = statusSums[InvoiceStatus.overdue] ?? 0;
                                          return _StatCard(
                                            title: 'Overdue',
                                            amount: overdueAmt,
                                            currency: baseCurrency,
                                            currencyService: currencyService,
                                            icon: Icons.error_outline_rounded,
                                            color: InvoiceStatusColors.getColor(InvoiceStatus.overdue),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: context.responsiveHeight(3)),

                      // Quick Actions
                      _AnimatedSection(
                        delay: 300,
                        animationController: _animationController,
                        child: Padding(
                          padding: context.responsiveHorizontalPadding,
                          child: _SettingsGroup(
                            title: 'Quick Actions',
                            children: [
                              _ActionItem(
                                icon: Icons.person_add_rounded,
                                title: 'Add Client',
                                subtitle: 'Add a new client',
                                onTap: () => context.go('/clients'),
                              ),
                              _ActionItem(
                                icon: Icons.bar_chart_rounded,
                                title: 'View Reports',
                                subtitle: 'Check your financial reports',
                                onTap: () => context.go('/invoices'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: context.responsiveHeight(3)),

                      // Recent Invoices
                      if (invoices.isNotEmpty) ...[
                        _AnimatedSection(
                          delay: 400,
                          animationController: _animationController,
                          child: Padding(
                            padding: context.responsiveHorizontalPadding,
                            child: _SettingsGroup(
                              title: 'Recent Invoices',
                              children: invoices.take(3).map((invoice) => _InvoiceItem(invoice: invoice)).toList(),
                            ),
                          ),
                        ),
                        SizedBox(height: context.responsiveHeight(12)), // Extra space for navigation
                      ] else ...[
                        _AnimatedSection(
                          delay: 400,
                          animationController: _animationController,
                          child: _EmptyState(),
                        ),
                        const EnhancedBannerAdWidget(showInEmptyState: true),
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
  /// Returns appropriate greeting based on current time
  ///
  /// Returns:
  /// - 'Good morning' for hours 0-11
  /// - 'Good afternoon' for hours 12-16
  /// - 'Good evening' for hours 17-23
  String _getGreeting() {
    final hour = DateTime.now().hour;

    // Morning: 12 AM to 11:59 AM
    if (hour >= 0 && hour < 12) {
      return 'Good morning';
    }

    // Afternoon: 12 PM to 4:59 PM
    if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    }

    // Evening: 5 PM to 11:59 PM
    return 'Good evening';
  }

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
              color: AppTheme.getCardSurfaceColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.getBorderColor(context),
              ),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name.trim().split(' ').map((e) => e[0]).take(2).join() : 'B',
                style: TextStyle(
                  color: AppTheme.getTextSecondaryColor(context),
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
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.getTextSecondaryColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final String currency;
  final CurrencyService currencyService;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.currency,
    required this.currencyService,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getBorderColor(context),
        ),
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
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getTextSecondaryColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Consumer(
            builder: (context, ref, child) {
              final displayCurrencyAsync = ref.watch(displayCurrencyFutureProvider);
              return displayCurrencyAsync.when(
                data: (displayCurrency) => FutureBuilder<String>(
                  key: ValueKey('stat-$displayCurrency'),
                  future: currencyService.convertAmount(amount, currency),
                  builder: (context, snapshot) {
                    final displayAmount = snapshot.data ?? '$currency ${amount.toStringAsFixed(0)}';
                    return Text(
                      displayAmount,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(18),
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    );
                  },
                ),
                loading: () => Text(
                  amount.formatAsCurrency(currency),
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(18),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
                error: (error, stack) => Text(
                  amount.formatAsCurrency(currency),
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(18),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
              );
            },
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
          padding: context.responsivePadding,
          child: Row(
            children: [
              Icon(
                icon,
                size: context.responsiveIconSize(),
                color: AppTheme.getTextSecondaryColor(context),
              ),
              SizedBox(width: context.responsiveWidth(4)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(17),
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(15),
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.getTextSecondaryColor(context),
                size: context.responsiveIconSize(mobile: 18, tablet: 20, desktop: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _InvoiceItem extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceItem({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/invoice/${invoice.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: context.responsivePadding,
        child: Row(
          children: [
          Container(
            width: context.responsiveIconSize(mobile: 36, tablet: 40, desktop: 44),
            height: context.responsiveIconSize(mobile: 36, tablet: 40, desktop: 44),
            decoration: BoxDecoration(
              color: _getStatusColor(invoice.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: _getStatusColor(invoice.status),
              size: context.responsiveIconSize(mobile: 18, tablet: 20, desktop: 22),
            ),
          ),
          SizedBox(width: context.responsiveWidth(3)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(17),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  invoice.client.name,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(15),
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                invoice.totalAmount.formatAsCurrency(invoice.currencyCode ?? 'USD'),
                style: TextStyle(
                  fontSize: context.responsiveFontSize(17),
                  fontWeight: FontWeight.w700,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 4),
              _StatusChip(status: invoice.status),
            ],
          ),
          ],
        ),
      ),
    );
  }

  static Color _getStatusColor(InvoiceStatus status) {
    return InvoiceStatusColors.getColor(status);
  }
}

class _StatusChip extends StatelessWidget {
  final InvoiceStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final statusColor = InvoiceStatusColors.getColor(status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = statusColor.withValues(alpha: isDark ? 0.2 : 0.1);
    final fg = statusColor;
    String label;
    switch (status) {
      case InvoiceStatus.paid:
        label = 'Paid';
      case InvoiceStatus.unpaid:
        label = 'Unpaid';
      case InvoiceStatus.partiallyPaid:
        label = 'Partial';
      case InvoiceStatus.overdue:
        label = 'Overdue';
      case InvoiceStatus.draft:
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.getCardSurfaceColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.getBorderColor(context),
              ),
            ),
            child: Image.asset(
              'assets/logo/applogo.png',
              width: 48,
              height: 48,
              color: AppTheme.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to your dashboard!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first invoice to see your business metrics here',
            style: TextStyle(
              fontSize: 17,
              color: AppTheme.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: 'Create Your First Invoice',
            onPressed: () => context.go('/invoice/create'),
            ),
          ),
        ],
      ),
    );
  }
}