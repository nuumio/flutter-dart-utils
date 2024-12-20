// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copied from Flutter and made it [DropdownMenu2] because the original doesn't
// play nice when dense (see https://github.com/flutter/flutter/issues/135903).
// Applied fixes mentioned in https://github.com/flutter/flutter/issues/135903#issuecomment-2364955429
// and marked them with `// nuumio:`.
library dropdown_menu2;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// Examples can assume:
// late BuildContext context;
// late FocusNode myFocusNode;

/// A callback function that returns the list of the items that matches the
/// current applied filter.
///
/// Used by [DropdownMenu2.filterCallback].
typedef FilterCallback<T> = List<DropdownMenuEntry<T>> Function(
    List<DropdownMenuEntry<T>> entries, String filter);

/// A callback function that returns the index of the item that matches the
/// current contents of a text field.
///
/// If a match doesn't exist then null must be returned.
///
/// Used by [DropdownMenu2.searchCallback].
typedef SearchCallback<T> = int? Function(
    List<DropdownMenuEntry<T>> entries, String query);

// Navigation shortcuts to move the selected menu items up or down.
final Map<ShortcutActivator, Intent> _kMenuTraversalShortcuts =
    <ShortcutActivator, Intent>{
  LogicalKeySet(LogicalKeyboardKey.arrowUp): const _ArrowUpIntent(),
  LogicalKeySet(LogicalKeyboardKey.arrowDown): const _ArrowDownIntent(),
};

const double _kMinimumWidth = 112.0;

const double _kDefaultHorizontalPadding = 12.0;

/// A dropdown menu that can be opened from a [TextField]. The selected
/// menu item is displayed in that field.
///
/// This widget is used to help people make a choice from a menu and put the
/// selected item into the text input field. People can also filter the list based
/// on the text input or search one item in the menu list.
///
/// The menu is composed of a list of [DropdownMenuEntry]s. People can provide information,
/// such as: label, leading icon or trailing icon for each entry. The [TextField]
/// will be updated based on the selection from the menu entries. The text field
/// will stay empty if the selected entry is disabled.
///
/// The dropdown menu can be traversed by pressing the up or down key. During the
/// process, the corresponding item will be highlighted and the text field will be updated.
/// Disabled items will be skipped during traversal.
///
/// The menu can be scrollable if not all items in the list are displayed at once.
///
/// {@tool dartpad}
/// This sample shows how to display outlined [DropdownMenu2] and filled [DropdownMenu2].
///
/// ** See code in examples/api/lib/material/dropdown_menu/dropdown_menu.0.dart **
/// {@end-tool}
///
/// See also:
///
/// * [MenuAnchor], which is a widget used to mark the "anchor" for a set of submenus.
///   The [DropdownMenu2] uses a [TextField] as the "anchor".
/// * [TextField], which is a text input widget that uses an [InputDecoration].
/// * [DropdownMenuEntry], which is used to build the [MenuItemButton] in the [DropdownMenu2] list.
class DropdownMenu2<T> extends StatefulWidget {
  /// Creates a const [DropdownMenu2].
  ///
  /// The leading and trailing icons in the text field can be customized by using
  /// [leadingIcon], [trailingIcon] and [selectedTrailingIcon] properties. They are
  /// passed down to the [InputDecoration] properties, and will override values
  /// in the [InputDecoration.prefixIcon] and [InputDecoration.suffixIcon].
  ///
  /// Except leading and trailing icons, the text field can be configured by the
  /// [InputDecorationTheme] property. The menu can be configured by the [menuStyle].
  const DropdownMenu2({
    super.key,
    this.enabled = true,
    this.width,
    this.menuHeight,
    this.leadingIcon,
    this.trailingIcon,
    // nuumio:
    this.trailingIconPadding = EdgeInsets.zero,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.selectedTrailingIcon,
    this.enableFilter = false,
    this.enableSearch = true,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.inputDecorationTheme,
    this.menuStyle,
    this.controller,
    this.initialSelection,
    this.onSelected,
    this.focusNode,
    this.requestFocusOnTap,
    this.expandedInsets,
    this.filterCallback,
    this.searchCallback,
    required this.dropdownMenuEntries,
    this.inputFormatters,
  }) : assert(filterCallback == null || enableFilter);

  /// Determine if the [DropdownMenu2] is enabled.
  ///
  /// Defaults to true.
  ///
  /// {@tool dartpad}
  /// This sample demonstrates how the [enabled] and [requestFocusOnTap] properties
  /// affect the textfield's hover cursor.
  ///
  /// ** See code in examples/api/lib/material/dropdown_menu/dropdown_menu.2.dart **
  /// {@end-tool}
  final bool enabled;

