
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_constants.dart';

class UserBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const UserBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<UserBottomNav> createState() => _UserBottomNavState();
}

class _UserBottomNavState extends State<UserBottomNav> {
    static const List<_NavItem> _items = [
    _NavItem(icon: AppImages.userNavHome, label: 'Home'),
    _NavItem(icon: AppImages.userNavVenue, label: 'Venue'),
    _NavItem(icon: AppImages.userNavBooking, label: 'My Booking'),
    // _NavItem(icon: AppImages.userNavGames, label: 'Games'), // hidden by client request
    _NavItem(icon: AppImages.userNavProfile, label: 'Profile'),
  ];

  static const double _circleSize = 55;
  static const double _navHeight = 65;
  static const double _totalHeight = 90;

    @override
    Widget build(BuildContext context) {
    // ✅ Use screen width minus left+right margins (16+16=32)
    final screenWidth = MediaQuery.of(context).size.width;
    final navWidth = screenWidth - 32;
    final itemWidth = navWidth / _items.length;

    // ✅ Circle center = active item center, then offset by half circle
    final circleLeft = (widget.currentIndex * itemWidth) +
        (itemWidth / 2) -
        (_circleSize / 2);

        return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      height: _totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Nav bar background ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: _navHeight,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),

           /// ✨ INNER SHADOW - TOP LIGHT
            Positioned(
              bottom: 0,
                  left: 0,
                  right: 0,
                  height: _navHeight,
              child: Container(
                
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            /// ✨ INNER SHADOW - BOTTOM DARK
            Positioned(

              bottom: 0,
                  left: 0,
                  right: 0,
                  height: _navHeight,
              child: Container(
                height: _navHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            /// 💎 INNER STROKE
            Positioned(
              bottom: 0,
                  left: 0,
                  right: 0,
                  height: _navHeight,
              child: Container(
                height: _navHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                ),
              ),
            ),

          // ── Animated floating circle ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: circleLeft,
            top: 0,
            child: Container(
              width: _circleSize,
              height: _circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mediumShadeGreen,
                image: DecorationImage(
                  image: AssetImage(AppImages.activeMenuBg),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  _items[widget.currentIndex].icon,
                  width: 26,
                  height: 26,
                  colorFilter: const ColorFilter.mode(
                    AppColors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // ── Nav items row ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: _navHeight,
            child: Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final isActive = index == widget.currentIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Show icon only when not active
                        // (active icon is shown in floating circle above)
                        if (!isActive)
                          SvgPicture.asset(
                            item.icon,
                            width: 22,
                            height: 22,
                            colorFilter: ColorFilter.mode(
                              AppColors.white.withValues(alpha: 0.8),
                              BlendMode.srcIn,
                            ),
                          )
                        else
                          const SizedBox(height: 22),

                        const SizedBox(height: 4),

                        Text(
                          item.label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: isActive
                                ? AppColors.white
                                : AppColors.white.withValues(alpha: 0.8),
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
        
  }

}


class _NavItem {
  final String icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}



// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import '../theme/app_theme.dart';
// import '../theme/app_constants.dart';

// class UserBottomNav extends StatelessWidget {
//   final int currentIndex;
//   final ValueChanged<int> onTap;

//   const UserBottomNav({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//   });

//   static const List<_NavItem> _items = [
//     _NavItem(icon: AppImages.userNavHome, label: 'Home'),
//     _NavItem(icon: AppImages.userNavVenue, label: 'Venue'),
//     _NavItem(icon: AppImages.userNavBooking, label: 'My Booking'),
//     _NavItem(icon: AppImages.userNavGames, label: 'Games'),
//     _NavItem(icon: AppImages.userNavProfile, label: 'Profile'),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//   margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
//   height: 72,
//   child: Stack(
//     children: [
//       /// 🔵 BASE BACKGROUND
//       Container(
//         decoration: BoxDecoration(
//           color: AppColors.navyBlue,
//           borderRadius: BorderRadius.circular(40),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.35),
//               blurRadius: 24,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//       ),

//       /// ✨ INNER SHADOW - TOP LIGHT
//       Positioned.fill(
//         child: Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(40),
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.center,
//               colors: [
//                 Colors.white.withOpacity(0.2),
//                 Colors.transparent,
//               ],
//             ),
//           ),
//         ),
//       ),

//       /// ✨ INNER SHADOW - BOTTOM DARK
//       Positioned.fill(
//         child: Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(40),
//             gradient: LinearGradient(
//               begin: Alignment.bottomCenter,
//               end: Alignment.center,
//               colors: [
//                 Colors.black.withOpacity(0.35),
//                 Colors.transparent,
//               ],
//             ),
//           ),
//         ),
//       ),

//       /// 💎 INNER STROKE
//       Positioned.fill(
//         child: Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(40),
//             border: Border.all(
//               color: Colors.white.withOpacity(0.12),
//               width: 1,
//             ),
//           ),
//         ),
//       ),

//       /// 🔘 YOUR ORIGINAL CONTENT (UNCHANGED)
//       Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: List.generate(_items.length, (index) {
//           final item = _items[index];
//           final isActive = index == currentIndex;

//           return Expanded(
//   child: GestureDetector(
//     onTap: () => onTap(index),
//     behavior: HitTestBehavior.opaque,
//     child: SizedBox(
//       height: 90,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           /// 🔥 FLOATING ACTIVE ICON
//           if (isActive)
//             Positioned(
//               top: -10,
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   /// Base circle + glow
//                   Container(
//                     width: 58,
//                     height: 58,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: AppColors.limeGreen,
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppColors.limeGreen.withOpacity(0.6),
//                           blurRadius: 20,
//                         ),
//                       ],
//                     ),
//                   ),

//                   /// Inner shadow
//                   Container(
//                     width: 58,
//                     height: 58,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       gradient: RadialGradient(
//                         colors: [
//                           Colors.transparent,
//                           Colors.black.withOpacity(0.25),
//                         ],
//                         radius: 0.9,
//                       ),
//                     ),
//                   ),

//                   /// Icon
//                   SvgPicture.asset(
//                     item.icon,
//                     width: 26,
//                     height: 26,
//                     colorFilter: const ColorFilter.mode(
//                       AppColors.navyBlue,
//                       BlendMode.srcIn,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//           /// 🔹 ICON + LABEL
//           Positioned(
//             bottom: isActive ? 2 : 10,
//             child: Column(
//               children: [
//                 SvgPicture.asset(
//                   item.icon,
//                   width: 22,
//                   height: 22,
//                   colorFilter: ColorFilter.mode(
//                     isActive
//                         ? AppColors.white.withOpacity(0.3)
//                         : AppColors.white.withOpacity(0.6),
//                     BlendMode.srcIn,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   item.label,
//                   style: TextStyle(
//                     fontSize: 10,
//                     color: isActive
//                         ? AppColors.white
//                         : AppColors.white.withOpacity(0.6),
//                     fontWeight:
//                         isActive ? FontWeight.w500 : FontWeight.w400,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//   ),
// );
//         }),
//       ),
//     ],
//   ),
// );
//   }
// }

