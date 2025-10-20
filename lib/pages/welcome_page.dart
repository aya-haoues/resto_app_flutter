import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  // --- PALETTE SIMPLIFIÉE ---
  static const Color primaryBackground = Colors.white;
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color buttonGradientStart = Color(0xFFFF6B35);
  static const Color buttonGradientEnd = Color(0xFFF7931E);
  static const Color shadowColor = Color(0x0F1E293B);

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

    // Animation de fondu pour tout le contenu
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    // Animation d'échelle pour le logo - plus prononcée
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Animation de "respiration" pour le logo - plus douce
    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.02).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Animation d'échelle pour le bouton
    _buttonScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.elasticOut),
      ),
    );

    // Animation de glissement pour le bouton - plus prononcée
    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // Animation de couleur pour le bouton
    _buttonColorAnimation = ColorTween(
      begin: accentOrange.withOpacity(0.5),
      end: accentOrange,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Démarrer l'animation après un court délai pour un meilleur effet
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

    // Animation de press
    _controller.animateTo(0.9, duration: const Duration(milliseconds: 150))
        .then((_) {
      _controller.animateTo(1.0, duration: const Duration(milliseconds: 250));
      Navigator.of(context).pushReplacementNamed('/order_info');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: primaryBackground,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _opacityAnimation,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo centré avec taille augmentée
                  _buildCenteredLogo(screenWidth, screenHeight),

                  SizedBox(height: screenHeight * 0.06), // Espacement réduit

                  // Bouton avec animations
                  _buildAnimatedButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCenteredLogo(double screenWidth, double screenHeight) {
    return Transform(
      transform: Matrix4.identity()
        ..scale(_scaleAnimation.value * _breathingAnimation.value)
        ..translate(0.0, -8 * (1 - _breathingAnimation.value)),
      alignment: Alignment.center,
      child: Container(
        width: screenWidth * 0.95, // Taille augmentée (95% de la largeur)
        height: screenWidth * 0.95, // Taille augmentée
        margin: EdgeInsets.only(bottom: screenHeight * 0.02),
        child: Image.asset(
          'assets/images/img.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.restaurant_menu,
                  size: screenWidth * 0.4, // Taille d'icône augmentée
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedButton() {
    return SlideTransition(
      position: _buttonSlideAnimation,
      child: ScaleTransition(
        scale: _buttonScaleAnimation,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()
                  ..scale(_controller.status == AnimationStatus.reverse ? 0.95 : 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        _buttonColorAnimation.value ?? buttonGradientStart,
                        buttonGradientEnd,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentOrange.withOpacity(0.3 * _controller.value),
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
              );
            },
          ),
        ),
      ),
    );
  }
}