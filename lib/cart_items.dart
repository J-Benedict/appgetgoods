import 'package:flutter/material.dart';
import 'colors.dart';

class CartItem extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final bool isSelected;
  final Function(bool?) onSelect;
  final int quantity;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback? onTap;
  final int stock;
  final bool animate;

  const CartItem({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.isSelected,
    required this.onSelect,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onRemove,
    this.onTap,
    required this.stock,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = stock == 0;
    return AnimatedScale(
      scale: animate ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF6C45F3).withOpacity(0.10),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: isOutOfStock ? null : onSelect,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                side: BorderSide(color: AppColors.primary, width: 2),
              ),
              // Product Image
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey[200],
                        child: Icon(Icons.error, color: Colors.grey[400]),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (isOutOfStock)
                      const Text(
                        'Out of Stock',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                  ],
                ),
              ),
              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove,
                        color: isOutOfStock ? Colors.grey : AppColors.primary,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: isOutOfStock ? null : () => onQuantityChanged(quantity - 1),
                    ),
                    Container(
                      width: 28,
                      alignment: Alignment.center,
                      child: Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add,
                        color: isOutOfStock ? Colors.grey : AppColors.primary,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: isOutOfStock ? null : () => onQuantityChanged(quantity + 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}