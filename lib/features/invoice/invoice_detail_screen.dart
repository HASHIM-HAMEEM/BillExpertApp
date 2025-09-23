import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../app/themes/app_theme.dart';
import '../../core/models/invoice.dart';
import '../../core/models/merchant.dart';
import '../../core/services/invoice_repository.dart';
import '../../core/services/merchant_repository.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/currency_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive_utils.dart';

// Route wrapper to open details by id via GoRouter
class InvoiceDetailRouteScreen extends ConsumerWidget {
  const InvoiceDetailRouteScreen({super.key, required this.invoiceId});
  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(invoiceRepositoryProvider);
    return FutureBuilder<Invoice?>(
      future: repo.getById(invoiceId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            backgroundColor: AppTheme.getBackgroundColor(context),
            appBar: AppBar(
              title: Text(
                'Invoice',
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
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final invoice = snap.data;
        if (invoice == null) {
          return Scaffold(
            backgroundColor: AppTheme.getBackgroundColor(context),
            appBar: AppBar(
              title: Text(
                'Invoice',
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
            body: Center(
              child: Text(
                'Invoice not found',
                style: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
              ),
            ),
          );
        }
        return InvoiceDetailScreen(invoice: invoice, showBackLeading: true);
      },
    );
  }
}

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.invoice, this.showBackLeading = false});
  final Invoice invoice;
  final bool showBackLeading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchRepo = ref.watch(merchantRepositoryProvider);
    final currencyService = ref.watch(currencyServiceProvider);

