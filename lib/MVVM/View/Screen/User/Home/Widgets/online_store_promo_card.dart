import 'package:flutter/material.dart';

class OnlineStorePromoCard extends StatelessWidget {
  final String imageUrl;
  final String? bannerImageUrl;
  final String title;
  final String? buttonText;
  final String? buttonBackgroundColor;
  final String? buttonTextColor;
  final VoidCallback? onTap;
  final VoidCallback? onButtonTap;

  const OnlineStorePromoCard({
    Key? key,
    required this.imageUrl,
    this.bannerImageUrl,
    this.title = '',
    this.buttonText,
    this.buttonBackgroundColor,
    this.buttonTextColor,
    this.onTap,
    this.onButtonTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180, // Added explicit height to match banner bounds in feed
        margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isNetwork)
                Image.network(
                  imageUrl,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) =>
                      bannerImageUrl != null && bannerImageUrl!.isNotEmpty
                          ? Image.network(
                              bannerImageUrl!,
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallbackImage(),
                            )
                          : _buildFallbackImage(),
                )
              else
                _buildFallbackImage(),
              
              // (If the original buildPromoCard had overlay text or buttons, they go here.
              // Assuming it was mostly the image for banners based on provided snippet)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }
}
