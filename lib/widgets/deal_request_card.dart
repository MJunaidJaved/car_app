import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deal_model.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';
import '../utils/helpers.dart';

class DealRequestCard extends StatelessWidget {
  final DealModel deal;

  const DealRequestCard({super.key, required this.deal});

  Future<void> _acceptDeal(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final wallet = userProvider.wallet;

    if (wallet == null || wallet.balance < deal.platformFee) {
      AppHelpers.showSnackBar(
        context,
        'Insufficient wallet balance. Please add funds.',
        isError: true,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${deal.customerName}'),
            const SizedBox(height: 8),
            Text('Agreed Fare: ${AppHelpers.formatCurrency(deal.agreedFare)}'),
            Text(
              'Platform Fee (10%): ${AppHelpers.formatCurrency(deal.platformFee)}',
              style: const TextStyle(color: Colors.orange),
            ),
            const Divider(height: 24),
            Text(
              'You will earn: ${AppHelpers.formatCurrency(deal.agreedFare - deal.platformFee)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'After confirmation, customer will receive your contact number.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.confirmDeal(
        deal.id,
        deal.captainId,
        deal.platformFee,
      );

      if (context.mounted) {
        AppHelpers.showSnackBar(context, 'Deal confirmed! Customer will contact you.');
      }
    } catch (e) {
      if (context.mounted) {
        AppHelpers.showSnackBar(context, 'Failed to confirm deal: $e', isError: true);
      }
    }
  }

  Future<void> _rejectDeal(BuildContext context) async {
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.updateDealStatus(deal.id, 'cancelled');

      if (context.mounted) {
        AppHelpers.showSnackBar(context, 'Request declined');
      }
    } catch (e) {
      if (context.mounted) {
        AppHelpers.showSnackBar(context, 'Failed to decline', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    deal.customerName.isNotEmpty
                        ? deal.customerName[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppHelpers.formatDateTime(deal.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (deal.customerMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.message, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deal.customerMessage!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 24),

            // Pricing Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Offer',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppHelpers.formatCurrency(deal.agreedFare),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Platform Fee (10%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppHelpers.formatCurrency(deal.platformFee),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'You will earn',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    AppHelpers.formatCurrency(deal.agreedFare - deal.platformFee),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectDeal(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptDeal(context),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
