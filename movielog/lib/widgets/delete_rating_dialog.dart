import 'package:flutter/material.dart';

import '../core/network/api_error.dart';
import '../theme/app_colors.dart';
import 'movielog_button.dart';

/// 7주차 평점 삭제 확인 Dialog.
/// - 취소하면 onConfirm을 호출하지 않으므로 삭제 요청을 보내지 않습니다.
/// - 삭제 요청 중에는 Dialog를 닫을 수 없습니다.
/// - 실제로 삭제까지 마쳤을 때만 true를 반환합니다.
class DeleteRatingDialog extends StatefulWidget {
  const DeleteRatingDialog({super.key, required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<DeleteRatingDialog> {
  bool _isDeleting = false;
  String? _errorText;

  Future<void> _onConfirm() async {
    setState(() {
      _isDeleting = true;
      _errorText = null;
    });
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorText = error is UserMessageException
            ? error.message
            : '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        backgroundColor: AppColors.warmWhite,
        title: const Text('평점을 삭제할까요?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('삭제한 평점은 복구할 수 없습니다.'),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(_errorText!, style: const TextStyle(color: AppColors.red)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          MovieLogButton(
            label: '삭제',
            isLoading: _isDeleting,
            onPressed: _onConfirm,
          ),
        ],
      ),
    );
  }
}
