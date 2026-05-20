import 'package:flutter/material.dart';
import 'package:trusttunnel/common/extensions/theme_extensions.dart';
import 'package:trusttunnel/common/utils/common_utils.dart';
import 'package:trusttunnel/data/model/breakpoint.dart';
import 'package:trusttunnel/di/widgets/dependency_scope.dart';
import 'package:trusttunnel/di/model/dependency_factory.dart';
import 'package:trusttunnel/di/model/repository_factory.dart';
import 'package:trusttunnel/widgets/arb_parser/arb_parser.dart';
import 'package:trusttunnel/widgets/common/scaffold_messenger_provider.dart';
import 'package:trusttunnel/widgets/custom_snack_bar.dart';

extension ScreenTypeExtension on BuildContext {
  Breakpoint get breakpoint => CommonUtils.getBreakpointByWidth(MediaQuery.of(this).size.width);

  bool get isMobileBreakpoint => breakpoint == Breakpoint.XS;
}

extension MediaQueryExtension on BuildContext {
  double get scaleFactor => MediaQuery.of(this).textScaler.scale(1.0);
}

extension DependencyExtension on BuildContext {
  DependencyFactory get dependencyFactory => DependencyScope.getDependenciesFactory(this);

  RepositoryFactory get repositoryFactory => DependencyScope.getRepositoryFactory(this);
}

extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => Theme.of(this).textTheme;

  CustomColors get colors => Theme.of(this).extension<CustomColors>()!;
}

extension SnackBarExtension on BuildContext {
  void showInfoSnackBar({
    required String message,
    bool showCloseIcon = true,
    SnackBarBehavior behavior = SnackBarBehavior.fixed,
  }) {
    var scaffoldMessenger = ScaffoldMessenger.of(this);

    if (scaffoldMessenger is ScaffoldMessengerProviderState) {
      scaffoldMessenger = scaffoldMessenger.value;
    }

    scaffoldMessenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        CustomSnackBar(
          content: ArbParser(
            data: message,
          ),
          behavior: behavior,
          showCloseIcon: showCloseIcon,
        ),
      );
  }
}

extension NavigatorExtension on BuildContext {
  void pop<T>({T? result}) => Navigator.of(this).pop(result);

  WidgetBuilder _getWidgetBuilder(BuildContext context, Widget widget) {
    final parentScaffoldMessenger = ScaffoldMessenger.maybeOf(context);

    return (innerContext) => ScaffoldMessengerProvider(
      value: parentScaffoldMessenger ?? ScaffoldMessenger.of(innerContext),
      child: widget,
    );
  }

  Future<T?> push<T extends Object?>(Widget widget) => Navigator.of(this).push(
    MaterialPageRoute<T>(
      builder: (innerContext) => _getWidgetBuilder(this, widget).call(innerContext),
    ),
  );
}

