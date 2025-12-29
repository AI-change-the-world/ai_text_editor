import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/objectbox/entities/model_profile.dart';
import '../../../services/model_profile_service.dart';

/// AI 模型配置 Provider
final modelProfilesProvider = FutureProvider<List<ModelProfile>>((ref) async {
  return ModelProfileService.instance.getAllProfiles();
});

/// AI 模型设置组件
/// 管理 AI 模型配置，包括提供商、API 密钥和参数
/// Requirements: 8.2
class AIModelSettings extends ConsumerStatefulWidget {
  const AIModelSettings({super.key});

  @override
  ConsumerState<AIModelSettings> createState() => _AIModelSettingsState();
}

class _AIModelSettingsState extends ConsumerState<AIModelSettings> {
  AITask? _selectedTask;

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(modelProfilesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 任务类型选择器
        _buildTaskSelector(),
        const SizedBox(height: 24),

        // 模型列表
        profilesAsync.when(
          data: (profiles) => _buildModelList(profiles),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('加载失败: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, size: 20, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text(
                '任务类型',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTaskChip(null, '全部'),
              ...AITask.values
                  .map((task) => _buildTaskChip(task, _getTaskLabel(task))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskChip(AITask? task, String label) {
    final isSelected = _selectedTask == task;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTask = selected ? task : null;
        });
      },
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade700 : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  String _getTaskLabel(AITask task) {
    switch (task) {
      case AITask.writing:
        return '写作';
      case AITask.qa:
        return '问答';
      case AITask.translation:
        return '翻译';
      case AITask.summarization:
        return '摘要';
      case AITask.code:
        return '代码';
      case AITask.embedding:
        return '嵌入';
    }
  }

  Widget _buildModelList(List<ModelProfile> profiles) {
    // 过滤模型
    final filteredProfiles = _selectedTask == null
        ? profiles
        : profiles.where((p) => p.taskType == _selectedTask).toList();

    if (filteredProfiles.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // 添加模型按钮
        _buildAddModelButton(),
        const SizedBox(height: 16),
        // 模型卡片列表
        ...filteredProfiles.map((profile) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildModelCard(profile),
            )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无模型配置',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加第一个 AI 模型',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          _buildAddModelButton(),
        ],
      ),
    );
  }

