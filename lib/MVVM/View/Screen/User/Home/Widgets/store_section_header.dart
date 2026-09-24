import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StoreSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const StoreSectionHeader({
    Key? key,
    required this.title,
    this.onSeeAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF082B63), // NaattuLink Navy
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                children: [
                  Text(
                    'See All',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFF5B400), // NaattuLink Gold
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color(0xFFF5B400),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
