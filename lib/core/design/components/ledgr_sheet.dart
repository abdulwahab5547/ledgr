import 'package:flutter/material.dart';

import '../ledgr_colors.dart';
import '../ledgr_radii.dart';

/// Wraps the contents of a `showModalBottomSheet` builder so every sheet in
/// the app shares the same surface — bg color, top radii, hairline, drag
/// handle, keyboard inset padding.
class LedgrSheet extends StatelessWidget {
  const LedgrSheet({
    required this.child,
    this.padding =
        const EdgeInsets.fromLTRB(22, 12, 22, 32),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget Function(BuildContext) builder,
  }) {
    // useRootNavigator pushes the modal above go_router's ShellRoute, so
    // the bottom tab bar (which lives inside the shell's Stack) is hidden
    // behind the modal scrim instead of overlapping the sheet's buttons.
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C000000),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: LedgrSheet(child: builder(sheetCtx)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final basePadding = padding.resolve(TextDirection.ltr);
    // Whole-sheet scroll: when the form is taller than the bottom-sheet's
    // available height, the user scrolls. The drag handle scrolls with it,
    // which matches typical iOS sheet behaviour. Bottom padding includes
    // the iPhone home indicator so the action row never sits under it.
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFF15161A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(LedgrRadii.sheet),
          topRight: Radius.circular(LedgrRadii.sheet),
        ),
        border: Border(
          top: BorderSide(color: LedgrColors.hairline2, width: 0.5),
          left: BorderSide(color: LedgrColors.hairline2, width: 0.5),
          right: BorderSide(color: LedgrColors.hairline2, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          basePadding.left,
          basePadding.top,
          basePadding.right,
          basePadding.bottom + media.viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 4, bottom: 18),
                decoration: BoxDecoration(
                  color: LedgrColors.hairline2,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
