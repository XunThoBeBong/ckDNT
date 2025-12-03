import 'package:flutter/material.dart';
import '../shimmer_widget.dart';

/// CategorySkeleton - Skeleton loading cho Category item
class CategorySkeleton extends StatelessWidget {
  const CategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerBox(
            width: 70,
            height: 70,
            borderRadius: 16,
          ),
          const SizedBox(height: 8),
          ShimmerBox(
            width: 60,
            height: 12,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}

