import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
 
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';

/// The original site's 5-button sign-in menu, split into a real screen.
///
/// Per PLANNING.md section 2, these 5 buttons map to only 3 architectural
/// roles (Student / Parent / Staff — Teacher, School Counsellor, and
/// Coordinator are permission variants of one Staff role). That's a
/// *folder-structure* decision, not a UI one: all 5 original labels are
/// kept here for visual parity with the live site, since a returning user
/// shouldn't see options quietly disappear. Only Student routes anywhere
/// today; the other 4 are visibly present but disabled with a
/// "Coming soon" tag, per the Day 1 scope.
class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Runata Pathway',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Choose how you'd like to sign in",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 32),
                  _RoleButton(
                    icon: '🎓',
                    label: 'Student',
                    enabled: true,
                    onTap: () => context.go(AppRoutes.studentLogin),
                  ),
                  const _RoleButton(icon: '👨‍👩‍👧', label: 'Parent', enabled: false),
                  const _RoleButton(icon: '🧑‍🏫', label: 'Teacher', enabled: false),
                  const _RoleButton(
                    icon: '💬',
                    label: 'School Counsellor',
                    enabled: false,
                  ),
                  const _RoleButton(
                    icon: '🧭',
                    label: 'Coordinator',
                    enabled: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.icon,
    required this.label,
    required this.enabled,
    this.onTap,
  });

  final String icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: enabled ? AppColors.surface : AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: enabled ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                ),
                if (!enabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Text(
                      'Coming soon',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
