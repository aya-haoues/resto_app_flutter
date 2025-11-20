// lib/pages/welcome_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Official Tawa Order colors from Compte Rendu 1
const Color primaryBlue = Color(0xFF0D3B66);    // Bleu Nuit
const Color goldAccent = Color(0xFFD4AF37);     // Or Vif
const Color oliveGreen = Color(0xFF6B8E23);     // Vert Olive

const Color ivoryWhite = Color(0xFFFDFDFD);     // Blanc Ivoire

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<Offset> _buttonSlideAnimation;
  late Animation<double> _breathingAnimation;
  late Animation<Color?> _buttonColorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.02).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.elasticOut),
      ),
    );

    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _buttonColorAnimation = ColorTween(
      begin: goldAccent.withOpacity(0.6),
      end: goldAccent,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToOrderInfo() {
    HapticFeedback.lightImpact();
    _controller.animateTo(0.9, duration: const Duration(milliseconds: 150)).then((_) {
      _controller.animateTo(1.0, duration: const Duration(milliseconds: 250));
      Navigator.of(context).pushReplacementNamed('/order_info');
    });
  }

  void _navigateToLogin() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: ivoryWhite,
      appBar: AppBar(
        backgroundColor: ivoryWhite,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings, color: primaryBlue),
            onPressed: _navigateToLogin,
            tooltip: 'Accès Responsable',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _opacityAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo Tawa Order (from her)
                Transform(
                  transform: Matrix4.identity()
                    ..scale(_scaleAnimation.value * _breathingAnimation.value)
                    ..translate(0.0, -8 * (1 - _breathingAnimation.value)),
                  alignment: Alignment.center,
                  child: Container(
                    width: screenWidth * 0.95,
                    height: screenWidth * 0.95,
                    margin: EdgeInsets.only(bottom: screenHeight * 0.09),
                    child: Image.asset(
                      'assets/images/img.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.restaurant_menu,
                          size: screenWidth * 0.4,
                          color: primaryBlue.withOpacity(0.5),
                        );
                      },
                    ),
                  ),
                ),




                const SizedBox(height: 20),

                // Button styled with official gold
                SlideTransition(
                  position: _buttonSlideAnimation,
                  child: ScaleTransition(
                    scale: _buttonScaleAnimation,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              _buttonColorAnimation.value ?? goldAccent,
                              goldAccent.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: goldAccent.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _navigateToOrderInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'COMMENCER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: Colors.white,
                              ),

                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}