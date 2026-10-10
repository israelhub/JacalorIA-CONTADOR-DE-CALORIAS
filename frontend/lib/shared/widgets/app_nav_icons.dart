import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

abstract final class AppNavIcons {
  static IconData performance({required bool selected}) =>
      PhosphorIcons.calendarBlank(_style(selected));

  static IconData home({required bool selected}) =>
      PhosphorIcons.house(_style(selected));

  static IconData social({required bool selected}) =>
      PhosphorIcons.users(_style(selected));

  static IconData more({required bool selected}) =>
      PhosphorIcons.plus(_style(selected));

  static IconData get camera =>
      PhosphorIcons.camera(PhosphorIconsStyle.regular);

  static IconData missions({required bool selected}) =>
      PhosphorIcons.target(_style(selected));

  static IconData workout({required bool selected}) =>
      PhosphorIcons.barbell(_style(selected));

  static IconData get profile =>
      PhosphorIcons.user(PhosphorIconsStyle.regular);

  static IconData get store =>
      PhosphorIcons.storefront(PhosphorIconsStyle.regular);

  static IconData get notifications =>
      PhosphorIcons.bell(PhosphorIconsStyle.regular);

  static PhosphorIconsStyle _style(bool selected) =>
      selected ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular;
}
