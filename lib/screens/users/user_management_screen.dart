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

  void _showApproveDialog(BuildContext context, UserModel user) {
    final Map<String, bool> selectedStations = {
      'Istasyon-1': true,
      'Istasyon-2': true,
      'Istasyon-3': true,
      'Istasyon-4': true,
    };

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: Row(
                children: const [
                  Icon(Icons.verified_user_rounded, color: AppColors.working),
                  SizedBox(width: 8),
                  Text('Onayla & Yetkilendir', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${user.adSoyad} (@${user.kullaniciAdi})',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (user.firmaAdi != null && user.firmaAdi!.isNotEmpty)
                      Text('Firma/Birim: ${user.firmaAdi}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.flag_rounded, color: Colors.orangeAccent, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Bu Kullanıcının Görebileceği İstasyonlar:',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildStationCheckTile('tuğba çevik — Istasyon-1', 'Istasyon-1', selectedStations, setDialogState),
                    _buildStationCheckTile('Kadir Kaya — Istasyon-2', 'Istasyon-2', selectedStations, setDialogState),
                    _buildStationCheckTile('Haşim Köksal — Istasyon-3', 'Istasyon-3', selectedStations, setDialogState),
                    _buildStationCheckTile('gizem akarsu — Istasyon-4', 'Istasyon-4', selectedStations, setDialogState),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  label: const Text('Onayla & Yetkilendir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.working),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final approvedList = selectedStations.entries.where((e) => e.value).map((e) => e.key).toList();
                    setState(() => _isProcessing = true);
                    final success = await ApiClient.approveUser(user.id, selectedStations: approvedList);
                    setState(() => _isProcessing = false);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '"${user.adSoyad}" başvurusu onaylandı ve yetkilendirildi.' : 'Onaylama sırasında bir hata oluştu.'),
                          backgroundColor: success ? AppColors.working : AppColors.alarm,
                        ),
                      );
                      context.read<AppProvider>().refreshData();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStationCheckTile(String label, String key, Map<String, bool> selectedMap, StateSetter setDialogState) {
    final isChecked = selectedMap[key] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isChecked ? AppColors.primary.withValues(alpha: 0.15) : AppColors.bgDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isChecked ? AppColors.primary : AppColors.cardBorder),
      ),
      child: CheckboxListTile(
        title: Text(
          label,
          style: TextStyle(
            color: isChecked ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        value: isChecked,
        activeColor: AppColors.primary,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        onChanged: (val) {
          setDialogState(() {
            selectedMap[key] = val ?? false;
          });
        },
      ),
    );
  }

  Future<void> _handleReject(int userId) async {
    setState(() => _isProcessing = true);
    final success = await ApiClient.rejectUser(userId);
    setState(() => _isProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Başvuru reddedildi.' : 'İşlem sırasında bir hata oluştu.'),
          backgroundColor: AppColors.alarm,
        ),
      );
      context.read<AppProvider>().refreshData();
    }
  }

  Future<void> _handleDelete(int userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Başvuruyu / Hesabı Sil', style: TextStyle(color: Colors.white)),
        content: Text('"$name" başvurusunu tamamen silmek istediğinize emin misiniz? Bu işlem geri alınamaz.', style: const TextStyle(color: AppColors.textSecondary)),
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
            content: Text(success ? '"$name" başvurusu/hesabı silindi.' : 'Silme işlemi başarısız.'),
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
            title: const Text('Patron Yetkilendirme & Üye Onayları', style: TextStyle(color: AppColors.textPrimary)),
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
                  // Pending Approval Banner
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
                              '${pendingUsers.length} Adet Onay Bekleyen Başvuru Var!',
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
                                'Üye Kayıt Onayları (${users.length} Kayıt)',
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const Text(
                                'Patronların izleyebilecekleri istasyonları belirleyerek onaylayın veya silin.',
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
    final isRejected = user.durum == 'reddedildi';

    String statusText;
    Color statusColor;

    if (isPending) {
      statusText = '⚠️ Onay Bekliyor';
      statusColor = AppColors.idle;
    } else if (isRejected) {
      statusText = '❌ Başvuru Reddedildi';
      statusColor = AppColors.alarm;
    } else {
      statusText = '✅ Hesabı Onaylandı';
      statusColor = AppColors.working;
    }

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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (user.firmaAdi != null && user.firmaAdi!.isNotEmpty)
                        Text(
                          'Firma / Birim: ${user.firmaAdi}',
                          style: const TextStyle(color: AppColors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w600),
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

            if (user.istasyonlar != null && user.istasyonlar!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam_rounded, color: AppColors.cyanAccent, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Yetkili İstasyonlar: ${user.istasyonlar}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 8),

            // Actions: Approve & Authorize Stations / Reject / Delete
            Row(
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isPending) ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                          label: const Text('Onayla & Yetkilendir', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.working,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _showApproveDialog(context, user),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.cancel_rounded, color: AppColors.alarm, size: 20),
                          onPressed: () => _handleReject(user.id),
                          tooltip: 'Başvuruyu Reddet',
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (user.kullaniciAdi != 'admin')
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 18),
                          onPressed: () => _handleDelete(user.id, user.adSoyad),
                          tooltip: 'Başvuruyu / Hesabı Sil',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
