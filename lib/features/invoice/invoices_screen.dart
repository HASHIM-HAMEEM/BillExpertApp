import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/themes/app_theme.dart';
import '../../core/models/invoice.dart';
import '../../core/services/invoice_repository.dart';
import '../../core/services/currency_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/widgets/enhanced_ad_widget.dart';
import 'invoice_detail_screen.dart';
import 'invoice_wizard_sheet.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(invoiceRepositoryProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context), // iOS-style background
      appBar: AppBar(
        title: Text(
          'Invoices',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Invoice>>(
        stream: repo.watchAll(),
        builder: (context, snapshot) {
          final invoices = snapshot.data ?? const <Invoice>[];
          
          if (invoices.isEmpty) {
            return _EmptyState(
              onCreateInvoice: () => _showInvoiceForm(context, ref),
            );
          }
          
          return SingleChildScrollView(
            padding: context.responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Banner
                _StatsCard(invoices: invoices, currencyService: currencyService),

                SizedBox(height: context.responsiveHeight(3)),

                // Invoices List
                _InvoicesGroup(
                  title: 'All Invoices',
                  invoices: invoices,
                  repository: repo,
                  currencyService: currencyService,
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _AnimatedCreateInvoiceFab(
        onPressed: () => _showInvoiceForm(context, ref),
      ),
    );
  }

  void _showInvoiceForm(BuildContext context, WidgetRef ref, {Invoice? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InvoiceWizardSheet(existing: existing),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateInvoice;

  const _EmptyState({required this.onCreateInvoice});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.responsiveWidth(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(context.responsiveWidth(8)),
            decoration: BoxDecoration(
              color: AppTheme.getTextSecondaryColor(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(context.responsiveBorderRadius(mobile: 20, tablet: 24, desktop: 28)),
            ),
            child: Image.asset(
              'assets/logo/applogo.png',
              width: context.responsiveIconSize(mobile: 48, tablet: 64, desktop: 80),
              height: context.responsiveIconSize(mobile: 48, tablet: 64, desktop: 80),
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          SizedBox(height: context.responsiveHeight(3)),
          Text(
            'No invoices yet',
            style: TextStyle(
              fontSize: context.responsiveFontSize(24),
              fontWeight: FontWeight.w700,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first invoice to get started',
            style: TextStyle(
              fontSize: context.responsiveFontSize(17),
              color: AppTheme.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onCreateInvoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: context.responsiveWidth(6),
                vertical: context.responsiveHeight(1.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
              ),
              elevation: 0,
            ),
            child: Text(
              'Create Your First Invoice',
              style: TextStyle(
                fontSize: context.responsiveFontSize(17),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final List<Invoice> invoices;
  final dynamic currencyService;

  const _StatsCard({required this.invoices, required this.currencyService});

  @override
  Widget build(BuildContext context) {
    final totalAmount = invoices.fold<double>(0, (sum, inv) => sum + inv.totalAmount);
    final paidCount = invoices.where((inv) => inv.status == InvoiceStatus.paid).length;
    final unpaidCount = invoices.where((inv) => inv.status == InvoiceStatus.unpaid).length;
    
    return Container(
      width: double.infinity,
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.getTextPrimaryColor(context),
            AppTheme.getTextSecondaryColor(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.getCardSurfaceColor(context),
                size: context.responsiveIconSize(mobile: 24, tablet: 28, desktop: 32),
              ),
              SizedBox(width: context.responsiveWidth(4)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final displayCurrencyAsync = ref.watch(displayCurrencyFutureProvider);
                        return displayCurrencyAsync.when(
                          data: (displayCurrency) => FutureBuilder<String>(
                            key: ValueKey('stats-total-$displayCurrency'),
                            future: currencyService.convertAmount(totalAmount, 'USD'),
                            builder: (context, snapshot) {
                              final displayAmount = snapshot.data ?? totalAmount.formatAsCurrency(displayCurrency);
                              return Text(
                                displayAmount,
                                style: TextStyle(
                                  color: AppTheme.getCardSurfaceColor(context),
                                  fontSize: context.responsiveFontSize(24),
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            },
                          ),
                          loading: () => Text(
                            totalAmount.formatAsCurrency('USD'), // Fallback to USD for loading
                            style: TextStyle(
                              color: AppTheme.getCardSurfaceColor(context),
                              fontSize: context.responsiveFontSize(24),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          error: (error, stack) => Text(
                            totalAmount.formatAsCurrency('USD'), // Fallback to USD for error
                            style: TextStyle(
                              color: AppTheme.getCardSurfaceColor(context),
                              fontSize: context.responsiveFontSize(24),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                    Text(
                      '${invoices.length} ${invoices.length == 1 ? 'Invoice' : 'Invoices'}',
                      style: TextStyle(
                        color: AppTheme.getCardSurfaceColor(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Paid',
                  value: paidCount.toString(),
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Unpaid',
                  value: unpaidCount.toString(),
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Overdue',
                  value: invoices.where((inv) => inv.status == InvoiceStatus.overdue).length.toString(),
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getCardSurfaceColor(context).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppTheme.getCardSurfaceColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.getCardSurfaceColor(context),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicesGroup extends StatelessWidget {
  final String title;
  final List<Invoice> invoices;
  final InvoiceRepository repository;
  final dynamic currencyService;

  const _InvoicesGroup({
    required this.title,
    required this.invoices,
    required this.repository,
    required this.currencyService,
  });

  List<Widget> _buildInvoiceListWithAds(BuildContext context, List<Invoice> invoices, InvoiceRepository repository, dynamic currencyService) {
    final List<Widget> widgets = [];
    const int adInterval = 3; // Show ad after every 3 invoices

    for (int i = 0; i < invoices.length; i++) {
      // Add invoice item
      widgets.add(
        _InvoiceItem(
          invoice: invoices[i],
          currencyService: currencyService,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => Container(
                height: MediaQuery.of(context).size.height * 0.9,
                decoration: BoxDecoration(
                  color: AppTheme.getCardSurfaceColor(context),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: InvoiceDetailScreen(invoice: invoices[i]),
              ),
            );
          },
          onDelete: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  'Delete Invoice',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
                content: Text(
                  'Are you sure you want to delete this invoice? This action cannot be undone.',
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      repository.delete(invoices[i].id);
                      Navigator.of(ctx).pop();
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Add divider if not the last item
      if (i < invoices.length - 1) {
        widgets.add(
          const Divider(
            height: 1,
            indent: 68,
          ),
        );
      }

      // Add native ad after every adInterval invoices (but not after the last one)
      if ((i + 1) % adInterval == 0 && i < invoices.length - 1) {
        widgets.add(const AdSeparator());
        widgets.add(const EnhancedNativeAdWidget());
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: context.responsiveWidth(4), bottom: context.responsiveHeight(1)),
          child: Text(
            title,
            style: TextStyle(
              fontSize: context.responsiveFontSize(22),
              fontWeight: FontWeight.w700,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.getCardSurfaceColor(context),
            borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
          ),
          child: Column(
            children: _buildInvoiceListWithAds(context, invoices, repository, currencyService),
          ),
        ),
      ],
    );
  }

}

class _InvoiceItem extends StatelessWidget {
  final Invoice invoice;
  final CurrencyService currencyService;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _InvoiceItem({
    required this.invoice,
    required this.currencyService,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
        child: Padding(
          padding: context.responsivePadding,
          child: Row(
            children: [
              // Invoice icon
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
              
              // Invoice info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            invoice.invoiceNumber,
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(17),
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextPrimaryColor(context),
                            ),
                          ),
                        ),
                        _StatusChip(status: invoice.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      invoice.client.name,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(15),
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Consumer(
                      builder: (context, ref, child) {
                        final displayCurrencyAsync = ref.watch(displayCurrencyFutureProvider);
                        return displayCurrencyAsync.when(
                          data: (displayCurrency) => FutureBuilder<String>(
                            key: ValueKey('invoice-${invoice.id}-$displayCurrency'),
                            future: currencyService.convertAmount(invoice.totalAmount, invoice.currencyCode ?? 'USD'),
                            builder: (context, snapshot) {
                              final displayAmount = snapshot.data ?? invoice.totalAmount.formatAsCurrency(invoice.currencyCode ?? 'USD');
                              return Text(
                                displayAmount,
                                style: TextStyle(
                                  fontSize: context.responsiveFontSize(15),
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.getTextPrimaryColor(context),
                                ),
                              );
                            },
                          ),
                          loading: () => Text(
                            invoice.totalAmount.formatAsCurrency(invoice.currencyCode ?? 'USD'),
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(15),
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextPrimaryColor(context),
                            ),
                          ),
                          error: (error, stack) => Text(
                            invoice.totalAmount.formatAsCurrency(invoice.currencyCode ?? 'USD'),
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(15),
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextPrimaryColor(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // More button
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    onTap();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_rounded, size: 20, color: AppTheme.getTextSecondaryColor(context)),
                        SizedBox(width: 12),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever_rounded, size: 20, color: const Color(0xFFEF4444)),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: const Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
                icon: Icon(
                  Icons.more_horiz,
                  color: AppTheme.getTextSecondaryColor(context),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _getStatusColor(InvoiceStatus status) {
    return InvoiceStatusColors.getColor(status);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final InvoiceStatus status;

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

class _AnimatedCreateInvoiceFab extends StatefulWidget {
  const _AnimatedCreateInvoiceFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_AnimatedCreateInvoiceFab> createState() => _AnimatedCreateInvoiceFabState();
}

class _AnimatedCreateInvoiceFabState extends State<_AnimatedCreateInvoiceFab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _elevation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _elevation = Tween<double>(begin: 2, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: FloatingActionButton(
            onPressed: widget.onPressed,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: _elevation.value,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}