    return FutureBuilder<MerchantProfile?>(
      future: merchRepo.getProfile(),
      builder: (context, snap) {
        final merchant = snap.data;

        return Scaffold(
          backgroundColor: AppTheme.getBackgroundColor(context),
          appBar: AppBar(
            title: Text(
              'Invoice ${invoice.invoiceNumber}',
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
            leading: showBackLeading
                ? IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: AppTheme.getTextPrimaryColor(context), size: 20),
                    onPressed: () {
                      // Try to pop first, if it fails (no previous route), go to dashboard
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                  )
                : null,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (merchant == null) return;
                  await _handleAction(context, ref, value, merchant);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'preview',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.getTextPrimaryColor(context).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.visibility_rounded,
                            size: 18,
                            color: AppTheme.getTextPrimaryColor(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Preview PDF',
                          style: TextStyle(
                            color: AppTheme.getTextPrimaryColor(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.getTextSecondaryColor(context).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: AppTheme.getTextSecondaryColor(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Duplicate Invoice',
                          style: TextStyle(
                            color: AppTheme.getTextPrimaryColor(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.getTextSecondaryColor(context).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: AppTheme.getCardSurfaceColor(context),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: context.responsivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and Amount Card - Modern Design
                  Container(
                    width: double.infinity,
                    padding: context.responsivePadding,
                    decoration: BoxDecoration(
                      color: AppTheme.getCardSurfaceColor(context),
                      borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                      border: Border.all(color: AppTheme.getBorderColor(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(invoice.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(invoice.status).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(invoice.status),
                                color: _getStatusColor(invoice.status),
                                size: context.responsiveIconSize(mobile: 14, tablet: 16, desktop: 18),
                              ),
                              SizedBox(width: context.responsiveWidth(1.5)),
                              Text(
                                _getStatusLabel(invoice.status),
                                style: TextStyle(
                                  color: _getStatusColor(invoice.status),
                                  fontSize: context.responsiveFontSize(14),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Amount Display with Currency Conversion
                        Consumer(
                          builder: (context, ref, child) {
                            final displayCurrencyAsync = ref.watch(displayCurrencyFutureProvider);
                            return displayCurrencyAsync.when(
                              data: (displayCurrency) => FutureBuilder<String>(
                                key: ValueKey('invoice-amount-$displayCurrency'),
                                future: currencyService.convertAmount(invoice.totalAmount, invoice.currencyCode ?? 'USD'),
                                builder: (context, snapshot) {
                                  final displayAmount = snapshot.data ?? invoice.totalAmount.formatAsCurrency(invoice.currencyCode ?? 'USD');
                                  return Text(
                                    displayAmount,
                                    style: TextStyle(
                                      color: AppTheme.getTextPrimaryColor(context),
                                      fontSize: context.responsiveFontSize(36),
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  );
                                },
                              ),
                              loading: () => Text(
                                invoice.totalAmount.formatAsCurrency(invoice.currencyCode ?? 'USD'),
                                style: TextStyle(
                                  color: AppTheme.getTextPrimaryColor(context),
                                  fontSize: context.responsiveFontSize(36),
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                              error: (error, stack) => Text(
                                invoice.totalAmount.formatAsCurrency(invoice.currencyCode ?? 'USD'),
                                style: TextStyle(
                                  color: AppTheme.getTextPrimaryColor(context),
                                  fontSize: context.responsiveFontSize(36),
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 8),
                        Text(
                          'Due ${_formatDate(invoice.dueDate)}',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.getTextSecondaryColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Invoice Details Section
                  _SettingsGroup(
                    title: 'Invoice Details',
                    children: [
                      _DetailRow(
                        label: 'Invoice Date',
                        value: _formatDate(invoice.date),
                        icon: Icons.calendar_today_rounded,
                      ),
                      Divider(height: 1, color: AppTheme.getDividerColor(context)),
                      _DetailRow(
                        label: 'Due Date',
                        value: _formatDate(invoice.dueDate),
                        icon: Icons.schedule_rounded,
                      ),
                      Divider(height: 1, color: AppTheme.getDividerColor(context)),
                      _DetailRow(
                        label: 'Client',
                        value: invoice.client.name,
                        icon: Icons.person_rounded,
                      ),
                      if (invoice.client.email != null) ...[
                        Divider(height: 1, color: AppTheme.getDividerColor(context)),
                        _DetailRow(
                          label: 'Email',
                          value: invoice.client.email!,
                          icon: Icons.email_rounded,
                        ),
                      ],
                      if (invoice.client.phone != null) ...[
                        Divider(height: 1, color: AppTheme.getDividerColor(context)),
                        _DetailRow(
                          label: 'Phone',
                          value: invoice.client.phone!,
                          icon: Icons.phone_rounded,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Items Section
                  _SettingsGroup(
                    title: 'Items (${invoice.items.length})',
                    children: invoice.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Column(
                        children: [
                          _ModernItemCard(item: item, currencyService: currencyService, invoiceCurrencyCode: invoice.currencyCode ?? 'USD'),
                          if (index < invoice.items.length - 1)
                            Divider(height: 1, color: AppTheme.getDividerColor(context)),
                        ],
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Summary Section
                  _SettingsGroup(
                    title: 'Summary',
                    children: [
                      _SummaryRow(
                        label: 'Subtotal',
                        value: invoice.subtotal.toStringAsFixed(2),
                        currencyCode: invoice.currencyCode ?? 'USD',
                        isSubtotal: true,
                      ),
                      if (invoice.discountTotal > 0) ...[
                        Divider(height: 1, color: AppTheme.getDividerColor(context)),
                        _SummaryRow(
                          label: 'Discounts',
                          value: invoice.discountTotal.toStringAsFixed(2),
                          currencyCode: invoice.currencyCode ?? 'USD',
                          isDiscount: true,
                        ),
                      ],
                      Divider(height: 1, color: AppTheme.getDividerColor(context)),
                      _SummaryRow(
                        label: 'Tax',
                        value: invoice.taxAmount.toStringAsFixed(2),
                        currencyCode: invoice.currencyCode ?? 'USD',
                        isSubtotal: true,
                      ),
                      Divider(height: 1, color: AppTheme.getDividerColor(context)),
                      Consumer(
                        builder: (context, ref, child) {
                          final displayCurrency = ref.watch(displayCurrencyProvider);
                          return FutureBuilder<String>(
                            key: ValueKey('summary-total-$displayCurrency'),
                            future: currencyService.convertAmount(invoice.totalAmount, invoice.currencyCode ?? 'USD'),
                            builder: (context, snapshot) {
                              final displayAmount = snapshot.data ?? '${invoice.currencyCode ?? 'USD'} ${invoice.totalAmount.toStringAsFixed(2)}';
                              return _SummaryRow(
                                label: 'Total',
                                value: displayAmount,
                                currencyCode: null, // Already included in converted amount
                                isTotal: true,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SettingsGroup(
                      title: 'Notes',
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.getBackgroundColor(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            invoice.notes!,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.getTextPrimaryColor(context),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: context.responsiveHeight(3)),

                  // Quick Actions
                  Container(
                    margin: context.responsiveHorizontalPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: context.responsiveWidth(1), bottom: context.responsiveHeight(2)),
                          child: Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(18),
                              fontWeight: FontWeight.w700,
                              color: AppTheme.getTextPrimaryColor(context),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: context.responsivePadding,
                          decoration: BoxDecoration(
                            color: AppTheme.getCardSurfaceColor(context),
                            borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                            border: Border.all(
                              color: AppTheme.getBorderColor(context),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.getTextPrimaryColor(context).withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Status Actions Row
                              if (![InvoiceStatus.paid, InvoiceStatus.unpaid, InvoiceStatus.partiallyPaid].contains(invoice.status))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    children: [
                                      if (invoice.status != InvoiceStatus.paid)
                                        Expanded(
                                          child: _ModernActionCard(
                                            label: 'Mark as Paid',
                                            icon: Icons.check_circle_rounded,
                                            gradient: LinearGradient(
                                              colors: [
                                                InvoiceStatusColors.getColor(InvoiceStatus.paid),
                                                InvoiceStatusColors.getColor(InvoiceStatus.paid).withValues(alpha: 0.8),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            onTap: () => _updateStatus(context, ref, InvoiceStatus.paid),
                                          ),
                                        ),
                                      if (invoice.status != InvoiceStatus.paid && invoice.status != InvoiceStatus.unpaid) SizedBox(width: context.responsiveWidth(3)),
                                      if (invoice.status != InvoiceStatus.unpaid)
                                        Expanded(
                                          child: _ModernActionCard(
                                            label: 'Mark Unpaid',
                                            icon: Icons.schedule_rounded,
                                            gradient: LinearGradient(
                                              colors: [
                                                InvoiceStatusColors.getColor(InvoiceStatus.unpaid),
                                                InvoiceStatusColors.getColor(InvoiceStatus.unpaid).withValues(alpha: 0.8),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            onTap: () => _updateStatus(context, ref, InvoiceStatus.unpaid),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                              // PDF Action
                              _ModernActionCard(
                                label: 'Preview PDF',
                                icon: Icons.picture_as_pdf_rounded,
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.getTextPrimaryColor(context),
                                    AppTheme.getTextPrimaryColor(context).withValues(alpha: 0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                onTap: () async {
                                  if (merchant != null) {
                                    await _handleAction(context, ref, 'preview', merchant);
                                  }
                                },
                              ),

                              // Partial Payment (if applicable)
                              if (invoice.status != InvoiceStatus.partiallyPaid) ...[
                                SizedBox(height: context.responsiveHeight(1.5)),
                                _ModernActionCard(
                                  label: 'Mark Partial',
                                  icon: Icons.pie_chart_rounded,
                                  gradient: LinearGradient(
                                    colors: [
                                      InvoiceStatusColors.getColor(InvoiceStatus.partiallyPaid),
                                      InvoiceStatusColors.getColor(InvoiceStatus.partiallyPaid).withValues(alpha: 0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  onTap: () => _updateStatus(context, ref, InvoiceStatus.partiallyPaid),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: context.responsiveHeight(10)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String action, MerchantProfile merchant) async {
    switch (action) {
      case 'preview':
        final file = await PdfService().generateInvoicePdf(merchant: merchant, invoice: invoice);
        if (context.mounted) _showPreview(context, file);
        break;
      case 'duplicate':
        final copy = Invoice(
          id: '${invoice.id}_copy_${DateTime.now().millisecondsSinceEpoch}',
          invoiceNumber: '${invoice.invoiceNumber}_COPY',
          date: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 30)),
          client: invoice.client,
          items: invoice.items,
          status: InvoiceStatus.draft,
          notes: invoice.notes,
          terms: invoice.terms,
          currencyCode: invoice.currencyCode,
        );
        await ref.read(invoiceRepositoryProvider).upsert(copy);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice duplicated'),
              backgroundColor: Colors.green,
            ),
          );
        }
        break;
    }
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, InvoiceStatus status) async {
    final updatedInvoice = Invoice(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      date: invoice.date,
      dueDate: invoice.dueDate,
      client: invoice.client,
      items: invoice.items,
      status: status,
      notes: invoice.notes,
      terms: invoice.terms,
      currencyCode: invoice.currencyCode,
    );
    
    await ref.read(invoiceRepositoryProvider).upsert(updatedInvoice);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${_getStatusLabel(status)}'),
          backgroundColor: _getStatusColor(status),
        ),
      );
    }
  }

  void _showPreview(BuildContext context, File file) {
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
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.getBorderColor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Invoice Preview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            
            // PDF Preview
            Expanded(
              child: PdfPreview(
                build: (format) => file.readAsBytes(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  IconData _getStatusIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Icons.check_circle_rounded;
      case InvoiceStatus.unpaid:
        return Icons.schedule_rounded;
      case InvoiceStatus.partiallyPaid:
        return Icons.pie_chart_rounded;
      case InvoiceStatus.overdue:
        return Icons.error_rounded;
      case InvoiceStatus.draft:
        return Icons.edit_document;
    }
  }

  String _getStatusLabel(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.unpaid:
        return 'Unpaid';
      case InvoiceStatus.partiallyPaid:
        return 'Partially Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.draft:
        return 'Draft';
    }
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.getTextSecondaryColor(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppTheme.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.getTextSecondaryColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernItemCard extends StatelessWidget {
  final InvoiceItem item;
  final dynamic currencyService;
  final String invoiceCurrencyCode;

  const _ModernItemCard({required this.item, required this.currencyService, required this.invoiceCurrencyCode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.description,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ItemDetailChip(
                  label: 'Qty',
                  value: item.quantity.toStringAsFixed(item.quantity == item.quantity.toInt() ? 0 : 2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ItemDetailChip(
                  label: 'Rate',
                  value: item.rate.toStringAsFixed(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ItemDetailChip(
                  label: 'Tax',
                  value: '${item.taxPercent.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Line Total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextSecondaryColor(context),
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final displayCurrencyAsync = ref.watch(displayCurrencyFutureProvider);
                  return displayCurrencyAsync.when(
                    data: (displayCurrency) => FutureBuilder<String>(
                      key: ValueKey('item-${item.description.hashCode}-$displayCurrency'),
                      future: currencyService.convertAmount(item.lineTotal, invoiceCurrencyCode),
                      builder: (context, snapshot) {
                        final displayAmount = snapshot.data ?? item.lineTotal.formatAsCurrency(invoiceCurrencyCode);
                        return Text(
                          displayAmount,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextPrimaryColor(context),
                          ),
                        );
                      },
                    ),
                    loading: () => Text(
                      item.lineTotal.formatAsCurrency(invoiceCurrencyCode),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    error: (error, stack) => Text(
                      item.lineTotal.formatAsCurrency(invoiceCurrencyCode),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemDetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _ItemDetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.getTextSecondaryColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.getTextPrimaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final String? currencyCode;
  final bool isTotal;
  final bool isSubtotal;
  final bool isDiscount;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.currencyCode,
    this.isTotal = false,
    this.isSubtotal = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 15,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: isTotal ? AppTheme.getTextPrimaryColor(context) : AppTheme.getTextSecondaryColor(context),
            ),
          ),
          Text(
            currencyCode != null && !isTotal ? CurrencyFormatter.formatCurrency(double.parse(value), currencyCode!) : value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal
                ? AppTheme.getTextPrimaryColor(context)
                : isDiscount
                  ? const Color(0xFFEF4444)
                  : AppTheme.getTextPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ModernActionCard({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveWidth(4),
          vertical: context.responsiveHeight(1.5),
        ),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: context.responsiveIconSize(mobile: 18, tablet: 20, desktop: 22),
              color: AppTheme.getCardSurfaceColor(context),
            ),
            SizedBox(width: context.responsiveWidth(2)),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.getCardSurfaceColor(context),
                  fontSize: context.responsiveFontSize(14),
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
