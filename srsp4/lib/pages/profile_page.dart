import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/app_scope.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/localization/app_locales.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static const appVersion = '1.0.0';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notifications = true;

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.storefront, color: AppColors.primary, size: 40.sp),
        title: Text('app_title'.tr(), style: AppTextStyles.subtitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'about_text'.tr(),
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'version'.tr(args: [ProfilePage.appVersion]),
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.of(context).theme;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        children: [
          Text('profile'.tr(), style: AppTextStyles.headline),
          SizedBox(height: 20.h),

          // Аватар и имя
          Center(
            child: Container(
              padding: EdgeInsets.all(4.r),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 48.r,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: Icon(
                  Icons.person,
                  size: 56.sp,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'user_name'.tr(),
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            'user_email'.tr(),
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),

          // Настройки
          Text('settings'.tr(), style: AppTextStyles.subtitle),
          SizedBox(height: 10.h),
          Card(
            child: Column(
              children: [
                // Переключатель языка
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _SettingIcon(icon: Icons.language),
                          SizedBox(width: 14.w),
                          Text('language'.tr(), style: AppTextStyles.body),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<Locale>(
                          showSelectedIcon: false,
                          segments: [
                            for (final locale in AppLocales.supported)
                              ButtonSegment(
                                value: locale,
                                label: Text(
                                  AppLocales.nameOf(locale),
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                              ),
                          ],
                          selected: {context.locale},
                          onSelectionChanged: (selection) =>
                              context.setLocale(selection.first),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Тёмная тема
                ValueListenableBuilder(
                  valueListenable: theme,
                  builder: (context, mode, _) => _SettingSwitch(
                    icon: Icons.dark_mode_outlined,
                    title: 'dark_theme'.tr(),
                    value: mode == ThemeMode.dark,
                    onChanged: theme.setDark,
                  ),
                ),
                const Divider(height: 1),

                // Уведомления
                _SettingSwitch(
                  icon: Icons.notifications_outlined,
                  title: 'notifications'.tr(),
                  value: _notifications,
                  onChanged: (value) => setState(() => _notifications = value),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // О приложении
          Card(
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
              leading: _SettingIcon(icon: Icons.info_outline),
              title: Text('about_app'.tr(), style: AppTextStyles.body),
              subtitle: Text(
                'version'.tr(args: [ProfilePage.appVersion]),
                style: AppTextStyles.small,
              ),
              trailing: Icon(Icons.chevron_right, size: 24.sp),
              onTap: _showAbout,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20.sp),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
      secondary: _SettingIcon(icon: icon),
      title: Text(title, style: AppTextStyles.body),
      value: value,
      activeTrackColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
