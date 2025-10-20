import 'dart:math';
import 'package:flutter/material.dart';
import 'package:foodfleet/components/mybutton.dart';

class SplashScreen3 extends StatelessWidget {
  final PageController pageController;
  const SplashScreen3({super.key, required this.pageController});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Responsive values
    final logoSize = width < 600 ? 40.0 : (width < 1200 ? 50.0 : 70.0);
    final titleSize = width < 600 ? 18.0 : (width < 1200 ? 22.0 : 26.0);
    final headlineSize = width < 600 ? 24.0 : (width < 1200 ? 32.0 : 40.0);
    final descSize = width < 600 ? 14.0 : (width < 1200 ? 16.0 : 18.0);
    final buttonHeight = width < 600 ? 48.0 : 56.0;

    final double floatingImageSize = width < 600 ? 40 : (width < 1200 ? 50 : 65);
    final double borderWidth = 10;
    final double containerRadius = width < 600 ? 120 : (width < 1200 ? 140 : 160);

    // Angles for positioning
    final List<double> baseAngles = [
      -pi / 2, // Top
      pi,      // Left
      0,       // Right
      pi / 2,  // Bottom
    ];

    final List<String> floatingImages = [
      'assets/favfood1.jpg',
      'assets/favfood2.jpg',
      'assets/favfood3.jpg',
      'assets/favfood4.jpg',
    ];

    final double positionRadius =
        containerRadius + (borderWidth / 2) - (floatingImageSize / 6);
    final double stackSize =
        (containerRadius + borderWidth + floatingImageSize) * 2;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width < 600 ? 16 : 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: logoSize,
                    width: logoSize,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/log1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SHLIH Kitchen',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 30),
              Expanded(
                flex: 3,
                child: Center(
                  child: SizedBox(
                    width: stackSize,
                    height: stackSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Main circular container with delivery image
                        Container(
                          height: containerRadius * 2,
                          width: containerRadius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.white,
                              width: borderWidth,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 5,
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Container(
                              margin: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/delivery2.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Floating images
                        for (int i = 0; i < baseAngles.length; i++)
                          Positioned(
                            left: (stackSize / 2) +
                                    cos(baseAngles[i]) * positionRadius -
                                floatingImageSize / 2,
                            top: (stackSize / 2) +
                                    sin(baseAngles[i]) * positionRadius -
                                floatingImageSize / 2,
                            child: Container(
                              width: floatingImageSize,
                              height: floatingImageSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  floatingImages[i],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    'Get deliveries at your door step',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: headlineSize,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'From our bustling kitchen straight to your doorstep in no time at all!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: descSize,
                      height: 1.4,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Column(
                children: [
                  SizedBox(
                    height: buttonHeight,
                    child: MyButton(
                      text: 'Get Started',
                      onPress: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(builder: (_) => const AuthGate()),
                        // );
                      },
                      color: const Color(0xFF0F2A12),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  MyButton(
                    text: 'Sign In',
                    onPress: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //       builder: (_) => const SignInorSignUp()),
                      // );
                    },
                    color: Colors.grey.shade500,
                    foregroundColor: const Color(0xFF0F2A12),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
