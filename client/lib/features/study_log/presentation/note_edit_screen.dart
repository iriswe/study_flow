import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'study_log_provider.dart';
import '../../tasks/presentation/tasks_provider.dart';
import '../../goals/presentation/goals_provider.dart';
import '../../../core/di/injection.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/toast.dart';
import '../data/study_log_repository.dart';

class NoteEditScreen extends ConsumerStatefulWidget {
  final String? logId;

  const NoteEditScreen({super.key, this.logId});

  bool get isEditMode => logId != null;

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  late QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '45');
  final _problemController = TextEditingController();
  String _selectedScore = '理解';
  bool _isLoading = false;
  bool _dataLoaded = false;
  int? _selectedGoalId;
  int? _selectedTaskId;
  int? _currentLogId; // for update mode
  final ImagePicker _imagePicker = ImagePicker();

  // Map Chinese labels to backend enum values
  static const Map<String, String> _scoreMap = {
    '不理解': 'UNDERSAND',
    '模糊': 'FUZZY',
    '理解': 'UNDERSTAND',
    '精通': 'MASTERY',
  };

  // Reverse map for loading
  static const Map<String, String> _reverseScoreMap = {
    'UNDERSAND': '不理解',
    'FUZZY': '模糊',
    'UNDERSTAND': '理解',
    'MASTERY': '精通',
  };

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    _quillController.addListener(_onContentChanged);
    if (widget.logId != null) {
      _loadExistingLog();
    } else {
      // Load tasks/goals for new mode
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tasksProvider.notifier).loadTasks();
        ref.read(goalsProvider.notifier).loadGoals();
      });
    }
  }

  void _onContentChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _insertImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (!mounted) return;
      ToastWidget.show(context, '正在上传图片...', type: 'info');

      final apiClient = getIt<ApiClient>();
      final imageUrl = await apiClient.uploadImage(image.path);

      if (!mounted) return;

      // Insert image embed into Quill document
      final index = _quillController.selection.baseOffset;
      _quillController.document.insert(index, BlockEmbed.image(imageUrl));
      _quillController.document.insert(index + 1, '\n');

      ToastWidget.show(context, '图片插入成功', type: 'success');
    } catch (e) {
      if (mounted) {
        ToastWidget.show(context, '图片上传失败', type: 'error');
      }
    }
  }

  void _onGoalChanged(int? goalId) {
    setState(() {
      _selectedGoalId = goalId;
      _selectedTaskId = null; // Reset task when goal changes
    });
    if (goalId != null) {
      ref.read(tasksProvider.notifier).loadTasksByGoalId(goalId);
    } else {
      ref.read(tasksProvider.notifier).loadTasks();
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    _editorFocusNode.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _durationController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  void _initializeForEdit(Map<String, dynamic> logData) {
    if (_dataLoaded) return;
    _dataLoaded = true;

    final goalId = logData['goalId'] as int?;
    final taskId = logData['taskId'] as int?;
    final duration = logData['duration'] as int?;
    final score = logData['score'] as String?;
    final problem = logData['problem'] as String?;
    final note = logData['note'] as String?;

    if (goalId != null) _selectedGoalId = goalId;
    if (taskId != null) _selectedTaskId = taskId;

    // Load tasks for the selected goal
    if (goalId != null) {
      ref.read(tasksProvider.notifier).loadTasksByGoalId(goalId);
    } else {
      ref.read(tasksProvider.notifier).loadTasks();
    }
    if (duration != null) _durationController.text = duration.toString();
    if (problem != null) _problemController.text = problem;

    // Map backend score to Chinese label
    if (score != null) {
      _selectedScore = _reverseScoreMap[score] ?? '理解';
    }

    // Load note content into Quill
    if (note != null && note.isNotEmpty) {
      try {
        _quillController.document = Document.fromJson([
          {'insert': '$note\n'}
        ]);
      } catch (_) {
        _quillController.document = Document()..insert(0, note);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final documentLength = _quillController.document.toPlainText().length;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.surface,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: () => context.go('/study-log'),
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEditMode ? '编辑笔记' : '新建笔记',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      if (widget.isEditMode && _titleController.text.isNotEmpty)
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: '笔记标题...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: _isLoading ? null : _saveNote,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.isEditMode ? '更新' : '保存'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: Row(
              children: [
                // Meta panel
                Container(
                  width: 260,
                  color: AppTheme.surface,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormGroup('关联目标', [
                          Consumer(
                            builder: (context, ref, _) {
                              final goalsState = ref.watch(goalsProvider);
                              return DropdownButtonFormField<int>(
                                value: _selectedGoalId,
                                decoration: const InputDecoration(
                                  hintText: '选择目标（可选）',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('无关联目标')),
                                  ...goalsState.goals.map((g) => DropdownMenuItem(value: g.id, child: Text(g.title))),
                                ],
                                onChanged: (v) => _onGoalChanged(v),
                              );
                            },
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _buildFormGroup('关联任务 *', [
                          Consumer(
                            builder: (context, ref, _) {
                              final tasksState = ref.watch(tasksProvider);
                              return DropdownButtonFormField<int>(
                                value: _selectedTaskId,
                                decoration: const InputDecoration(
                                  hintText: '请选择任务（必填）',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('请选择任务')),
                                  ...tasksState.tasks.map((t) => DropdownMenuItem(value: t.id, child: Text(t.title))),
                                ],
                                onChanged: (v) => setState(() => _selectedTaskId = v),
                              );
                            },
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _buildFormGroup('学习时长（分钟）', [
                          TextField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '45',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _buildFormGroup('理解程度', [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['不理解', '模糊', '理解', '精通'].map((s) => ChoiceChip(
                              label: Text(s),
                              selected: _selectedScore == s,
                              onSelected: (_) => setState(() => _selectedScore = s),
                              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                fontSize: 13,
                                color: _selectedScore == s ? AppTheme.primary : AppTheme.textSecondary,
                              ),
                            )).toList(),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _buildFormGroup('难点记录', [
                          TextField(
                            controller: _problemController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: '记录学习过程中的难点和疑问...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                // Editor panel
                Expanded(
                  child: Container(
                    color: AppTheme.surface,
                    child: Column(
                      children: [
                        // Quill toolbar
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bg2,
                            border: Border(bottom: BorderSide(color: AppTheme.border)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: QuillSimpleToolbar(
                                  controller: _quillController,
                                  configurations: QuillSimpleToolbarConfigurations(
                                    showFontFamily: false,
                                    showFontSize: true,
                                    showSearchButton: false,
                                    showSubscript: false,
                                    showSuperscript: false,
                                    showInlineCode: false,
                                    showCodeBlock: false,
                                    showColorButton: false,
                                    showBackgroundColorButton: false,
                                    showClearFormat: false,
                                    showHeaderStyle: true,
                                    showBoldButton: true,
                                    showItalicButton: true,
                                    showUnderLineButton: true,
                                    showStrikeThrough: false,
                                    showListNumbers: true,
                                    showListBullets: true,
                                    showListCheck: false,
                                    showQuote: true,
                                    showIndent: true,
                                    showLink: true,
                                    showUndo: true,
                                    showRedo: true,
                                    showDirection: false,
                                    showAlignmentButtons: false,
                                    showDividers: true,
                                    multiRowsDisplay: false,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.image, size: 20),
                                onPressed: _isLoading ? null : _insertImage,
                                tooltip: '插入图片',
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        // Quill editor
                        Expanded(
                          child: Container(
                            color: AppTheme.surface,
                            padding: const EdgeInsets.all(16),
                            child: QuillEditor.basic(
                              controller: _quillController,
                              focusNode: _editorFocusNode,
                              scrollController: _scrollController,
                              configurations: QuillEditorConfigurations(
                                placeholder: '开始记录你的学习笔记...',
                                padding: EdgeInsets.zero,
                                expands: true,
                                autoFocus: false,
                                scrollable: true,
                              ),
                            ),
                          ),
                        ),
                        // Char count
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          color: AppTheme.bg2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '$documentLength 字符',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormGroup(String label, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Future<void> _loadExistingLog() async {
    final id = int.tryParse(widget.logId ?? '');
    if (id == null) {
      _dataLoaded = true;
      return;
    }

    _currentLogId = id;

    // Load tasks/goals for the dropdowns in edit mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksProvider.notifier).loadTasks();
      ref.read(goalsProvider.notifier).loadGoals();
    });

    setState(() => _isLoading = true);
    try {
      final logData = await _fetchLog(id);
      if (logData != null && mounted) {
        _initializeForEdit(logData);
      } else if (mounted) {
        ToastWidget.show(context, '笔记不存在', type: 'error');
        if (mounted) context.go('/study-log');
      }
    } catch (e) {
      if (mounted) {
        ToastWidget.show(context, '加载笔记失败', type: 'error');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchLog(int id) async {
    // Always fetch from backend to get complete data (taskId, goalId, etc.)
    final repo = getIt<StudyLogRepository>();
    final data = await repo.getStudyLog(id);
    if (data != null) return data;
    // Fallback: check provider state
    final state = ref.read(studyLogProvider);
    final log = state.logs.where((l) => l.id == id).firstOrNull;
    if (log != null) {
      return {
        'id': log.id,
        'goalId': log.goalId,
        'taskId': null,
        'duration': log.duration,
        'note': log.note,
        'score': null,
        'problem': null,
        'taskTitle': log.goalTitle,
      };
    }
    return null;
  }

  Future<void> _saveNote() async {
    if (_selectedTaskId == null) {
      ToastWidget.show(context, '请先选择关联任务', type: 'error');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final content = _quillController.document.toPlainText();
      final duration = int.tryParse(_durationController.text) ?? 45;
      final score = _scoreMap[_selectedScore] ?? 'UNDERSTAND';

      bool success;
      if (widget.isEditMode && _currentLogId != null) {
        // Update existing log
        success = await ref.read(studyLogProvider.notifier).updateLog(
          _currentLogId!,
          taskId: _selectedTaskId,
          duration: duration,
          note: content.isNotEmpty ? content : null,
          score: score,
          problem: _problemController.text.isNotEmpty ? _problemController.text : null,
        );
      } else {
        // Create new log
        success = await ref.read(studyLogProvider.notifier).createLog(
          goalId: _selectedGoalId,
          taskId: _selectedTaskId,
          duration: duration,
          note: content.isNotEmpty ? content : null,
          score: score,
          problem: _problemController.text.isNotEmpty ? _problemController.text : null,
        );
      }

      if (mounted) {
        if (success) {
          ToastWidget.show(context, widget.isEditMode ? '笔记更新成功' : '笔记保存成功', type: 'success');
          context.go('/study-log');
        } else {
          ToastWidget.show(context, '保存失败', type: 'error');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastWidget.show(context, '保存失败: $e', type: 'error');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
