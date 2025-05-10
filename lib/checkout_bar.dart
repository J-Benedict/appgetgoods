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
      height: 63,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.borderGrey,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: isAllSelected,
                  onChanged: onSelectAll,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  side: const BorderSide(
                    color: AppColors.lightGrey,
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select All',
                style: TextStyle(
                  color: AppColors.grey,
                  fontFamily: 'Roboto',
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontFamily: 'Roboto',
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  total,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCheckout,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 26,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Text(
              'Check Out ($itemCount)',
              style: const TextStyle(
                color: AppColors.white,
                fontFamily: 'Roboto',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}