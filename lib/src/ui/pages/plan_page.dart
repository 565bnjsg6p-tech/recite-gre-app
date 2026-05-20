import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_preferences.dart';
import '../../data/app_store.dart';
import '../../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_card.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  final _dailyNewController = TextEditingController();
  DateTime? _examDate;
  bool _isLoading = true;
  bool _isSaving = false;
  String _message = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _loadPlan();
    }
  }

  @override
  void dispose() {
    _dailyNewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return PageScaffold(
      title: '背诵计划',
      subtitle: '目标、节奏和长期学习曲线',
      children: [
        SectionCard(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '计划设置',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 620;
                        final fields = [
                          _NumberField(
                            controller: _dailyNewController,
                            label: '每日新词',
                            icon: Icons.add_task_rounded,
                          ),
                          const _SystemReviewPlanNote(),
                        ];
                        return isWide
                            ? Row(
                                children: [
                                  for (final field in fields) ...[
                                    Expanded(child: field),
                                    if (field != fields.last)
                                      const SizedBox(width: 12),
                                  ],
                                ],
                              )
                            : Column(
                                children: [
                                  for (final field in fields) ...[
                                    field,
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 12),
                    _ExamDatePicker(
                      value: _examDate,
                      onPick: _pickExamDate,
                      onClear: () => setState(() => _examDate = null),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : () => _savePlan(store),
                        icon: const Icon(Icons.save_rounded),
                        label: Text(_isSaving ? '保存中' : '保存计划'),
                      ),
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _message,
                        style: const TextStyle(color: ReciteColors.muted),
                      ),
                    ],
                  ],
                ),
        ),
        const _StudyDashboardSection(),
        StreamBuilder<List<StudyActivityPoint>>(
          stream: store.watchStudyActivity(days: 45),
          builder: (context, snapshot) {
            final points = snapshot.data ?? const <StudyActivityPoint>[];
            return SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '45 天学习曲线',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const _LegendDot(color: ReciteColors.blue, label: '新增'),
                      const SizedBox(width: 10),
                      const _LegendDot(color: ReciteColors.teal, label: '复习'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: points.isEmpty
                        ? const Center(child: Text('暂无学习记录。'))
                        : CustomPaint(
                            painter: _ActivityChartPainter(points),
                            child: const SizedBox.expand(),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '复习规则',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const _RuleItem('不认识', '立即回到到期队列，难度系数下降，间隔重置。', ReciteColors.red),
              const _RuleItem(
                '模糊',
                '通常安排到明天，难度轻微下降，保持学习中。',
                ReciteColors.orange,
              ),
              const _RuleItem(
                '认识',
                '使用简化 SM-2：1 天、6 天，然后按难度系数逐步拉长。',
                ReciteColors.teal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadPlan() async {
    final plan = await AppScope.of(context).getStudyPlan();
    if (!mounted) {
      return;
    }
    setState(() {
      _dailyNewController.text = plan.dailyNewWords.toString();
      _examDate = _parsePlanDate(plan.examDateLabel);
      _isLoading = false;
    });
  }

  Future<void> _pickExamDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fallback = DateTime(now.year, now.month, now.day + 90);
    final initial = _examDate == null || _examDate!.isBefore(today)
        ? fallback
        : _examDate!;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _examDate = picked);
    }
  }

  Future<void> _savePlan(AppStore store) async {
    final dailyNew = int.tryParse(_dailyNewController.text.trim()) ?? 30;
    setState(() {
      _isSaving = true;
      _message = '';
    });
    await store.saveStudyPlan(dailyNewWords: dailyNew, examDate: _examDate);
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
      _dailyNewController.text = dailyNew
          .clamp(1, AppPreferences.maxDailyNewWords)
          .toString();
      _message = '计划已保存，后续会纳入云端同步。';
    });
  }

  DateTime? _parsePlanDate(String label) {
    final parts = label.split('.');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

class _StudyDashboardSection extends StatelessWidget {
  const _StudyDashboardSection();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return StreamBuilder<StudyDashboard>(
      stream: store.watchStudyDashboard(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '学习仪表盘',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 980
                      ? 3
                      : constraints.maxWidth >= 640
                      ? 2
                      : 1;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _DashboardMetric(
                        width: _metricWidth(constraints.maxWidth, columns),
                        icon: Icons.local_fire_department_rounded,
                        color: ReciteColors.orange,
                        label: '连续学习',
                        value: '${data?.streakDays ?? 0} 天',
                        caption: '任意新增或复习都会延续。',
                      ),
                      _DashboardMetric(
                        width: _metricWidth(constraints.maxWidth, columns),
                        icon: Icons.insights_rounded,
                        color: ReciteColors.teal,
                        label: '7 天活跃',
                        value: _percent(data?.activeRate7 ?? 0),
                        caption: '近 7 天有学习记录的比例。',
                      ),
                      _DashboardMetric(
                        width: _metricWidth(constraints.maxWidth, columns),
                        icon: Icons.calendar_month_rounded,
                        color: ReciteColors.blue,
                        label: '30 天活跃',
                        value: _percent(data?.activeRate30 ?? 0),
                        caption: '长期节奏是否稳定。',
                      ),
                      _DashboardMetric(
                        width: _metricWidth(constraints.maxWidth, columns),
                        icon: Icons.event_repeat_rounded,
                        color: ReciteColors.blue,
                        label: '明日预计复习',
                        value: '${data?.tomorrowReviewWords ?? 0}',
                        caption: '由系统间隔重复自动计算。',
                      ),
                      _DashboardMetric(
                        width: _metricWidth(constraints.maxWidth, columns),
                        icon: Icons.priority_high_rounded,
                        color: ReciteColors.red,
                        label: '困难词',
                        value: '${data?.difficultWords ?? 0}',
                        caption: '遗忘、低难度系数或学习中反复出错。',
                      ),
                      _DashboardMetric(
                        width: _metricWidth(constraints.maxWidth, columns),
                        icon: Icons.library_books_rounded,
                        color: ReciteColors.teal,
                        label: '可学习词',
                        value: '${data?.reviewableWords ?? 0}',
                        caption: '已补全且可进入学习/复习的词。',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  double _metricWidth(double maxWidth, int columns) {
    final spacing = 12 * (columns - 1);
    return (maxWidth - spacing) / columns;
  }

  String _percent(double value) {
    return '${(value * 100).round()}%';
  }
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.width,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.caption,
  });

  final double width;
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(color: ReciteColors.muted)),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(caption, style: const TextStyle(color: ReciteColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemReviewPlanNote extends StatelessWidget {
  const _SystemReviewPlanNote();

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '系统复习计划',
        prefixIcon: Icon(Icons.repeat_on_rounded),
      ),
      child: const Text(
        '由到期日、熟练度、遗忘次数和间隔重复算法自动生成',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ExamDatePicker extends StatelessWidget {
  const _ExamDatePicker({
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.flag_rounded),
            label: Text(
              value == null ? '设置目标考试日期' : '考试日期：${_formatDate(value!)}',
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: '清除日期',
          onPressed: value == null ? null : onClear,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}.$month.$day';
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: ReciteColors.muted)),
      ],
    );
  }
}

class _ActivityChartPainter extends CustomPainter {
  const _ActivityChartPainter(this.points);

  final List<StudyActivityPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(32, 8, size.width - 40, size.height - 34);
    final gridPaint = Paint()
      ..color = ReciteColors.line
      ..strokeWidth = 1;
    final labelPaint = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );
    final maxValue = math.max(
      1,
      points.fold<int>(
        0,
        (max, point) =>
            math.max(max, math.max(point.addedWords, point.reviewedWords)),
      ),
    );

    for (var i = 0; i <= 4; i++) {
      final y = chart.bottom - chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      labelPaint.text = TextSpan(
        text: (maxValue * i / 4).round().toString(),
        style: const TextStyle(fontSize: 10, color: ReciteColors.muted),
      );
      labelPaint.layout(maxWidth: 28);
      labelPaint.paint(canvas, Offset(0, y - 7));
    }

    _drawLine(canvas, chart, maxValue, ReciteColors.blue, (p) => p.addedWords);
    _drawLine(
      canvas,
      chart,
      maxValue,
      ReciteColors.teal,
      (p) => p.reviewedWords,
    );
  }

  void _drawLine(
    Canvas canvas,
    Rect chart,
    int maxValue,
    Color color,
    int Function(StudyActivityPoint point) readValue,
  ) {
    if (points.isEmpty) {
      return;
    }
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? chart.left
          : chart.left + chart.width * i / (points.length - 1);
      final y = chart.bottom - chart.height * readValue(points[i]) / maxValue;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    final step = math.max(1, points.length ~/ 8);
    for (var i = 0; i < points.length; i += step) {
      final x = points.length == 1
          ? chart.left
          : chart.left + chart.width * i / (points.length - 1);
      final y = chart.bottom - chart.height * readValue(points[i]) / maxValue;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _RuleItem extends StatelessWidget {
  const _RuleItem(this.rating, this.effect, this.color);

  final String rating;
  final String effect;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$rating：',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: effect),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
