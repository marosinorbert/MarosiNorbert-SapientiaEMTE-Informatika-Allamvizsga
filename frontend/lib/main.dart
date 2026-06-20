import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sensors_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/log_screen.dart';
import 'screens/plants_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/esp32_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/sidebar.dart';
import 'utils/responsive.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const SmartGreenhouseApp());
}

class SmartGreenhouseApp extends StatelessWidget {
  const SmartGreenhouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettingsController.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Smart Greenhouse',
          theme: AppTheme.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon:
                    const Icon(Icons.menu_rounded, color: AppTheme.textPrimary),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'GreenHouse ',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text: 'Pro',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: Sidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (i) {
                  setState(() => _selectedIndex = i);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: isMobile
          ? _getScreenContent()
          : Row(
              children: [
                Sidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (i) => setState(() => _selectedIndex = i),
                ),
                Expanded(child: _getScreenContent()),
              ],
            ),
    );
  }

  Widget _getScreenContent() {
    Widget screen;

    switch (_selectedIndex) {
      case 0:
        screen = const DashboardScreen();
        break;
      case 1:
        screen = const SensorsScreen();
        break;
      case 2:
        screen = const DevicesScreen();
        break;
      case 3:
        screen = const AlertsScreen();
        break;
      case 4:
        screen = const LogScreen();
        break;
      case 5:
        screen = const PlantsScreen();
        break;
      case 6:
        screen = const StatisticsScreen();
        break;
      case 7:
        screen = const SettingsScreen();
        break;
      default:
        screen = const Esp32Screen();
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: ResponsiveHelper.getPadding(context),
            child: screen,
          ),
        ),
      ),
    );
  }
}
