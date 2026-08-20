import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _isProcessing = false;

  Future<void> _handleApprove(int userId) async {
    setState(() => _isProcessing = true);
    final success = await ApiClient.approveUser(userId);
    setState(() => _isProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Kullanıcı kaydı başarıyla onaylandı.' : 'Onaylama sırasında bir hata oluştu.'),
          backgroundColor: success ? AppColors.working : AppColors.alarm,
        ),
      );
      context.read<AppProvider>().refreshData();
    }
  }

  Future<void> _handleReject(int userId) async {
    setState(() => _isProcessing = true);
    final success = await ApiClient.rejectUser(userId);
    setState(() => _isProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Kullanıcı başvurusu reddedildi.' : 'İşlem sırasında bir hata oluştu.'),
          backgroundColor: AppColors.alarm,
        ),
      );
      context.read<AppProvider>().refreshData();
    }
  }

  Future<void> _handleDelete(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Kullanıcıyı Sil', style: TextStyle(color: Colors.white)),
        content: const Text('Bu kullanıcı hesabını silmek istediğinize emin misiniz?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alarm),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      final success = await ApiClient.deleteUser(userId);
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Kullanıcı silindi.' : 'Silme işlemi başarısız.'),
            backgroundColor: success ? AppColors.working : AppColors.alarm,
          ),
        );
        context.read<AppProvider>().refreshData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final users = provider.users;
        final pendingUsers = users.where((u) => u.durum == 'onay_bekliyor' || u.durum == 'bekliyor').toList();

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('Kullanıcı Onaylama & Yönetim', style: TextStyle(color: AppColors.textPrimary)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: provider.refreshData,
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Pending Approval Banner (Onay Bekleyen Başvurular)
                  if (pendingUsers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      color: AppColors.idle.withValues(alpha: 0.2),
                      child: Row(
                        children: [
                          const Icon(Icons.pending_actions_rounded, color: AppColors.idle, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${pendingUsers.length} Adet Onay Bekleyen Yeni Kullanıcı Başvurusu Var!',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Header Summary
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
                                'Sistemde ${users.length} Kayıtlı Kullanıcı Bulunuyor',
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const Text(
                                'Yönetici (Admin) ve Patron hesaplarının onaylanması ve yetkileri.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // User List
                  Expanded(
                    child: users.isEmpty
                        ? const Center(
                            child: Text('Kayıtlı kullanıcı bulunamadı.', style: TextStyle(color: AppColors.textSecondary)),
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
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
      roleColor = AppColors.textSecondary;
      roleIcon = Icons.person_rounded;
    }

    final isPending = user.durum == 'onay_bekliyor' || user.durum == 'bekliyor';

    return Card(
      color: AppColors.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isPending ? AppColors.idle : AppColors.cardBorder, width: isPending ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: roleColor.withValues(alpha: 0.2),
                  child: Icon(roleIcon, color: roleColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.adSoyad,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.kullaniciAdi} • ${user.email ?? "E-Posta Yok"}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    user.rol.toUpperCase(),
                    style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 8),

            // User Actions: Approve / Reject / Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isPending ? '⚠️ Durum: Onay Bekliyor' : '✅ Durum: Onaylandı',
                  style: TextStyle(
                    color: isPending ? AppColors.idle : AppColors.working,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    if (isPending) ...[
                      IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: AppColors.working, size: 24),
                        onPressed: () => _handleApprove(user.id),
                        tooltip: 'Başvuruyu Onayla',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_rounded, color: AppColors.alarm, size: 24),
                        onPressed: () => _handleReject(user.id),
                        tooltip: 'Başvuruyu Reddet',
                      ),
                    ],
                    if (user.kullaniciAdi != 'admin')
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 20),
                        onPressed: () => _handleDelete(user.id),
                        tooltip: 'Kullanıcıyı Sil',
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