  /// Determine the width of the [DropdownMenu2].
  ///
  /// If this is null, the width of the [DropdownMenu2] will be the same as the width of the widest
  /// menu item plus the width of the leading/trailing icon.
  final double? width;

  /// Determine the height of the menu.
  ///
  /// If this is null, the menu will display as many items as possible on the screen.
  final double? menuHeight;

  /// An optional Icon at the front of the text input field.
  ///
  /// Defaults to null. If this is not null, the menu items will have extra paddings to be aligned
  /// with the text in the text field.
  final Widget? leadingIcon;

  /// An optional icon at the end of the text field.
  ///
  /// Defaults to an [Icon] with [Icons.arrow_drop_down].
  final Widget? trailingIcon;

  // nuumio:
  /// Padding for the trailing icon.
  ///
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry trailingIconPadding;

  /// Optional widget that describes the input field.
  ///
  /// When the input field is empty and unfocused, the label is displayed on
  /// top of the input field (i.e., at the same location on the screen where
  /// text may be entered in the input field). When the input field receives
  /// focus (or if the field is non-empty), the label moves above, either
  /// vertically adjacent to, or to the center of the input field.
  ///
  /// Defaults to null.
  final Widget? label;

  /// Text that suggests what sort of input the field accepts.
  ///
  /// Defaults to null;
  final String? hintText;

  /// Text that provides context about the [DropdownMenu2]'s value, such
  /// as how the value will be used.
  ///
  /// If non-null, the text is displayed below the input field, in
  /// the same location as [errorText]. If a non-null [errorText] value is
  /// specified then the helper text is not shown.
  ///
  /// Defaults to null;
  ///
  /// See also:
  ///
  /// * [InputDecoration.helperText], which is the text that provides context about the [InputDecorator.child]'s value.
  final String? helperText;

  /// Text that appears below the input field and the border to show the error message.
  ///
  /// If non-null, the border's color animates to red and the [helperText] is not shown.
  ///
  /// Defaults to null;
  ///
  /// See also:
  ///
  /// * [InputDecoration.errorText], which is the text that appears below the [InputDecorator.child] and the border.
  final String? errorText;

  /// An optional icon at the end of the text field to indicate that the text
  /// field is pressed.
  ///
  /// Defaults to an [Icon] with [Icons.arrow_drop_up].
  final Widget? selectedTrailingIcon;

  /// Determine if the menu list can be filtered by the text input.
  ///
  /// Defaults to false.
  final bool enableFilter;

  /// Determine if the first item that matches the text input can be highlighted.
  ///
  /// Defaults to true as the search function could be commonly used.
  final bool enableSearch;

  /// The text style for the [TextField] of the [DropdownMenu2];
  ///
  /// Defaults to the overall theme's [TextTheme.bodyLarge]
  /// if the dropdown menu theme's value is null.
  final TextStyle? textStyle;

  /// The text align for the [TextField] of the [DropdownMenu2].
  ///
  /// Defaults to [TextAlign.start].
  final TextAlign textAlign;

  /// Defines the default appearance of [InputDecoration] to show around the text field.
  ///
  /// By default, shows a outlined text field.
  final InputDecorationTheme? inputDecorationTheme;

  /// The [MenuStyle] that defines the visual attributes of the menu.
  ///
  /// The default width of the menu is set to the width of the text field.
  final MenuStyle? menuStyle;

  /// Controls the text being edited or selected in the menu.
  ///
  /// If null, this widget will create its own [TextEditingController].
  final TextEditingController? controller;

  /// The value used to for an initial selection.
  ///
  /// Defaults to null.
  final T? initialSelection;

  /// The callback is called when a selection is made.
  ///
  /// Defaults to null. If null, only the text field is updated.
  final ValueChanged<T?>? onSelected;

  /// Defines the keyboard focus for this widget.
  ///
  /// The [focusNode] is a long-lived object that's typically managed by a
  /// [StatefulWidget] parent. See [FocusNode] for more information.
  ///
  /// To give the keyboard focus to this widget, provide a [focusNode] and then
  /// use the current [FocusScope] to request the focus:
  ///
  /// ```dart
  /// FocusScope.of(context).requestFocus(myFocusNode);
  /// ```
  ///
  /// This happens automatically when the widget is tapped.
  ///
  /// To be notified when the widget gains or loses the focus, add a listener
  /// to the [focusNode]:
  ///
  /// ```dart
  /// myFocusNode.addListener(() { print(myFocusNode.hasFocus); });
  /// ```
  ///
  /// If null, this widget will create its own [FocusNode].
  ///
  /// ## Keyboard
  ///
  /// Requesting the focus will typically cause the keyboard to be shown
  /// if it's not showing already.
  ///
  /// On Android, the user can hide the keyboard - without changing the focus -
  /// with the system back button. They can restore the keyboard's visibility
  /// by tapping on a text field. The user might hide the keyboard and
  /// switch to a physical keyboard, or they might just need to get it
  /// out of the way for a moment, to expose something it's
  /// obscuring. In this case requesting the focus again will not
  /// cause the focus to change, and will not make the keyboard visible.
  ///
  /// If this is non-null, the behaviour of [requestFocusOnTap] is overridden
  /// by the [FocusNode.canRequestFocus] property.
  final FocusNode? focusNode;

