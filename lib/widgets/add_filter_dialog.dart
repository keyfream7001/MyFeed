import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/filter_provider.dart';
import '../models/filter.dart';

class AddFilterDialog extends StatefulWidget {
  const AddFilterDialog({super.key});

  @override
  State<AddFilterDialog> createState() => _AddFilterDialogState();
}

class _AddFilterDialogState extends State<AddFilterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  
  FilterType _selectedType = FilterType.keyword;
  FilterAction _selectedAction = FilterAction.hide;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '필터 추가',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Filter type
              Text(
                '필터 유형',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              SegmentedButton<FilterType>(
                segments: const [
                  ButtonSegment(
                    value: FilterType.keyword,
                    label: Text('키워드'),
                    icon: Icon(Icons.text_fields),
                  ),
                  ButtonSegment(
                    value: FilterType.source,
                    label: Text('소스'),
                    icon: Icon(Icons.rss_feed),
                  ),
                  ButtonSegment(
                    value: FilterType.author,
                    label: Text('작성자'),
                    icon: Icon(Icons.person),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedType = selection.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // Value field
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: _getValueLabel(),
                  hintText: _getValueHint(),
                  prefixIcon: Icon(_getValueIcon()),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '값을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Filter action
              Text(
                '필터 동작',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              RadioListTile<FilterAction>(
                title: const Text('숨기기'),
                subtitle: const Text('해당 콘텐츠를 완전히 숨깁니다'),
                value: FilterAction.hide,
                groupValue: _selectedAction,
                onChanged: (value) {
                  setState(() {
                    _selectedAction = value!;
                  });
                },
              ),
              RadioListTile<FilterAction>(
                title: const Text('흐리게 표시'),
                subtitle: const Text('해당 콘텐츠를 흐리게 표시합니다'),
                value: FilterAction.mute,
                groupValue: _selectedAction,
                onChanged: (value) {
                  setState(() {
                    _selectedAction = value!;
                  });
                },
              ),
              
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('추가하기'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getValueLabel() {
    return switch (_selectedType) {
      FilterType.keyword => '키워드',
      FilterType.source => '소스 이름',
      FilterType.author => '작성자 이름',
    };
  }

  String _getValueHint() {
    return switch (_selectedType) {
      FilterType.keyword => '예: 광고, 스포일러',
      FilterType.source => '예: 스팸사이트',
      FilterType.author => '예: 스패머',
    };
  }

  IconData _getValueIcon() {
    return switch (_selectedType) {
      FilterType.keyword => Icons.text_fields,
      FilterType.source => Icons.rss_feed,
      FilterType.author => Icons.person,
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<FilterProvider>();
    final success = await provider.addFilter(
      type: _selectedType,
      value: _valueController.text,
      action: _selectedAction,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('필터가 추가되었습니다')),
        );
      } else {
        setState(() {
          _error = provider.error ?? '필터를 추가할 수 없습니다';
        });
        provider.clearError();
      }
    }
  }
}
