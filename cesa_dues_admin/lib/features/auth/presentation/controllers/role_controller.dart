import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';

/// Provider to hold the current admin's role and persist it across reloads.
class RoleController extends StateNotifier<UserRole> {
  RoleController() : super(UserRole.financialSecretary) {
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('admin_role');
    if (savedRole == UserRole.hod.name) {
      state = UserRole.hod;
    } else {
      state = UserRole.financialSecretary;
    }
  }

  Future<void> setRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_role', role.name);
    state = role;
  }
}

final roleControllerProvider = StateNotifierProvider<RoleController, UserRole>((ref) {
  return RoleController();
});
