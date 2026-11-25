import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/security_provider.dart';
import '../../../../core/theme/app_colors.dart';

class PasscodeSheet extends ConsumerStatefulWidget {
  const PasscodeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PasscodeSheet(),
    );
  }

  @override
  ConsumerState<PasscodeSheet> createState() => _PasscodeSheetState();
}

class _PasscodeSheetState extends ConsumerState<PasscodeSheet> {
    String _pin = '';

  void _onKeypadPressed(String val) {
    if (_pin.length < 4) {
      setState(() => _pin += val);
      if (_pin.length == 4) {
        _savePin();
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }
  
  Future<void> _savePin() async {
    await ref.read(securityProvider.notifier).setPasscode(_pin);
    if (mounted) Navigator.pop(context);
  }
  
  Future<void> _clearPin() async {
    await ref.read(securityProvider.notifier).setPasscode(null);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingPin = ref.watch(securityProvider).passcode != null;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 40),
      child: Column(
        children: [
          Text(
            hasExistingPin ? 'Change Passcode' : 'Set Passcode',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? AppColors.primary : Colors.transparent,
                  border: Border.all(color: isFilled ? AppColors.accent(context) : AppColors.borderColor(context), width: 2),
                ),
              );
            }),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index == 9) return const SizedBox.shrink();
                if (index == 11) {
                  return InkWell(
                    onTap: _onDeletePressed,
                    borderRadius: BorderRadius.circular(40),
                    child: Center(child: Icon(Icons.backspace_outlined, color: AppColors.text(context)),
                    ),
                  );
                }
                final num = index == 10 ? '0' : '\${index + 1}';
                return InkWell(
                  onTap: () => _onKeypadPressed(num),
                  borderRadius: BorderRadius.circular(40),
                  child: Center(
                    child: Text(
                      num,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.text(context)),
                    ),
                  ),
                );
              },
            ),
          ),
          if (hasExistingPin)
            TextButton(
              onPressed: _clearPin,
              child: const Text('Remove Passcode', style: TextStyle(color: Color(0xFFFF5252))),
            )
        ],
      ),
    );
  }
}
