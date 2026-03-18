part of 'app_icon_cubit.dart';

class AppIconState extends Equatable {
  final String iconName;

  const AppIconState({this.iconName = 'default'});

  bool get isDefault => iconName == 'default';
  bool get isAlternative => iconName == 'alternative';

  @override
  List<Object?> get props => [iconName];
}
