import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../models/feed_source.dart';

class AddFeedDialog extends StatefulWidget {
  const AddFeedDialog({super.key});

  @override
  State<AddFeedDialog> createState() => _AddFeedDialogState();
}

class _AddFeedDialogState extends State<AddFeedDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;

  // Popular feed suggestions
  final _suggestions = [
    ('GeekNews', 'https://news.hada.io/rss'),
    ('TechCrunch', 'https://techcrunch.com/feed/'),
    ('The Verge', 'https://www.theverge.com/rss/index.xml'),
    ('Ars Technica', 'https://feeds.arstechnica.com/arstechnica/index'),
    ('Hacker News', 'https://hnrss.org/frontpage'),
  ];

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
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
                    '피드 추가',
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
              
              // URL field
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'RSS/피드 URL',
                  hintText: 'https://example.com/feed.xml',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'URL을 입력해주세요';
                  }
                  if (!Uri.tryParse(value)!.hasScheme ?? true) {
                    return '올바른 URL 형식이 아닙니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Name field (optional)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '이름 (선택)',
                  hintText: '피드 이름을 입력하세요',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 16),
              
              // Category field (optional)
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: '카테고리 (선택)',
                  hintText: '뉴스, 기술, 블로그 등',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
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
              
              const SizedBox(height: 24),
              
              // Suggestions
              Text(
                '추천 피드',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((s) {
                  return ActionChip(
                    label: Text(s.$1),
                    onPressed: () {
                      _urlController.text = s.$2;
                      _nameController.text = s.$1;
                    },
                  );
                }).toList(),
              ),
              
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<FeedProvider>();
    final success = await provider.addSource(
      name: _nameController.text,
      url: _urlController.text,
      category: _categoryController.text.isNotEmpty
          ? _categoryController.text
          : null,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('피드가 추가되었습니다')),
        );
      } else {
        setState(() {
          _error = provider.error ?? '피드를 추가할 수 없습니다';
        });
        provider.clearError();
      }
    }
  }
}
