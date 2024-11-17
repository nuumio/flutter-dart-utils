// Copyright (c) 2024 Jari Hämäläinen
// SPDX-License-Identifier: MIT

import 'dart:io';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_flutter_notes/src/providers/display_settings_provider.dart';
import 'package:my_flutter_notes/src/tabs/multi_touch_tab.dart';
import 'package:my_flutter_notes/src/tabs/settings_tab.dart';
import 'package:my_flutter_notes/src/tabs/widgets_tab.dart';
import 'package:my_flutter_notes/src/widgets/app_settings.dart';
import 'package:my_flutter_notes/src/widgets/preferred_size_tab_bar.dart';
import 'package:my_flutter_notes/src/widgets/tab_drag_brake.dart';
import 'package:my_flutter_notes/src/widgets/theme_mode_selector.dart';

const seedColor = Color.fromARGB(255, 255, 16, 240);

void main() {
  runApp(const ProviderScope(child: MyFlutterNotes()));
}

class MyFlutterNotes extends ConsumerStatefulWidget {
  const MyFlutterNotes({super.key});

  @override
  ConsumerState<MyFlutterNotes> createState() => _MyFlutterNotesState();
}

class _MyFlutterNotesState extends ConsumerState<MyFlutterNotes> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();

    _listener = AppLifecycleListener(
      // Lifecycle / state listeners are NOT called on Linux exit.
      onShow: () => _handleTransition('show'),
      onResume: () => _handleTransition('resume'),
      onHide: () => _handleTransition('hide'),
      onInactive: () => _handleTransition('inactive'),
      onPause: () => _handleTransition('pause'),
      onDetach: () => _handleTransition('detach'),
      onRestart: () => _handleTransition('restart'),
      // This fires for each state change. Callbacks above fire only for
      // specific state transitions.
      onStateChange: (state) => debugPrint('App state: $state'),
      // This doesn't get called on Android. It's called on Linux.
      onExitRequested: () async {
        _handleTransition('exit requested');
        return ui.AppExitResponse.exit;
      },
    );
  }

  _handleTransition(String state) {
    debugPrint('App transition: $state');
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displaySettings = ref.watch(displaySettingsProvider);

    final theme = Theme.of(context);

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primary: const ui.Color.fromARGB(255, 163, 21, 121),
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      primary: seedColor,
      inversePrimary: const Color.fromARGB(255, 64 + 10, 4, 60 - 5),
      surface: const Color.fromARGB(255, 10, 1, 6),
      error: const Color.fromARGB(255, 201, 0, 0),
      // Hovered error border, error text and text content use
      // onErrorContainer color
      onErrorContainer: const Color.fromARGB(255, 230, 42, 42),
    );

    final textTheme = theme.textTheme;
    final textThemeLight = textTheme.apply(
      bodyColor: lightColorScheme.onSurface,
      displayColor: lightColorScheme.onSurface,
    );
    final textThemeDark = textTheme.apply(
      bodyColor: darkColorScheme.onSurface,
      displayColor: darkColorScheme.onSurface,
    );

    final fabTheme = theme.floatingActionButtonTheme;
    final fabThemeLight = fabTheme.copyWith(
      backgroundColor: lightColorScheme.inversePrimary,
      foregroundColor: lightColorScheme.primary,
    );
    final fabThemeDark = fabTheme.copyWith(
      backgroundColor: darkColorScheme.inversePrimary,
      foregroundColor: darkColorScheme.primary,
    );

    final ttThemeLight = theme.tooltipTheme.copyWith(
      decoration: BoxDecoration(
        // Using BorderRadius.all() instead of BorderRadius.circular()
        // because BorderRadius.circular() is not const (at least not
        // currently)
        border: Border.all(color: darkColorScheme.primaryFixed),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        color: darkColorScheme.primaryFixedDim,
      ),
      textStyle: textThemeLight.bodyMedium!
          .copyWith(color: darkColorScheme.onPrimaryFixed),
      preferBelow: false,
    );
    final ttThemeDark = theme.tooltipTheme.copyWith(
      decoration: BoxDecoration(
        // Using BorderRadius.all() instead of BorderRadius.circular()
        // because BorderRadius.circular() is not const (at least not
        // currently)
        border: Border.all(color: darkColorScheme.inversePrimary),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        color: darkColorScheme.secondaryContainer,
      ),
      textStyle: textThemeDark.bodyMedium!
          .copyWith(color: darkColorScheme.onSecondaryContainer),
      preferBelow: false,
    );

    return MaterialApp(
      title: 'My Flutter Notes',
      theme: ThemeData(
        colorScheme: lightColorScheme,
        floatingActionButtonTheme: fabThemeLight,
        textTheme: textThemeLight,
        tooltipTheme: ttThemeLight,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        floatingActionButtonTheme: fabThemeDark,
        textTheme: textThemeDark,
        tooltipTheme: ttThemeDark,
        useMaterial3: true,
      ),
      themeMode: displaySettings.themeMode,
      home: const HomePage(title: 'My Flutter Notes'),
    );
  }
}

