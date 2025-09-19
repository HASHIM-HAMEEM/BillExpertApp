import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/models/invoice.dart';
import '../../core/models/merchant.dart';
import '../../core/services/invoice_repository.dart';
import '../../core/services/merchant_repository.dart';
import '../../core/services/pdf_service.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.invoice});
  final Invoice invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchRepo = ref.watch(merchantRepositoryProvider);
    
    return FutureBuilder<MerchantProfile?>(
      future: merchRepo.getProfile(),
      builder: (context, snap) {
        final merchant = snap.data;
        
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E5E7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Title and actions
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invoice ${invoice.invoiceNumber}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  invoice.client.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (merchant == null) return;
                                await _handleAction(context, ref, value, merchant);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'preview',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility_rounded, size: 20),
                                      SizedBox(width: 12),
                                      Text('Preview PDF'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'duplicate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.copy_rounded, size: 20),
                                      SizedBox(width: 12),
                                      Text('Duplicate'),
                                    ],
                                  ),
                                ),
                              ],
                              icon: const Icon(
                                Icons.more_horiz,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status and Amount Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getStatusColor(invoice.status),
                                _getStatusColor(invoice.status).withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getStatusIcon(invoice.status),
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _getStatusLabel(invoice.status),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${invoice.currencyCode ?? 'USD'} ${invoice.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Invoice Details Section
                        _DetailSection(
                          title: 'Invoice Details',
                          children: [
                            _DetailRow(
                              label: 'Invoice Date',
                              value: _formatDate(invoice.date),
                              icon: Icons.calendar_today_rounded,
                            ),
                            _DetailRow(
                              label: 'Due Date',
                              value: _formatDate(invoice.dueDate),
                              icon: Icons.schedule_rounded,
                            ),
                            _DetailRow(
                              label: 'Client',
                              value: invoice.client.name,
                              icon: Icons.person_rounded,
                            ),
                            if (invoice.client.email != null)
                              _DetailRow(
                                label: 'Email',
                                value: invoice.client.email!,
                                icon: Icons.email_rounded,
                              ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Items Section
                        _DetailSection(
                          title: 'Items',
                          children: invoice.items.map((item) => _ItemCard(item: item)).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Totals Section
                        _DetailSection(
                          title: 'Summary',
                          children: [
                            _TotalRow(
                              label: 'Subtotal',
                              value: invoice.subtotal.toStringAsFixed(2),
                              isSubtotal: true,
                            ),
                            if (invoice.discountTotal > 0)
                              _TotalRow(
                                label: 'Discounts',
                                value: '-${invoice.discountTotal.toStringAsFixed(2)}',
                                isDiscount: true,
                              ),
                            _TotalRow(
                              label: 'Tax',
                              value: invoice.taxAmount.toStringAsFixed(2),
                              isSubtotal: true,
                            ),
                            _TotalRow(
                              label: 'Total',
                              value: '${invoice.currencyCode ?? 'USD'} ${invoice.totalAmount.toStringAsFixed(2)}',
                              isTotal: true,
                            ),
                          ],
                        ),

                        if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _DetailSection(
                            title: 'Notes',
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  invoice.notes!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF8E8E93),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Action Buttons
                        _ActionButtons(
                          invoice: invoice,
                          onStatusUpdate: (status) => _updateStatus(context, ref, status),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
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
        decoration: const BoxDecoration(
          color: Colors.white,
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
                      color: const Color(0xFFE5E5E7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Invoice Preview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
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

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFE5E5E7),
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
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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

class _ItemCard extends StatelessWidget {
  final InvoiceItem item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Qty: ${item.quantity.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8E8E93),
                ),
              ),
              Text(
                'Rate: ${item.rate.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8E8E93),
                ),
              ),
              Text(
                'Tax: ${item.taxPercent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Line Total:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                item.lineTotal.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final bool isSubtotal;
  final bool isDiscount;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isSubtotal = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 17,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? Colors.black : const Color(0xFF8E8E93),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 17,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal 
                ? const Color(0xFF6366F1)
                : isDiscount 
                  ? Colors.red 
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Invoice invoice;
  final Function(InvoiceStatus) onStatusUpdate;

  const _ActionButtons({
    required this.invoice,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (invoice.status != InvoiceStatus.paid)
              _ActionButton(
                label: 'Mark as Paid',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
                onTap: () => onStatusUpdate(InvoiceStatus.paid),
              ),
            if (invoice.status != InvoiceStatus.unpaid)
              _ActionButton(
                label: 'Mark as Unpaid',
                icon: Icons.schedule_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () => onStatusUpdate(InvoiceStatus.unpaid),
              ),
            if (invoice.status != InvoiceStatus.partiallyPaid)
              _ActionButton(
                label: 'Partially Paid',
                icon: Icons.pie_chart_rounded,
                color: const Color(0xFF6366F1),
                onTap: () => onStatusUpdate(InvoiceStatus.partiallyPaid),
              ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }
}
