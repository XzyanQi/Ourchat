import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ourchat/pages/chats_page.dart';
import 'package:ourchat/pages/profile_page.dart';
import 'package:ourchat/pages/users_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _bottomNavController;
  late AnimationController _pageIndicatorController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bottomNavAnimation;
  late Animation<double> _pageIndicatorAnimation;

  final List<Widget> _pages = [
    const ChatsPage(),
    const UsersPage(),
    const ProfilePage(),
  ];
  final List<String> _pageLabels = ["Chats", "Users", "Profile"];
  final List<IconData> _pageIcons = [
    Icons.chat_bubble_rounded,
    Icons.people_rounded,
    Icons.person_rounded,
  ];
  final List<IconData> _pageIconsOutline = [
    Icons.chat_bubble_outline_rounded,
    Icons.people_outline_rounded,
    Icons.person_outline_rounded,
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bottomNavController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pageIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _bottomNavAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bottomNavController, curve: Curves.elasticOut),
    );
    _pageIndicatorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageIndicatorController,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _scaleController.forward();
      _slideController.forward();
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _bottomNavController.forward();
    });

    _pageIndicatorController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _bottomNavController.dispose();
    _pageIndicatorController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index != _currentPage) {
      HapticFeedback.lightImpact();

      setState(() {
        _currentPage = index;
      });

      _fadeController.reset();
      _scaleController.reset();
      _slideController.reset();
      _pageIndicatorController.reset();

      _fadeController.forward();
      _scaleController.forward();
      _slideController.forward();
      _pageIndicatorController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildUI();
  }

  Widget _buildUI() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBody: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  const Color(0xFF1A1A26).withOpacity(0.8),
                  const Color(0xFF0A0A0F),
                  const Color(0xFF050508),
                ],
              ),
            ),
          ),

          AnimatedBuilder(
            animation: Listenable.merge([
              _fadeAnimation,
              _scaleAnimation,
              _slideAnimation,
            ]),
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _pages[_currentPage],
                  ),
                ),
              );
            },
          ),

          if (isTablet)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              right: 20,
              child: _buildPageIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: _buildModernBottomNavigation(isTablet),
    );
  }

  Widget _buildPageIndicator() {
    return AnimatedBuilder(
      animation: _pageIndicatorAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _pageIndicatorAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A26).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF6C5CE7)
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernBottomNavigation(bool isTablet) {
    return AnimatedBuilder(
      animation: _bottomNavAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(_bottomNavAnimation),
          child: Container(
            margin: EdgeInsets.all(isTablet ? 24 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                height: isTablet ? 80 : 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A1A26).withOpacity(0.95),
                      const Color(0xFF252540).withOpacity(0.9),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: List.generate(
                    _pages.length,
                    (index) => Expanded(child: _buildNavItem(index, isTablet)),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, bool isTablet) {
    final isSelected = _currentPage == index;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0, end: isSelected ? 1 : 0),
      builder: (context, value, child) {
        return GestureDetector(
          onTap: () => _onPageChanged(index),
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF6C5CE7).withOpacity(0.3),
                        const Color(0xFF5B4FE0).withOpacity(0.2),
                      ],
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (isSelected)
                  Center(
                    child: Container(
                      width: 60 + (value * 20),
                      height: 60 + (value * 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6C5CE7).withOpacity(0.3 * value),
                            const Color(0xFF6C5CE7).withOpacity(0.1 * value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        padding: EdgeInsets.all(isSelected ? 12 : 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFF6C5CE7).withOpacity(0.2)
                              : Colors.transparent,
                          border: isSelected
                              ? Border.all(
                                  color: const Color(
                                    0xFF6C5CE7,
                                  ).withOpacity(0.3),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: Icon(
                            isSelected
                                ? _pageIcons[index]
                                : _pageIconsOutline[index],
                            key: ValueKey(isSelected),
                            color: isSelected
                                ? const Color(0xFF6C5CE7)
                                : Colors.white.withOpacity(0.6),
                            size: isTablet ? 26 : 22,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF6C5CE7)
                              : Colors.white.withOpacity(0.6),
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                        child: Text(_pageLabels[index]),
                      ),
                    ],
                  ),
                ),

                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _onPageChanged(index),
                      splashColor: const Color(0xFF6C5CE7).withOpacity(0.1),
                      highlightColor: const Color(0xFF6C5CE7).withOpacity(0.05),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
