import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';

enum SuperAdminAnalyticsPeriod { day, month, year, custom }

class SuperAdminDateFilterSelection {
  const SuperAdminDateFilterSelection({
    required this.period,
    required this.label,
    required this.range,
  });

  final SuperAdminAnalyticsPeriod period;
  final String label;
  final DateTimeRange range;
}

class SuperAdminDateFilter extends StatefulWidget {
  const SuperAdminDateFilter({
    super.key,
    this.initialSelection,
    required this.onChanged,
  });

  final SuperAdminDateFilterSelection? initialSelection;
  final ValueChanged<SuperAdminDateFilterSelection> onChanged;

  @override
  State<SuperAdminDateFilter> createState() => _SuperAdminDateFilterState();
}

class _SuperAdminDateFilterState extends State<SuperAdminDateFilter> {
  final _dateFormat = DateFormat('d MMM yyyy');
  late SuperAdminAnalyticsPeriod _period;
  late DateTime _day;
  late DateTime _month;
  late int _year;
  DateTimeRange? _customRange;
  int _weekOffset = 0;
  late int _monthStripYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initial = widget.initialSelection;
    _period = initial?.period ?? SuperAdminAnalyticsPeriod.day;
    _day = initial?.period == SuperAdminAnalyticsPeriod.day
      ? initial!.range.start
      : now;
    _month = initial?.range.start ?? DateTime(now.year, now.month);
    _year = initial?.range.start.year ?? now.year;
    _customRange = _period == SuperAdminAnalyticsPeriod.custom
        ? initial?.range
        : null;
    _monthStripYear = _month.year;
    final todayMonday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
    final selectedMonday = DateTime(_day.year, _day.month, _day.day)
      .subtract(Duration(days: _day.weekday - 1));
    _weekOffset = selectedMonday.difference(todayMonday).inDays ~/ 7;
  }

  SuperAdminDateFilterSelection get _selection {
    final range = _range;
    return SuperAdminDateFilterSelection(
      period: _period,
      label: _label,
      range: range,
    );
  }

  DateTimeRange get _range {
    switch (_period) {
      case SuperAdminAnalyticsPeriod.day:
        final start = DateTime(_day.year, _day.month, _day.day);
        return DateTimeRange(start: start, end: start.add(const Duration(days: 1)));
      case SuperAdminAnalyticsPeriod.month:
        final start = DateTime(_month.year, _month.month);
        return DateTimeRange(start: start, end: DateTime(start.year, start.month + 1));
      case SuperAdminAnalyticsPeriod.year:
        return DateTimeRange(start: DateTime(_year), end: DateTime(_year + 1));
      case SuperAdminAnalyticsPeriod.custom:
        return _customRange ??
            DateTimeRange(start: DateTime.now(), end: DateTime.now().add(const Duration(days: 1)));
    }
  }

  String get _label {
    switch (_period) {
      case SuperAdminAnalyticsPeriod.day:
        return _dateFormat.format(_day);
      case SuperAdminAnalyticsPeriod.month:
        return DateFormat('MMMM yyyy').format(_month);
      case SuperAdminAnalyticsPeriod.year:
        return '$_year';
      case SuperAdminAnalyticsPeriod.custom:
        if (_customRange == null) return 'Choose a range';
        return '${_dateFormat.format(_customRange!.start)} - ${_dateFormat.format(_customRange!.end.subtract(const Duration(days: 1)))}';
    }
  }

  void _setPeriod(SuperAdminAnalyticsPeriod period) {
    if (period == SuperAdminAnalyticsPeriod.custom) {
      _chooseCustomRange();
      return;
    }
    setState(() => _period = period);
    widget.onChanged(_selection);
  }

  Future<void> _chooseCustomRange() async {
    final chosen = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDateRange: _customRange,
      helpText: 'Select analytics range',
      saveText: 'Apply',
    );
    if (chosen == null || !mounted) return;
    final start = DateTime(chosen.start.year, chosen.start.month, chosen.start.day);
    final end = DateTime(chosen.end.year, chosen.end.month, chosen.end.day).add(const Duration(days: 1));
    if (start.isAfter(end)) return;
    setState(() {
      _period = SuperAdminAnalyticsPeriod.custom;
      _customRange = DateTimeRange(start: start, end: end);
    });
    widget.onChanged(_selection);
  }

  void _clearCustomRange() {
    setState(() {
      _period = SuperAdminAnalyticsPeriod.day;
      _customRange = null;
      _day = DateTime.now();
    });
    widget.onChanged(_selection);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: SuperAdminAnalyticsPeriod.values.map((period) {
                  final selected = _period == period;
                  final label = switch (period) {
                    SuperAdminAnalyticsPeriod.day => 'Day',
                    SuperAdminAnalyticsPeriod.month => 'Month',
                    SuperAdminAnalyticsPeriod.year => 'Year',
                    SuperAdminAnalyticsPeriod.custom => 'Custom Range',
                  };
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary),
                      onSelected: (_) => _setPeriod(period),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        if (_period == SuperAdminAnalyticsPeriod.day) _dayStrip(),
        if (_period == SuperAdminAnalyticsPeriod.month) _monthStrip(),
        if (_period == SuperAdminAnalyticsPeriod.year) _yearStrip(),
        if (_period == SuperAdminAnalyticsPeriod.custom && _customRange != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearCustomRange,
              icon: const Icon(Icons.clear),
              label: const Text('Clear selection'),
            ),
          ),
      ],
    );
  }

  Widget _dayStrip() {
    final today = DateTime.now();
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1))
        .add(Duration(days: _weekOffset * 7));
    return _stripCard(
      leading: IconButton(
        onPressed: () => setState(() => _weekOffset--),
        icon: const Icon(Icons.chevron_left),
      ),
      trailing: IconButton(
        onPressed: () => setState(() => _weekOffset++),
        icon: const Icon(Icons.chevron_right),
      ),
      children: [
        for (var i = 0; i < 7; i++)
          _pill(
            DateFormat('EEE\nd').format(monday.add(Duration(days: i))),
            _day.year == monday.add(Duration(days: i)).year &&
                _day.month == monday.add(Duration(days: i)).month &&
                _day.day == monday.add(Duration(days: i)).day,
            () {
              setState(() {
                _period = SuperAdminAnalyticsPeriod.day;
                _day = monday.add(Duration(days: i));
              });
              widget.onChanged(_selection);
            },
          ),
      ],
    );
  }

  Widget _monthStrip() => _stripCard(
        leading: IconButton(
          onPressed: _monthStripYear > 2026
              ? () => setState(() => _monthStripYear--)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        trailing: IconButton(
          onPressed: _monthStripYear < DateTime.now().year
              ? () => setState(() => _monthStripYear++)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
        children: [
          for (var month = 1; month <= 12; month++)
            _pill(
              DateFormat('MMM').format(DateTime(_monthStripYear, month)),
              _month.year == _monthStripYear && _month.month == month,
              () {
                setState(() {
                  _period = SuperAdminAnalyticsPeriod.month;
                  _month = DateTime(_monthStripYear, month);
                });
                widget.onChanged(_selection);
              },
            ),
        ],
      );

  Widget _yearStrip() => _stripCard(
        children: [
          for (var year = 2026; year <= DateTime.now().year; year++)
            _pill(' $year ', _year == year, () {
              setState(() {
                _period = SuperAdminAnalyticsPeriod.year;
                _year = year;
              });
              widget.onChanged(_selection);
            }),
        ],
      );

  Widget _stripCard({
    Widget? leading,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Card(
      child: Row(
        children: [
          if (leading != null) leading,
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: children),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _pill(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 58,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.bgSubtle,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
