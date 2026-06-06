import 'package:bookplayz/theme/app_constants.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Optional search bar rendered below the top-bar row.
/// Pass to HeroBanner via [showSearch: true].
class HeroBannerSearchBar extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
 
  const HeroBannerSearchBar({
    super.key,
    this.hint = 'Search...',
    this.controller,
    this.onChanged,
    this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Image.asset(
                AppImages.searchIcon,
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: onTap != null
                    ? Text(
                        hint,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.darkGray,
                        ),
                      )
                    : TextField(
                        controller: controller,
                        onChanged: onChanged,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.darkGray,
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppColors.darkGray,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}