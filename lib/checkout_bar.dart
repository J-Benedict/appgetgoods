import 'package:flutter/material.dart';
import 'colors.dart';

class CheckoutBar extends StatelessWidget {
  final bool isAllSelected;
  final Function(bool?) onSelectAll;
  final String total;
  final int itemCount;
  final VoidCallback onCheckout;

  const CheckoutBar({
    super.key,
    required this.isAllSelected,
    required this.onSelectAll,
    required this.total,
    required this.itemCount,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Select All Checkbox
              Row(
                children: [
                  Checkbox(
                    value: isAllSelected,
                    onChanged: onSelectAll,
                    activeColor: AppColors.primary,
                  ),
                  const Text(
                    'Select All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Total and Checkout
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total: $total',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '$itemCount item${itemCount != 1 ? 's' : ''} selected',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6C45F3),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12), // Add space below the bar
        ],
      ),
    );
  }
}