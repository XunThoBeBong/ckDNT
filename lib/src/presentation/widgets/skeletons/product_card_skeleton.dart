import 'package:flutter/material.dart';
import '../shimmer_widget.dart';
import '../../config/themes/app_colors.dart';

/// ProductCardSkeleton - Skeleton loading cho ProductCard
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          Expanded(
            child: ShimmerBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 16,
            ),
          ),

          // Content skeleton
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                ShimmerBox(width: double.infinity, height: 16, borderRadius: 4),
                const SizedBox(height: 8),
                ShimmerBox(width: 120, height: 16, borderRadius: 4),
                const SizedBox(height: 12),

                // Price skeleton
                ShimmerBox(width: 100, height: 20, borderRadius: 4),
                const SizedBox(height: 8),

                // Rating skeleton
                Row(
                  children: [
                    ShimmerBox(width: 60, height: 12, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