  Widget _buildAddModelButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAddModelDialog(),
        icon: const Icon(Icons.add),
        label: const Text('添加模型配置'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.blue.shade300),
          foregroundColor: Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildModelCard(ModelProfile profile) {
    final provider = AIProvider.fromId(profile.provider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              profile.isDefault ? Colors.blue.shade300 : Colors.grey.shade200,
          width: profile.isDefault ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // 卡片头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                // 提供商图标
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getProviderColor(profile.provider)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _getProviderInitial(profile.provider),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getProviderColor(profile.provider),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 模型信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (profile.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '默认',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${provider?.displayName ?? profile.provider} · ${profile.modelName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // 任务类型标签
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getTaskLabel(profile.taskType),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 操作菜单
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) => _handleModelAction(value, profile),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                    if (!profile.isDefault)
                      const PopupMenuItem(
                        value: 'setDefault',
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 18),
                            SizedBox(width: 8),
                            Text('设为默认'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 卡片内容
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildModelParam('温度', profile.temperature.toStringAsFixed(1)),
                const SizedBox(width: 24),
                _buildModelParam('最大 Token', '${profile.maxTokens}'),
                const SizedBox(width: 24),
                _buildModelParam(
                  'API Key',
                  profile.apiKey != null && profile.apiKey!.isNotEmpty
                      ? '已配置'
                      : '未配置',
                  isWarning: profile.apiKey == null || profile.apiKey!.isEmpty,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelParam(String label, String value,
      {bool isWarning = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isWarning ? Colors.orange.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _getProviderColor(String provider) {
    switch (provider) {
      case 'openai':
        return Colors.green.shade600;
      case 'anthropic':
        return Colors.orange.shade600;
      case 'deepseek':
        return Colors.blue.shade600;
      case 'ollama':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getProviderInitial(String provider) {
    switch (provider) {
      case 'openai':
        return 'O';
      case 'anthropic':
        return 'A';
      case 'deepseek':
        return 'D';
      case 'ollama':
        return 'L';
      default:
        return '?';
    }
  }

  void _handleModelAction(String action, ModelProfile profile) async {
    switch (action) {
      case 'edit':
        await _showEditModelDialog(profile);
        break;
      case 'setDefault':
        await ModelProfileService.instance.setDefaultProfileForTask(
          profile.uuid,
          profile.taskType,
        );
        ref.invalidate(modelProfilesProvider);
        break;
      case 'delete':
        final confirmed = await _showDeleteConfirmDialog(profile);
        if (confirmed == true) {
          await ModelProfileService.instance.deleteProfile(profile.uuid);
          ref.invalidate(modelProfilesProvider);
        }
        break;
    }
  }

  Future<void> _showAddModelDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ModelProfileDialog(),
    );
    if (result == true) {
      ref.invalidate(modelProfilesProvider);
    }
  }

  Future<void> _showEditModelDialog(ModelProfile profile) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModelProfileDialog(profile: profile),
    );
    if (result == true) {
      ref.invalidate(modelProfilesProvider);
    }
  }

  Future<bool?> _showDeleteConfirmDialog(ModelProfile profile) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除模型配置'),
        content: Text('确定要删除模型配置 "${profile.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 模型配置对话框
/// 用于添加或编辑模型配置
class ModelProfileDialog extends StatefulWidget {
  final ModelProfile? profile;

  const ModelProfileDialog({super.key, this.profile});

  @override
  State<ModelProfileDialog> createState() => _ModelProfileDialogState();
}

class _ModelProfileDialogState extends State<ModelProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _systemPromptController;

  late AIProvider _selectedProvider;
  late String _selectedModel;
  late AITask _selectedTask;
  late bool _isDefault;
  late double _temperature;
  late int _maxTokens;

  bool _isSaving = false;
  bool _showApiKey = false;

  bool get isEditing => widget.profile != null;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;

    _nameController = TextEditingController(text: profile?.name ?? '');
    _apiKeyController = TextEditingController();
    _baseUrlController = TextEditingController(text: profile?.baseUrl ?? '');
    _systemPromptController =
        TextEditingController(text: profile?.systemPrompt ?? '');

    _selectedProvider =
        AIProvider.fromId(profile?.provider ?? 'openai') ?? AIProvider.openai;
    _selectedModel = profile?.modelName ??
        ModelProfileService.getRecommendedModels(_selectedProvider).first;
    _selectedTask = profile?.taskType ?? AITask.writing;
    _isDefault = profile?.isDefault ?? false;
    _temperature = profile?.temperature ?? 0.7;
    _maxTokens = profile?.maxTokens ?? 4096;

    // 如果是编辑模式，设置默认 base URL
    if (profile == null) {
      _baseUrlController.text = _selectedProvider.defaultBaseUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            _buildHeader(),
            const Divider(height: 1),
            // 表单内容
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProviderSection(),
                      const SizedBox(height: 20),
                      _buildModelSection(),
                      const SizedBox(height: 20),
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildTaskSection(),
                      const SizedBox(height: 16),
                      _buildApiKeyField(),
                      const SizedBox(height: 16),
                      _buildBaseUrlField(),
                      const SizedBox(height: 20),
                      _buildParametersSection(),
                      const SizedBox(height: 20),
                      _buildSystemPromptField(),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // 操作按钮
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.smart_toy, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Text(
            isEditing ? '编辑模型配置' : '添加模型配置',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '提供商',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AIProvider.values.map((provider) {
            final isSelected = _selectedProvider == provider;
            return ChoiceChip(
              label: Text(provider.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedProvider = provider;
                    _selectedModel =
                        ModelProfileService.getRecommendedModels(provider)
                            .first;
                    _baseUrlController.text = provider.defaultBaseUrl;
                  });
                }
              },
              selectedColor: Colors.blue.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue.shade700 : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModelSection() {
    final models = ModelProfileService.getRecommendedModels(_selectedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '模型',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue:
              models.contains(_selectedModel) ? _selectedModel : models.first,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: models
              .map((model) => DropdownMenuItem(
                    value: model,
                    child: Text(model),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedModel = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: '配置名称 *',
        hintText: '例如：GPT-4o (写作)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入配置名称';
        }
        return null;
      },
    );
  }

  Widget _buildTaskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '任务类型',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AITask.values.map((task) {
            final isSelected = _selectedTask == task;
            return ChoiceChip(
              label: Text(_getTaskLabel(task)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTask = task;
                    // 自动填充系统提示词
                    if (_systemPromptController.text.isEmpty) {
                      _systemPromptController.text =
                          ModelProfileService.getDefaultSystemPrompt(task) ??
                              '';
                    }
                  });
                }
              },
              selectedColor: Colors.blue.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue.shade700 : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value ?? false;
                });
              },
            ),
            const Text('设为该任务的默认模型'),
          ],
        ),
      ],
    );
  }

  String _getTaskLabel(AITask task) {
    switch (task) {
      case AITask.writing:
        return '写作';
      case AITask.qa:
        return '问答';
      case AITask.translation:
        return '翻译';
      case AITask.summarization:
        return '摘要';
      case AITask.code:
        return '代码';
      case AITask.embedding:
        return '嵌入';
    }
  }

  Widget _buildApiKeyField() {
    final needsApiKey = _selectedProvider != AIProvider.ollama;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'API Key ${needsApiKey ? "*" : "(可选)"}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            if (isEditing)
              Text(
                '留空则保持原有密钥',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _apiKeyController,
          obscureText: !_showApiKey,
          decoration: InputDecoration(
            hintText: isEditing ? '输入新密钥或留空' : '输入 API Key',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _showApiKey = !_showApiKey;
                });
              },
            ),
          ),
          validator: (value) {
            if (!isEditing &&
                needsApiKey &&
                (value == null || value.trim().isEmpty)) {
              return '请输入 API Key';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBaseUrlField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'API 地址',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _baseUrlController,
          decoration: InputDecoration(
            hintText: _selectedProvider.defaultBaseUrl,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildParametersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '模型参数',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          // 温度
          Row(
            children: [
              const Text('温度'),
              const Spacer(),
              Text(
                _temperature.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
          Slider(
            value: _temperature,
            min: 0,
            max: 2,
            divisions: 20,
            onChanged: (value) {
              setState(() {
                _temperature = value;
              });
            },
          ),
          const SizedBox(height: 8),
          // 最大 Token
          Row(
            children: [
              const Text('最大 Token'),
              const Spacer(),
              Text(
                '$_maxTokens',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
          Slider(
            value: _maxTokens.toDouble(),
            min: 256,
            max: 32768,
            divisions: 32,
            onChanged: (value) {
              setState(() {
                _maxTokens = value.round();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemPromptField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '系统提示词',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                final defaultPrompt =
                    ModelProfileService.getDefaultSystemPrompt(_selectedTask);
                if (defaultPrompt != null) {
                  _systemPromptController.text = defaultPrompt;
                }
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('使用默认'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _systemPromptController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '输入系统提示词（可选）',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(isEditing ? '保存' : '添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final service = ModelProfileService.instance;

      if (isEditing) {
        // 更新现有配置
        await service.updateProfile(
          widget.profile!.uuid,
          UpdateModelProfileRequest(
            name: _nameController.text.trim(),
            provider: _selectedProvider.id,
            modelName: _selectedModel,
            apiKey: _apiKeyController.text.isNotEmpty
                ? _apiKeyController.text
                : null,
            baseUrl: _baseUrlController.text.trim().isNotEmpty
                ? _baseUrlController.text.trim()
                : null,
            taskType: _selectedTask,
            isDefault: _isDefault,
            temperature: _temperature,
            maxTokens: _maxTokens,
            systemPrompt: _systemPromptController.text.trim().isNotEmpty
                ? _systemPromptController.text.trim()
                : null,
          ),
        );
      } else {
        // 创建新配置
        await service.createProfile(
          CreateModelProfileRequest(
            name: _nameController.text.trim(),
            provider: _selectedProvider.id,
            modelName: _selectedModel,
            apiKey: _apiKeyController.text.isNotEmpty
                ? _apiKeyController.text
                : null,
            baseUrl: _baseUrlController.text.trim().isNotEmpty
                ? _baseUrlController.text.trim()
                : null,
            taskType: _selectedTask,
            isDefault: _isDefault,
            temperature: _temperature,
            maxTokens: _maxTokens,
            systemPrompt: _systemPromptController.text.trim().isNotEmpty
                ? _systemPromptController.text.trim()
                : null,
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