  /// Determine if the dropdown button requests focus and the on-screen virtual
  /// keyboard is shown in response to a touch event.
  ///
  /// Ignored if a [focusNode] is explicitly provided (in which case,
  /// [FocusNode.canRequestFocus] controls the behavior).
  ///
  /// Defaults to null, which enables platform-specific behavior:
  ///
  ///  * On mobile platforms, acts as if set to false; tapping on the text
  ///    field and opening the menu will not cause a focus request and the
  ///    virtual keyboard will not appear.
  ///
  ///  * On desktop platforms, acts as if set to true; the dropdown takes the
  ///    focus when activated.
  ///
  /// Set this to true or false explicitly to override the default behavior.
  ///
  /// {@tool dartpad}
  /// This sample demonstrates how the [enabled] and [requestFocusOnTap] properties
  /// affect the textfield's hover cursor.
  ///
  /// ** See code in examples/api/lib/material/dropdown_menu/dropdown_menu.2.dart **
  /// {@end-tool}
  final bool? requestFocusOnTap;

  /// Descriptions of the menu items in the [DropdownMenu2].
  ///
  /// This is a required parameter. It is recommended that at least one [DropdownMenuEntry]
  /// is provided. If this is an empty list, the menu will be empty and only
  /// contain space for padding.
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;

  /// Defines the menu text field's width to be equal to its parent's width
  /// plus the horizontal width of the specified insets.
  ///
  /// If this property is null, the width of the text field will be determined
  /// by the width of menu items or [DropdownMenu2.width]. If this property is not null,
  /// the text field's width will match the parent's width plus the specified insets.
  /// If the value of this property is [EdgeInsets.zero], the width of the text field will be the same
  /// as its parent's width.
  ///
  /// The [expandedInsets]' top and bottom are ignored, only its left and right
  /// properties are used.
  ///
  /// Defaults to null.
  final EdgeInsets? expandedInsets;

  /// When [DropdownMenu2.enableFilter] is true, this callback is used to
  /// compute the list of filtered items.
  ///
  /// {@tool snippet}
  ///
  /// In this example the `filterCallback` returns the items that contains the
  /// trimmed query.
  ///
  /// ```dart
  /// DropdownMenu2<Text>(
  ///   enableFilter: true,
  ///   filterCallback: (List<DropdownMenuEntry<Text>> entries, String filter) {
  ///     final String trimmedFilter = filter.trim().toLowerCase();
  ///       if (trimmedFilter.isEmpty) {
  ///         return entries;
  ///       }
  ///
  ///       return entries
  ///         .where((DropdownMenuEntry<Text> entry) =>
  ///           entry.label.toLowerCase().contains(trimmedFilter),
  ///         )
  ///         .toList();
  ///   },
  ///   dropdownMenuEntries: const <DropdownMenuEntry<Text>>[],
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// Defaults to null. If this parameter is null and the
  /// [DropdownMenu2.enableFilter] property is set to true, the default behavior
  /// will return a filtered list. The filtered list will contain items
  /// that match the text provided by the input field, with a case-insensitive
  /// comparison. When this is not null, `enableFilter` must be set to true.
  final FilterCallback<T>? filterCallback;

  /// When [DropdownMenu2.enableSearch] is true, this callback is used to compute
  /// the index of the search result to be highlighted.
  ///
  /// {@tool snippet}
  ///
  /// In this example the `searchCallback` returns the index of the search result
  /// that exactly matches the query.
  ///
  /// ```dart
  /// DropdownMenu2<Text>(
  ///   searchCallback: (List<DropdownMenuEntry<Text>> entries, String query) {
  ///     if (query.isEmpty) {
  ///       return null;
  ///     }
  ///     final int index = entries.indexWhere((DropdownMenuEntry<Text> entry) => entry.label == query);
  ///
  ///     return index != -1 ? index : null;
  ///   },
  ///   dropdownMenuEntries: const <DropdownMenuEntry<Text>>[],
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// Defaults to null. If this is null and [DropdownMenu2.enableSearch] is true,
  /// the default function will return the index of the first matching result
  /// which contains the contents of the text input field.
  final SearchCallback<T>? searchCallback;

