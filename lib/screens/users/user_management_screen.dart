import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final users = provider.users;

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('Kullanıcı & Yönetici Hesapları', style: TextStyle(color: AppColors.textPrimary)),
          ),
          body: Column(
            children: [
              // Header Summary Banner
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.cardDark,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.brandRedLight.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.manage_accounts_rounded, color: AppColors.brandRedLight, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sistemde Kayıtlı ${users.length} Hesap Bulunuyor',
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const Text(
                            'Yönetici (Admin), Patron ve Saha Kullanıcı hesapları.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Users List
              Expanded(
                child: users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.person_off_rounded, size: 52, color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text(
                              'Kayıtlı kullanıcı bulunamadı.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _buildUserTile(user);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserTile(UserModel user) {
    Color roleColor;
    IconData roleIcon;

    if (user.rol == 'admin') {
      roleColor = AppColors.brandRedLight;
      roleIcon = Icons.admin_panel_settings_rounded;
    } else if (user.rol == 'patron') {
      roleColor = AppColors.cyanAccent;
      roleIcon = Icons.business_center_rounded;
    } else {
      roleColor = AppColors.working;
      roleIcon = Icons.person_rounded;
    }

    return Card(
      color: AppColors.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: roleColor.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: roleColor.withValues(alpha: 0.15),
          child: Icon(roleIcon, color: roleColor, size: 24),
        ),
        title: Row(
          children: [
            Text(
              user.adSoyad,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.rol.toUpperCase(),
                style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Kullanıcı Adı: ${user.kullaniciAdi}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            if (user.email != null && user.email!.isNotEmpty)
              Text(
                'E-Posta: ${user.email}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.working.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'ONAYLI',
            style: TextStyle(color: AppColors.working, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ),
    );
  }
}
