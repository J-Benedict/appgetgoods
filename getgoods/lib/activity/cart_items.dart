import 'package:flutter/material.dart';
import '../colors.dart';

class CartItem extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final bool isSelected;
  final Function(bool?) onSelect;
  final Function(int) onQuantityChanged;
  final int quantity;

  const CartItem({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.isSelected,
    required this.onSelect,
    required this.onQuantityChanged,
    required this.quantity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: isSelected,
                onChanged: onSelect,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                side: const BorderSide(
                  color: AppColors.lightGrey,
                  width: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.lightGrey),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
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
                    color: AppColors.grey,
                    fontFamily: 'Roboto',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  price,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 69),
              Container(
                width: 73,
                height: 21,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderGrey),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => onQuantityChanged(quantity - 1),
                      child: const Text(
                        '-',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      quantity.toString(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onQuantityChanged(quantity + 1),
                      child: const Text(
                        '+',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}