  /// Optional input validation and formatting overrides.
  ///
  /// Formatters are run in the provided order when the user changes the text
  /// this widget contains. When this parameter changes, the new formatters will
  /// not be applied until the next time the user inserts or deletes text.
  /// Formatters don't run when the text is changed
  /// programmatically via [controller].
  ///
  /// See also:
  ///
  ///  * [TextEditingController], which implements the [Listenable] interface
  ///    and notifies its listeners on [TextEditingValue] changes.
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<DropdownMenu2<T>> createState() => _DropdownMenuState<T>();
}

class _DropdownMenuState<T> extends State<DropdownMenu2<T>> {
  final GlobalKey _anchorKey = GlobalKey();
  final GlobalKey _leadingKey = GlobalKey();
  late List<GlobalKey> buttonItemKeys;
  final MenuController _controller = MenuController();
  late bool _enableFilter;
  late List<DropdownMenuEntry<T>> filteredEntries;
  List<Widget>? _initialMenu;
  int? currentHighlight;
  double? leadingPadding;
  bool _menuHasEnabledItem = false;
  TextEditingController? _localTextEditingController;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _localTextEditingController = widget.controller;
    } else {
      _localTextEditingController = TextEditingController();
    }
    _enableFilter = widget.enableFilter;
    filteredEntries = widget.dropdownMenuEntries;
    buttonItemKeys = List<GlobalKey>.generate(
        filteredEntries.length, (int index) => GlobalKey());
    _menuHasEnabledItem =
        filteredEntries.any((DropdownMenuEntry<T> entry) => entry.enabled);

    final int index = filteredEntries.indexWhere(
        (DropdownMenuEntry<T> entry) => entry.value == widget.initialSelection);
    if (index != -1) {
      _localTextEditingController?.value = TextEditingValue(
        text: filteredEntries[index].label,
        selection: TextSelection.collapsed(
            offset: filteredEntries[index].label.length),
      );
    }
    refreshLeadingPadding();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _localTextEditingController?.dispose();
      _localTextEditingController = null;
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(DropdownMenu2<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (widget.controller != null) {
        _localTextEditingController?.dispose();
      }
      _localTextEditingController =
          widget.controller ?? TextEditingController();
    }
    if (oldWidget.enableSearch != widget.enableSearch) {
      if (!widget.enableSearch) {
        currentHighlight = null;
      }
    }
    if (oldWidget.dropdownMenuEntries != widget.dropdownMenuEntries) {
      currentHighlight = null;
      filteredEntries = widget.dropdownMenuEntries;
      buttonItemKeys = List<GlobalKey>.generate(
          filteredEntries.length, (int index) => GlobalKey());
      _menuHasEnabledItem =
          filteredEntries.any((DropdownMenuEntry<T> entry) => entry.enabled);
    }
    if (oldWidget.leadingIcon != widget.leadingIcon) {
      refreshLeadingPadding();
    }
    if (oldWidget.initialSelection != widget.initialSelection) {
      final int index = filteredEntries.indexWhere(
          (DropdownMenuEntry<T> entry) =>
              entry.value == widget.initialSelection);
      if (index != -1) {
        _localTextEditingController?.value = TextEditingValue(
          text: filteredEntries[index].label,
          selection: TextSelection.collapsed(
              offset: filteredEntries[index].label.length),
        );
      }
    }
  }

  bool canRequestFocus() {
    return widget.focusNode?.canRequestFocus ??
        widget.requestFocusOnTap ??
        switch (Theme.of(context).platform) {
          TargetPlatform.iOS ||
          TargetPlatform.android ||
          TargetPlatform.fuchsia =>
            false,
          TargetPlatform.macOS ||
          TargetPlatform.linux ||
          TargetPlatform.windows =>
            true,
        };
  }

  void refreshLeadingPadding() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        leadingPadding = getWidth(_leadingKey);
      });
    }, debugLabel: 'DropdownMenu2.refreshLeadingPadding');
  }

  void scrollToHighlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? highlightContext =
          buttonItemKeys[currentHighlight!].currentContext;
      if (highlightContext != null) {
        Scrollable.ensureVisible(highlightContext);
      }
    }, debugLabel: 'DropdownMenu2.scrollToHighlight');
  }

  double? getWidth(GlobalKey key) {
    final BuildContext? context = key.currentContext;
    if (context != null) {
      final RenderBox box = context.findRenderObject()! as RenderBox;
      return box.hasSize ? box.size.width : null;
    }
    return null;
  }

  List<DropdownMenuEntry<T>> filter(List<DropdownMenuEntry<T>> entries,
      TextEditingController textEditingController) {
    final String filterText = textEditingController.text.toLowerCase();
    return entries
        .where((DropdownMenuEntry<T> entry) =>
            entry.label.toLowerCase().contains(filterText))
        .toList();
  }

  int? search(List<DropdownMenuEntry<T>> entries,
      TextEditingController textEditingController) {
    final String searchText = textEditingController.value.text.toLowerCase();
    if (searchText.isEmpty) {
      return null;
    }
    if (currentHighlight != null &&
        entries[currentHighlight!].label.toLowerCase().contains(searchText)) {
      return currentHighlight;
    }
    final int index = entries.indexWhere((DropdownMenuEntry<T> entry) =>
        entry.label.toLowerCase().contains(searchText));

    return index != -1 ? index : null;
  }

  List<Widget> _buildButtons(
    List<DropdownMenuEntry<T>> filteredEntries,
    TextDirection textDirection, {
    int? focusedIndex,
    bool enableScrollToHighlight = true,
  }) {
    final List<Widget> result = <Widget>[];
    for (int i = 0; i < filteredEntries.length; i++) {
      final DropdownMenuEntry<T> entry = filteredEntries[i];

      // By default, when the text field has a leading icon but a menu entry doesn't
      // have one, the label of the entry should have extra padding to be aligned
      // with the text in the text input field. When both the text field and the
      // menu entry have leading icons, the menu entry should remove the extra
      // paddings so its leading icon will be aligned with the leading icon of
      // the text field.
      final double padding = entry.leadingIcon == null
          ? (leadingPadding ?? _kDefaultHorizontalPadding)
          : _kDefaultHorizontalPadding;
      final ButtonStyle defaultStyle = switch (textDirection) {
        TextDirection.rtl => MenuItemButton.styleFrom(
            padding: EdgeInsets.only(
                left: _kDefaultHorizontalPadding, right: padding)),
        TextDirection.ltr => MenuItemButton.styleFrom(
            padding: EdgeInsets.only(
                left: padding, right: _kDefaultHorizontalPadding)),
      };

      ButtonStyle effectiveStyle = entry.style ?? defaultStyle;
      final Color focusedBackgroundColor = effectiveStyle.foregroundColor
              ?.resolve(<MaterialState>{MaterialState.focused}) ??
          Theme.of(context).colorScheme.onSurface;

      Widget label = entry.labelWidget ?? Text(entry.label);
      if (widget.width != null) {
        final double horizontalPadding = padding + _kDefaultHorizontalPadding;
        label = ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: widget.width! - horizontalPadding),
          child: label,
        );
      }

      // Simulate the focused state because the text field should always be focused
      // during traversal. If the menu item has a custom foreground color, the "focused"
      // color will also change to foregroundColor.withOpacity(0.12).
      effectiveStyle = entry.enabled && i == focusedIndex
          ? effectiveStyle.copyWith(
              backgroundColor: MaterialStatePropertyAll<Color>(
                  focusedBackgroundColor.withOpacity(0.12)))
          : effectiveStyle;

      final Widget menuItemButton = MenuItemButton(
        key: enableScrollToHighlight ? buttonItemKeys[i] : null,
        style: effectiveStyle,
        leadingIcon: entry.leadingIcon,
        trailingIcon: entry.trailingIcon,
        onPressed: entry.enabled && widget.enabled
            ? () {
                _localTextEditingController?.value = TextEditingValue(
                  text: entry.label,
                  selection:
                      TextSelection.collapsed(offset: entry.label.length),
                );
                currentHighlight = widget.enableSearch ? i : null;
                widget.onSelected?.call(entry.value);
              }
            : null,
        requestFocusOnHover: false,
        child: label,
      );
      result.add(menuItemButton);
    }

    return result;
  }

  void handleUpKeyInvoke(_) {
    setState(() {
      if (!widget.enabled || !_menuHasEnabledItem || !_controller.isOpen) {
        return;
      }
      _enableFilter = false;
      currentHighlight ??= 0;
      currentHighlight = (currentHighlight! - 1) % filteredEntries.length;
      while (!filteredEntries[currentHighlight!].enabled) {
        currentHighlight = (currentHighlight! - 1) % filteredEntries.length;
      }
      final String currentLabel = filteredEntries[currentHighlight!].label;
      _localTextEditingController?.value = TextEditingValue(
        text: currentLabel,
        selection: TextSelection.collapsed(offset: currentLabel.length),
      );
    });
  }

  void handleDownKeyInvoke(_) {
    setState(() {
      if (!widget.enabled || !_menuHasEnabledItem || !_controller.isOpen) {
        return;
      }
      _enableFilter = false;
      currentHighlight ??= -1;
      currentHighlight = (currentHighlight! + 1) % filteredEntries.length;
      while (!filteredEntries[currentHighlight!].enabled) {
        currentHighlight = (currentHighlight! + 1) % filteredEntries.length;
      }
      final String currentLabel = filteredEntries[currentHighlight!].label;
      _localTextEditingController?.value = TextEditingValue(
        text: currentLabel,
        selection: TextSelection.collapsed(offset: currentLabel.length),
      );
    });
  }

  void handlePressed(MenuController controller) {
    if (controller.isOpen) {
      currentHighlight = null;
      controller.close();
    } else {
      // close to open
      if (_localTextEditingController!.text.isNotEmpty) {
        _enableFilter = false;
      }
      controller.open();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);
    _initialMenu ??= _buildButtons(widget.dropdownMenuEntries, textDirection,
        enableScrollToHighlight: false);
    final DropdownMenuThemeData theme = DropdownMenuTheme.of(context);
    final DropdownMenuThemeData defaults = _DropdownMenuDefaultsM3(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (_enableFilter) {
      filteredEntries = widget.filterCallback
              ?.call(filteredEntries, _localTextEditingController!.text) ??
          filter(widget.dropdownMenuEntries, _localTextEditingController!);
    }

    if (widget.enableSearch) {
      if (widget.searchCallback != null) {
        currentHighlight = widget.searchCallback!
            .call(filteredEntries, _localTextEditingController!.text);
      } else {
        currentHighlight =
            search(filteredEntries, _localTextEditingController!);
      }
      if (currentHighlight != null) {
        scrollToHighlight();
      }
    }

    final List<Widget> menu = _buildButtons(filteredEntries, textDirection,
        focusedIndex: currentHighlight);

    final TextStyle effectiveTextStyle = widget.textStyle ??
        (theme.textStyle ?? defaults.textStyle!).copyWith(
          color: !widget.enabled
              ? colorScheme.onSurface.withOpacity(0.38)
              : widget.errorText != null
                  ? colorScheme.error
                  : null,
        );

    MenuStyle? effectiveMenuStyle =
        widget.menuStyle ?? theme.menuStyle ?? defaults.menuStyle!;

    final double? anchorWidth = getWidth(_anchorKey);
    if (widget.width != null) {
      effectiveMenuStyle = effectiveMenuStyle.copyWith(
          minimumSize:
              MaterialStatePropertyAll<Size?>(Size(widget.width!, 0.0)));
    } else if (anchorWidth != null) {
      effectiveMenuStyle = effectiveMenuStyle.copyWith(
          minimumSize: MaterialStatePropertyAll<Size?>(Size(anchorWidth, 0.0)));
    }

    if (widget.menuHeight != null) {
      effectiveMenuStyle = effectiveMenuStyle.copyWith(
          maximumSize: MaterialStatePropertyAll<Size>(
              Size(double.infinity, widget.menuHeight!)));
    }
    final InputDecorationTheme effectiveInputDecorationTheme =
        widget.inputDecorationTheme ??
            theme.inputDecorationTheme ??
            defaults.inputDecorationTheme!;

    final MouseCursor? effectiveMouseCursor = switch (widget.enabled) {
      true =>
        canRequestFocus() ? SystemMouseCursors.text : SystemMouseCursors.click,
      false => null,
    };

    Widget menuAnchor = MenuAnchor(
      style: effectiveMenuStyle,
      controller: _controller,
      menuChildren: menu,
      crossAxisUnconstrained: false,
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        assert(_initialMenu != null);
        // nuumio: replace original trailingButton with one from
        //   https://github.com/flutter/flutter/issues/135903#issuecomment-2364955429
        // final Widget trailingButton = Padding(
        //   padding: const EdgeInsets.all(4.0),
        //   child: IconButton(
        //     isSelected: controller.isOpen,
        //     icon: widget.trailingIcon ?? const Icon(Icons.arrow_drop_down),
        //     selectedIcon:
        //         widget.selectedTrailingIcon ?? const Icon(Icons.arrow_drop_up),
        //     onPressed: !widget.enabled
        //         ? null
        //         : () {
        //             handlePressed(controller);
        //           },
        //   ),
        // );
        final Widget trailingButton = Padding(
          padding: widget.trailingIconPadding,
          child: controller.isOpen
              ? const Icon(Icons.arrow_drop_down)
              : const Icon(Icons.arrow_drop_up),
        );

        final Widget leadingButton = Padding(
            padding: const EdgeInsets.all(8.0),
            child: widget.leadingIcon ?? const SizedBox.shrink());

        final Widget textField = TextField(
            key: _anchorKey,
            enabled: widget.enabled,
            mouseCursor: effectiveMouseCursor,
            focusNode: widget.focusNode,
            canRequestFocus: canRequestFocus(),
            enableInteractiveSelection: canRequestFocus(),
            textAlign: widget.textAlign,
            textAlignVertical: TextAlignVertical.center,
            style: effectiveTextStyle,
            controller: _localTextEditingController,
            onEditingComplete: () {
              if (currentHighlight != null) {
                final DropdownMenuEntry<T> entry =
                    filteredEntries[currentHighlight!];
                if (entry.enabled) {
                  _localTextEditingController?.value = TextEditingValue(
                    text: entry.label,
                    selection:
                        TextSelection.collapsed(offset: entry.label.length),
                  );
                  widget.onSelected?.call(entry.value);
                }
              } else {
                widget.onSelected?.call(null);
              }
              if (!widget.enableSearch) {
                currentHighlight = null;
              }
              controller.close();
            },
            onTap: !widget.enabled
                ? null
                : () {
                    handlePressed(controller);
                  },
            onChanged: (String text) {
              controller.open();
              setState(() {
                filteredEntries = widget.dropdownMenuEntries;
                _enableFilter = widget.enableFilter;
              });
            },
            inputFormatters: widget.inputFormatters,
            decoration: InputDecoration(
              label: widget.label,
              hintText: widget.hintText,
              helperText: widget.helperText,
              errorText: widget.errorText,
              prefixIcon: widget.leadingIcon != null
                  ? SizedBox(key: _leadingKey, child: widget.leadingIcon)
                  : null,
              suffixIcon: trailingButton,
            ).applyDefaults(effectiveInputDecorationTheme));

        if (widget.expandedInsets != null) {
          // If [expandedInsets] is not null, the width of the text field should depend
          // on its parent width. So we don't need to use `_DropdownMenuBody` to
          // calculate the children's width.
          return textField;
        }

        return _DropdownMenuBody(
          width: widget.width,
          children: <Widget>[
            textField,
            ..._initialMenu!,
            trailingButton,
            leadingButton,
          ],
        );
      },
    );

    if (widget.expandedInsets case final EdgeInsets padding) {
      menuAnchor = Padding(
        padding: padding.copyWith(top: 0.0, bottom: 0.0),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: menuAnchor,
        ),
      );
    }

    return Shortcuts(
      shortcuts: _kMenuTraversalShortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _ArrowUpIntent: CallbackAction<_ArrowUpIntent>(
            onInvoke: handleUpKeyInvoke,
          ),
          _ArrowDownIntent: CallbackAction<_ArrowDownIntent>(
            onInvoke: handleDownKeyInvoke,
          ),
        },
        child: menuAnchor,
      ),
    );
  }
}

