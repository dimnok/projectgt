import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/company/presentation/widgets/company_create_dialog.dart';
import 'package:projectgt/presentation/state/auth_state.dart';

/// Экран онбординга компании (выбор: создать новую или вступить по коду).
///
/// Показывается пользователям, у которых еще не привязана активная компания.
class CompanyOnboardingScreen extends ConsumerStatefulWidget {
  /// Конструктор [CompanyOnboardingScreen].
  const CompanyOnboardingScreen({super.key});

  @override
  ConsumerState<CompanyOnboardingScreen> createState() => _CompanyOnboardingScreenState();
}

class _CompanyOnboardingScreenState extends ConsumerState<CompanyOnboardingScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 450 : double.infinity),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Иконка
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.building_2_fill, 
                        size: 64, 
                        color: theme.colorScheme.primary
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Text(
                      'Выберите организацию',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Для начала работы необходимо создать новую компанию или присоединиться к существующей.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Блок 1: Вступить по коду
                    _buildActionCard(
                      theme: theme,
                      title: 'Вступить по коду',
                      description: 'Если у вас есть код приглашения от вашей организации',
                      child: Column(
                        children: [
                          TextField(
                            controller: _codeController,
                            decoration: const InputDecoration(
                              labelText: 'Код приглашения',
                              hintText: 'Например: GT-ABC12345',
                              prefixIcon: Icon(CupertinoIcons.ticket),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GTPrimaryButton(
                            text: 'Присоединиться',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Функционал вступления будет доступен в следующем обновлении'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ИЛИ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Блок 2: Создать новую компанию
                    _buildActionCard(
                      theme: theme,
                      title: 'Создать новую компанию',
                      description: 'Зарегистрируйте свою организацию и пригласите сотрудников',
                      child: GTSecondaryButton(
                        text: 'Создать компанию',
                        onPressed: () => CompanyCreateDialog.show(
                          context,
                          onSuccess: () => ref
                              .read(authProvider.notifier)
                              .checkAuthStatus(force: true),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Кнопка выхода (на случай если пользователь ошибся аккаунтом)
                    TextButton.icon(
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                      icon: const Icon(CupertinoIcons.arrow_left_square),
                      label: const Text('Выйти из аккаунта'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required ThemeData theme,
    required String title,
    required String description,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

