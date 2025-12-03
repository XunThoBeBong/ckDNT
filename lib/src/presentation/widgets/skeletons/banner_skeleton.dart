import 'package:flutter/material.dart';
import '../shimmer_widget.dart';

/// BannerSkeleton - Skeleton loading cho Banner slider
class BannerSkeleton extends StatelessWidget {
  const BannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 180,
      child: ShimmerBox(width: double.infinity, height: 180, borderRadius: 16),
    );
  }
}
