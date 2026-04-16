import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/settings_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/error_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<SettingsProvider>().fetchSettings());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: () {
        if (provider.isLoading && provider.settings.isEmpty) {
          return const ShimmerLoading(itemCount: 4);
        }
        if (provider.error != null && provider.settings.isEmpty) {
          return ErrorState(
              message: provider.error!,
              onRetry: () => context.read<SettingsProvider>().fetchSettings());
        }
        return RefreshIndicator(
          onRefresh: () => context.read<SettingsProvider>().fetchSettings(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: provider.settings.length + 2,
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      leading: const Icon(Icons.lock_outline,
                          color: AppColors.primary),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.changePassword),
                    ),
                  ),
                );
              }
              if (i == provider.settings.length + 1) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Money Manager v1.0.0',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                );
              }
              final setting = provider.settings[i - 1];
              return _SettingTile(setting: setting);
            },
          ),
        );
      }(),
    );
  }
}

class _SettingTile extends StatefulWidget {
  final dynamic setting;
  const _SettingTile({required this.setting});

  @override
  State<_SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<_SettingTile> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _isSaving = false;

  bool get _isTimeSetting =>
      widget.setting.key == 'edit_window_start' ||
      widget.setting.key == 'edit_window_end';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.setting.value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeDisplay(String value) {
    final time = _parseTime(value);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _pickTime() async {
    final current = _parseTime(_controller.text);
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null) {
      _controller.text = _formatTime(picked);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await context.read<SettingsProvider>().updateSetting(
            widget.setting.id as int,
            _controller.text.trim(),
          );
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Setting updated'),
        backgroundColor: AppColors.success,
      ));
    } on ValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.firstError), backgroundColor: AppColors.error));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.setting.key,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      if (widget.setting.description != null)
                        Text(widget.setting.description!,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined,
                      size: 18),
                  onPressed: () => setState(() {
                    _isEditing = !_isEditing;
                    if (!_isEditing) {
                      _controller.text = widget.setting.value.toString();
                    }
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isEditing) ...[
              if (_isTimeSetting)
                GestureDetector(
                  onTap: _pickTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _controller,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        suffixIcon: const Icon(Icons.access_time),
                      ),
                    ),
                  ),
                )
              else
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        side: const BorderSide(color: AppColors.divider),
                      ),
                      onPressed: () => setState(() {
                        _isEditing = false;
                        _controller.text = widget.setting.value.toString();
                      }),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size.fromHeight(40),
                      ),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ] else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _isTimeSetting
                      ? _formatTimeDisplay(widget.setting.value.toString())
                      : widget.setting.value.toString(),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