const navs = [
  (title: 'Widgets', icon: Icon(Icons.widgets)),
  (title: 'Multi-touch', icon: Icon(Icons.touch_app)),
  (title: 'Settings', icon: Icon(Icons.settings)),
];

class HomePage extends StatefulHookConsumerWidget {
  final String title;

  const HomePage({super.key, required this.title});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final tabDragController = TabDragBrakeController();

  @override
  void dispose() {
    super.dispose();
    tabDragController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 3);
    // Separate index state for BottomNavigationBar
    final tabIndex = useState(tabController.index);

    final tabs = navs
        .map((nav) => Tab(
              icon: nav.icon,
              text: Platform.isAndroid ? nav.title : null,
              child: Platform.isLinux
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 120,
                      ),
                      child: Center(child: Text(nav.title)),
                    )
                  : null,
            ))
        .toList();

    return Scaffold(
      appBar: Platform.isAndroid
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(widget.title),
            )
          : TabBarAppBar(
              controller: tabController,
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              // 64 is M3 primary tab container height when having both icon and
              // text: https://m3.material.io/components/tabs/specs
              // 52 makes a nice "tight fit". 60 would match the height if
              // BottomNavigationBar (at least it's close to it on Linux).
              preferredSize: const Size.fromHeight(64),
              tabs: tabs,
            ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              // Adjust top padding (default = 16) because CloseButton pushes
              // things down. Also use SafeArea to avoid status bar overlap on
              // Android. It seems that 2.0 is good for Android and 8.0 for
              // Linux (title stays at *about* the same vertical position).
              padding: EdgeInsets.fromLTRB(
                16.0,
                Platform.isAndroid ? 2.0 : 8.0,
                16.0,
                8.0,
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.title),
                        const CloseButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ...navs.mapIndexed((i, nav) => ListTile(
                  leading: nav.icon,
                  title: Text(nav.title),
                  iconColor: tabIndex.value == i
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  textColor: tabIndex.value == i
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  onTap: () {
                    tabController.index = i;
                    tabIndex.value = i;
                    Navigator.pop(context);
                  },
                )),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: QuickSettings(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Exit app'),
              onTap: () {
                if (Platform.isAndroid) {
                  // This exits the app on Android. AppLifecycleListener
                  // lifecycle listeners are called.
                  SystemNavigator.pop();
                } else {
                  // This gived AppLifecycleListener.onExitRequested a chance to
                  // run on Linux. It does nothing on Android.
                  ServicesBinding.instance
                      .exitApplication(ui.AppExitType.cancelable);
                }
              },
            ),
          ],
        ),
      ),
      // TabDragBrake "hit the brakes" on tabs when user drags balls on
      // multi-touch tab.
      body: TabDragBrake(
        controller: tabDragController,
        child: Builder(builder: (context) {
          // Brake check
          final brake = TabDragBrake.of(context);
          return TabBarView(
            controller: tabController,
            physics: brake.isOn ? const NeverScrollableScrollPhysics() : null,
            children: const [
              WidgetsTab(),
              MultiTouchTab(),
              SettingsTab(),
            ],
          );
        }),
      ),
      bottomNavigationBar: Platform.isAndroid
          ? BottomNavigationBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              items: navs
                  .map(
                    (nav) => BottomNavigationBarItem(
                      icon: nav.icon,
                      label: nav.title,
                    ),
                  )
                  .toList(),
              currentIndex: tabIndex.value,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              onTap: (index) {
                tabController.index = index;
                tabIndex.value = index;
              },
            )
          : null,
    );
  }
}

class QuickSettings extends StatelessWidget {
  const QuickSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick settings',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        const IntrinsicWidth(child: AppSettings()),
        const SizedBox(height: 16),
        const ThemeModeSelector(),
      ],
    );
  }
}
