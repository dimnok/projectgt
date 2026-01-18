import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/presentation/state/profile_state.dart';

/// Форма для заполнения данных профиля (ФИО).
///
/// Отвечает за ввод данных, валидацию и логику сохранения.
class ProfileCompletionForm extends ConsumerStatefulWidget {
  /// Создает экземпляр [ProfileCompletionForm].
  const ProfileCompletionForm({super.key});

  @override
  ConsumerState<ProfileCompletionForm> createState() =>
      _ProfileCompletionFormState();
}

class _ProfileCompletionFormState extends ConsumerState<ProfileCompletionForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    // Слайд от самого низа (1.0), чтобы имитировать выезд нового окна
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuart,
          ),
        );

    // Задержка 400мс, чтобы окно OTP успело полностью уехать вниз
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Пожалуйста, введите ФИО';
    }
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return 'Введите фамилию и имя';
    }
    return null;
  }

  Future<void> _completeProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final fullName = _fullNameController.text.trim();
      final currentProfile = ref.read(currentUserProfileProvider).profile;

      if (currentProfile == null) throw Exception('Профиль не найден');

      await ref
          .read(completeUserProfileUseCaseProvider)
          .execute(fullName: fullName, phone: currentProfile.phone ?? '');

      final updatedProfile = currentProfile.copyWith(
        fullName: fullName,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(currentUserProfileProvider.notifier)
          .updateCurrentUserProfile(updatedProfile);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Профиль успешно сохранен'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GTTextField(
                controller: _fullNameController,
                labelText: 'Фамилия Имя',
                hintText: 'Иванов Иван',
                prefixIcon: CupertinoIcons.person,
                validator: _validateFullName,
                textCapitalization: TextCapitalization.words,
                enabled: !_isLoading,
                onSubmitted: (_) => _completeProfile(),
              ),
              const SizedBox(height: 32),
              GTPrimaryButton(
                    text: 'Завершить регистрацию',
                    onPressed: _completeProfile,
                    isLoading: _isLoading,
                    icon: CupertinoIcons.check_mark_circled,
                  )
                  .animate()
                  .fade(duration: 300.ms)
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    curve: Curves.easeOutBack,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
