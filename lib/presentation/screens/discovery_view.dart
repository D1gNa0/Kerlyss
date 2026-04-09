import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aether_colors.dart';
import '../common/aether_glass.dart';
import '../common/aether_source_bottom_sheet.dart';

class DiscoveryView extends ConsumerWidget {
  const DiscoveryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'DISCOVER',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 10,
                          letterSpacing: 8,
                          color: Colors.white38,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => const AetherSourceBottomSheet(),
                        );
                      },
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(27),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'SEARCH AETHER...',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white30,
                                    letterSpacing: 2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRENDING SOURCES',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                  ),
                  const SizedBox(height: 24),
                  // Mock Grid for Discovery
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return AetherGlass(
                        borderRadius: 20,
                        opacity: 0.05,
                        child: Center(
                          child: Icon(
                            Icons.explore_outlined,
                            color: Colors.white10,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