class _ArrowUpIntent extends Intent {
  const _ArrowUpIntent();
}

class _ArrowDownIntent extends Intent {
  const _ArrowDownIntent();
}

class _DropdownMenuBody extends MultiChildRenderObjectWidget {
  const _DropdownMenuBody({
    super.children,
    this.width,
  });

  final double? width;

  @override
  _RenderDropdownMenuBody createRenderObject(BuildContext context) {
    return _RenderDropdownMenuBody(
      width: width,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderDropdownMenuBody renderObject) {
    renderObject.width = width;
  }
}

class _DropdownMenuBodyParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderDropdownMenuBody extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DropdownMenuBodyParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox,
            _DropdownMenuBodyParentData> {
  _RenderDropdownMenuBody({
    double? width,
  }) : _width = width;

  double? get width => _width;
  double? _width;
  set width(double? value) {
    if (_width == value) {
      return;
    }
    _width = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DropdownMenuBodyParentData) {
      child.parentData = _DropdownMenuBodyParentData();
    }
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    double maxWidth = 0.0;
    double? maxHeight;
    RenderBox? child = firstChild;

    final double intrinsicWidth =
        width ?? getMaxIntrinsicWidth(constraints.maxHeight);
    final double widthConstraint =
        math.min(intrinsicWidth, constraints.maxWidth);
    final BoxConstraints innerConstraints = BoxConstraints(
      maxWidth: widthConstraint,
      maxHeight: getMaxIntrinsicHeight(widthConstraint),
    );
    while (child != null) {
      if (child == firstChild) {
        child.layout(innerConstraints, parentUsesSize: true);
        maxHeight ??= child.size.height;
        final _DropdownMenuBodyParentData childParentData =
            child.parentData! as _DropdownMenuBodyParentData;
        assert(child.parentData == childParentData);
        child = childParentData.nextSibling;
        continue;
      }
      child.layout(innerConstraints, parentUsesSize: true);
      final _DropdownMenuBodyParentData childParentData =
          child.parentData! as _DropdownMenuBodyParentData;
      childParentData.offset = Offset.zero;
      maxWidth = math.max(maxWidth, child.size.width);
      maxHeight ??= child.size.height;
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }

    assert(maxHeight != null);
    maxWidth = math.max(_kMinimumWidth, maxWidth);
    size = constraints.constrain(Size(width ?? maxWidth, maxHeight!));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? child = firstChild;
    if (child != null) {
      final _DropdownMenuBodyParentData childParentData =
          child.parentData! as _DropdownMenuBodyParentData;
      context.paintChild(child, offset + childParentData.offset);
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final BoxConstraints constraints = this.constraints;
    double maxWidth = 0.0;
    double? maxHeight;
    RenderBox? child = firstChild;
    final double intrinsicWidth =
        width ?? getMaxIntrinsicWidth(constraints.maxHeight);
    final double widthConstraint =
        math.min(intrinsicWidth, constraints.maxWidth);
    final BoxConstraints innerConstraints = BoxConstraints(
      maxWidth: widthConstraint,
      maxHeight: getMaxIntrinsicHeight(widthConstraint),
    );

    while (child != null) {
      if (child == firstChild) {
        final Size childSize = child.getDryLayout(innerConstraints);
        maxHeight ??= childSize.height;
        final _DropdownMenuBodyParentData childParentData =
            child.parentData! as _DropdownMenuBodyParentData;
        assert(child.parentData == childParentData);
        child = childParentData.nextSibling;
        continue;
      }
      final Size childSize = child.getDryLayout(innerConstraints);
      final _DropdownMenuBodyParentData childParentData =
          child.parentData! as _DropdownMenuBodyParentData;
      childParentData.offset = Offset.zero;
      maxWidth = math.max(maxWidth, childSize.width);
      maxHeight ??= childSize.height;
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }

    assert(maxHeight != null);
    maxWidth = math.max(_kMinimumWidth, maxWidth);
    return constraints.constrain(Size(width ?? maxWidth, maxHeight!));
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    RenderBox? child = firstChild;
    double width = 0;
    while (child != null) {
      if (child == firstChild) {
        final _DropdownMenuBodyParentData childParentData =
            child.parentData! as _DropdownMenuBodyParentData;
        child = childParentData.nextSibling;
        continue;
      }
      final double maxIntrinsicWidth = child.getMinIntrinsicWidth(height);
      if (child == lastChild) {
        width += maxIntrinsicWidth;
      }
      if (child == childBefore(lastChild!)) {
        width += maxIntrinsicWidth;
      }
      width = math.max(width, maxIntrinsicWidth);
      final _DropdownMenuBodyParentData childParentData =
          child.parentData! as _DropdownMenuBodyParentData;
      child = childParentData.nextSibling;
    }

    return math.max(width, _kMinimumWidth);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    RenderBox? child = firstChild;
    double width = 0;
    while (child != null) {
      if (child == firstChild) {
        final _DropdownMenuBodyParentData childParentData =
            child.parentData! as _DropdownMenuBodyParentData;
        child = childParentData.nextSibling;
        continue;
      }
      final double maxIntrinsicWidth = child.getMaxIntrinsicWidth(height);
      // Add the width of leading Icon.
      if (child == lastChild) {
        width += maxIntrinsicWidth;
      }
      // Add the width of trailing Icon.
      if (child == childBefore(lastChild!)) {
        width += maxIntrinsicWidth;
      }
      width = math.max(width, maxIntrinsicWidth);
      final _DropdownMenuBodyParentData childParentData =
          child.parentData! as _DropdownMenuBodyParentData;
      child = childParentData.nextSibling;
    }

    return math.max(width, _kMinimumWidth);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final RenderBox? child = firstChild;
    double width = 0;
    if (child != null) {
      width = math.max(width, child.getMinIntrinsicHeight(width));
    }
    return width;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final RenderBox? child = firstChild;
    double width = 0;
    if (child != null) {
      width = math.max(width, child.getMaxIntrinsicHeight(width));
    }
    return width;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? child = firstChild;
    if (child != null) {
      final _DropdownMenuBodyParentData childParentData =
          child.parentData! as _DropdownMenuBodyParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }
}

// Hand coded defaults. These will be updated once we have tokens/spec.
class _DropdownMenuDefaultsM3 extends DropdownMenuThemeData {
  _DropdownMenuDefaultsM3(this.context);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);

  @override
  TextStyle? get textStyle => _theme.textTheme.bodyLarge;

  @override
  MenuStyle get menuStyle {
    return const MenuStyle(
      minimumSize: MaterialStatePropertyAll<Size>(Size(_kMinimumWidth, 0.0)),
      maximumSize: MaterialStatePropertyAll<Size>(Size.infinite),
      visualDensity: VisualDensity.standard,
    );
  }

  @override
  InputDecorationTheme get inputDecorationTheme {
    return const InputDecorationTheme(border: OutlineInputBorder());
  }
}
