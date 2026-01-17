import 'package:flutter/material.dart';

class SingleBannerHome extends StatelessWidget {
  final String imageAsset;

  final String? bottomLeftAsset;
  final String? bottomRightAsset;

  final double bottomAspectRatio;

  const SingleBannerHome({
    super.key,
    required this.imageAsset,
    this.bottomLeftAsset,
    this.bottomRightAsset,
    this.bottomAspectRatio = 1,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final topHeight = w * 0.42;

    final hasBottomBanners =
        bottomLeftAsset != null && bottomRightAsset != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: topHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      image: DecorationImage(
                        image: AssetImage(imageAsset),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (hasBottomBanners) ...[
            const SizedBox(height: 10),

            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 12.0;
                final itemWidth = (constraints.maxWidth - gap) / 2;
                final itemHeight = itemWidth / bottomAspectRatio;

                return SizedBox(
                  height: itemHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _SmallBannerTile(imageAsset: bottomLeftAsset!),
                      ),
                      const SizedBox(width: gap),
                      Expanded(
                        child: _SmallBannerTile(imageAsset: bottomRightAsset!),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallBannerTile extends StatelessWidget {
  final String imageAsset;

  const _SmallBannerTile({required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.pink[50],
              image: DecorationImage(
                image: AssetImage(imageAsset),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
