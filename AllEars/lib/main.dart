import 'package:app/screens/room.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'constants/colors.dart';
import 'helpers/greet.dart';
import 'components/text.dart';
import 'components/pet.dart';

// Screens (you need to create these)
import 'screens/todo.dart';
// Add more screens as needed

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AllEars',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'NunitoSans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF5c32a5),
          surface: AppColors.karry,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final GlobalKey<CurvedNavigationBarState> _navKey = GlobalKey();
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TodoScreen(),
    ChatRoomScreen()
    // Add more screens here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        key: _navKey,
        index: _selectedIndex,
        items: const [
          Icon(Icons.home, size: 30, color: AppColors.karry,),
          Icon(Icons.person, size: 30, color: AppColors.karry),
          Icon(Icons.person, size: 30, color: AppColors.karry),
        ],
        color: AppColors.waikawaGray,
        buttonBackgroundColor: AppColors.waikawaGray,
        backgroundColor: Colors.transparent,
        height: 60.0,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      body: _screens[_selectedIndex],
    );
  }
}

// 🏠 HOME SCREEN (kept from your original MyHomePage)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String greeting = '';
  bool _isInteractingWithPetGameView = false;

  @override
  void initState() {
    super.initState();
    greeting = GreetingHelper.getRandomGreeting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: _isInteractingWithPetGameView
            ? const NeverScrollableScrollPhysics()
            : null,
        child: Container(
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Stack(
                children: [
                  SvgPicture.asset(
                    'assets/img/homepage/bghead.svg',
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.contain,
                    semanticsLabel: 'Bghead',
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Head1(
                                  greeting,
                                  lineHeight: 1.8,
                                ).animate().flip(duration: 500.ms),
                                const SizedBox(width: 12),
                                Transform.rotate(
                                  angle: 0,
                                  child: Image.asset(
                                    'assets/img/pet/head.gif',
                                    height: 64,
                                    width: 64,
                                  ),
                                ).animate(
                                  onPlay: (controller) =>
                                      controller.repeat(reverse: true),
                                ).custom(
                                  duration: 2000.ms,
                                  builder: (context, value, child) {
                                    final angle = (value * 2 - 1) * 0.26;
                                    return Transform.rotate(
                                      angle: angle,
                                      child: child,
                                    );
                                  },
                                ),
                              ],
                            ),
                            Head2(
                              'Let’s start your day with AllEars!!',
                              textAlign: TextAlign.center,
                              weight: 400,
                            ).animate().flip(duration: 1000.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // CONTENT
              Container(
                margin: const EdgeInsets.symmetric(vertical: 32.0),
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Head2(
                          'Check your \n pet\'s condition!',
                          textAlign: TextAlign.center,
                          color: AppColors.blueRibbon,
                          weight: 600,
                        ),
                        const SizedBox(width: 12),
                        Image.asset(
                          'assets/img/pet/head.gif',
                          height: 64,
                          width: 64,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Listener(
                      onPointerDown: (_) {
                        setState(() {
                          _isInteractingWithPetGameView = true;
                        });
                      },
                      onPointerUp: (_) {
                        setState(() {
                          _isInteractingWithPetGameView = false;
                        });
                      },
                      onPointerCancel: (_) {
                        setState(() {
                          _isInteractingWithPetGameView = false;
                        });
                      },
                      child: PetGameView(),
                    ),
                    // const SizedBox(height: 32),
                    // Head2(
                    //   'Check Your Status',
                    //   textAlign: TextAlign.center,
                    //   color: AppColors.blueRibbon,
                    //   weight: 600,
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
