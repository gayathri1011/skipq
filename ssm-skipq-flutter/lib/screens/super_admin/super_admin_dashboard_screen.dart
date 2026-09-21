import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/feedback.dart';
import '../../models/order.dart';
import '../../models/super_admin.dart';
import '../../services/feedback_service.dart';
import '../../services/menu_service.dart';
import '../../services/orders_service.dart';
import '../../services/super_admin_service.dart';
import 'super_admin_analytics_detail_screen.dart';
import 'super_admin_date_filter.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({
    super.key,
    required this.ordersService,
    required this.feedbackService,
    required this.superAdminService,
    required this.menuService,
  });

  final OrdersService ordersService;
  final FeedbackService feedbackService;
  final SuperAdminService superAdminService;
  final MenuService menuService;

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

enum _AdminPeriod { day, month, year, custom }

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  final _dateFormat = DateFormat('d MMM yyyy');
  List<Order> _orders = [];
  List<OrderFeedback> _feedback = [];
  List<ManagedManager> _managers = [];
  _AdminPeriod _period = _AdminPeriod.day;
  DateTime _day = DateTime.now();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _year = DateTime.now().year;
  int _weekOffset = 0;
  DateTimeRange? _customRange;
  bool _loading = true;
  String? _error;
  final Set<String> _visibleManagerPasswords = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.superAdminService.fetchOrders(),
        widget.superAdminService.fetchFeedback(),
        widget.superAdminService.fetchManagers(),
      ]);
      _orders = results[0] as List<Order>;
      _feedback = results[1] as List<OrderFeedback>;
      _managers = results[2] as List<ManagedManager>;
    } catch (_) {
      _error = 'Unable to load Super Admin data.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTimeRange get _range {
    switch (_period) {
      case _AdminPeriod.day:
        final start = DateTime(_day.year, _day.month, _day.day);
        return DateTimeRange(
            start: start, end: start.add(const Duration(days: 1)));
      case _AdminPeriod.month:
        return DateTimeRange(
            start: DateTime(_month.year, _month.month),
            end: DateTime(_month.year, _month.month + 1));
      case _AdminPeriod.year:
        return DateTimeRange(start: DateTime(_year), end: DateTime(_year + 1));
      case _AdminPeriod.custom:
        return _customRange ??
            DateTimeRange(
                start: DateTime.now(),
                end: DateTime.now().add(const Duration(days: 1)));
    }
  }

  List<Order> get _periodOrders => _orders
      .where((order) =>
          !order.createdAt.isBefore(_range.start) &&
          order.createdAt.isBefore(_range.end))
      .toList();
  List<OrderFeedback> get _periodFeedback => _feedback
      .where((entry) =>
          !entry.createdAt.isBefore(_range.start) &&
          entry.createdAt.isBefore(_range.end))
      .toList();

  @override
  Widget build(BuildContext context) {
    final orders = _periodOrders;
    final feedback = _periodFeedback;
    final average = feedback.isEmpty
        ? 0.0
        : feedback.fold<int>(0, (sum, item) => sum + item.rating) /
            feedback.length;
    final completedOrders =
        orders.where((order) => order.status == OrderStatus.pickedUp).toList();
    final revenue =
        completedOrders.fold<num>(0, (sum, order) => sum + order.total);
    final cancelledOrders =
        orders.where((order) => order.status == OrderStatus.cancelled).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('SkipQ@SSM',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
          const Text('Super Admin Portal',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 18),
          _periodSelector(),
          if (_period == _AdminPeriod.day) _dayStrip(),
          if (_period == _AdminPeriod.month) _monthStrip(),
          if (_period == _AdminPeriod.year) _yearStrip(),
          if (_period == _AdminPeriod.custom && _customRange != null)
            Text(
                '${_dateFormat.format(_range.start)} - ${_dateFormat.format(_range.end.subtract(const Duration(days: 1)))}'),
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error))
          else ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.18,
              children: [
                _summaryCard('Order Analytics', '${orders.length}',
                    Icons.receipt_long_outlined, 'Order Analytics'),
                _summaryCard(
                    'Feedback Analytics',
                    '${average.toStringAsFixed(1)} / 5',
                    Icons.star_outline,
                    'Feedback Analytics'),
                _summaryCard('Revenue Analytics', '₹$revenue',
                    Icons.payments_outlined, 'Revenue Analytics'),
                _summaryCard('Cancellation Analytics', '$cancelledOrders',
                    Icons.cancel_outlined, 'Cancellation Analytics'),
              ],
            ),
            const SizedBox(height: 22),
            _managerSection(),
          ],
        ],
      ),
    );
  }

  Widget _periodSelector() {
    const labels = ['Day', 'Month', 'Year', 'Custom Range'];
    final periods = _AdminPeriod.values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(periods.length, (index) {
          final selected = _period == periods[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[index]),
              selected: selected,
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                  color: selected ? Colors.white : AppTheme.textSecondary),
              onSelected: (_) => _selectPeriod(periods[index]),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _selectPeriod(_AdminPeriod period) async {
    if (period != _AdminPeriod.custom) {
      setState(() => _period = period);
      return;
    }
    final chosen = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDateRange: _customRange,
      saveText: 'Apply',
    );
    if (chosen != null && mounted) {
      setState(() {
        _period = period;
        _customRange = DateTimeRange(
          start:
              DateTime(chosen.start.year, chosen.start.month, chosen.start.day),
          end: DateTime(chosen.end.year, chosen.end.month, chosen.end.day)
              .add(const Duration(days: 1)),
        );
      });
    }
  }

  Widget _dayStrip() {
    final monday = _day.subtract(Duration(days: _day.weekday - 1));
    return _stripCard([
      for (var i = 0; i < 7; i++)
        _pill(
            DateFormat('EEE').format(monday.add(Duration(days: i))),
            _day.day == monday.add(Duration(days: i)).day,
            () => setState(() => _day = monday.add(Duration(days: i)))),
    ]);
  }

  Widget _monthStrip() => _stripCard([
        for (var i = 1; i <= 12; i++)
          _pill(
              DateFormat('MMM').format(DateTime(_month.year, i)),
              _month.month == i,
              () => setState(() => _month = DateTime(_month.year, i)))
      ], arrows: true);
  Widget _yearStrip() => _stripCard([
        for (var year = 2026; year <= DateTime.now().year; year++)
          _pill('$year', _year == year, () => setState(() => _year = year))
      ]);

  Widget _stripCard(List<Widget> children, {bool arrows = false}) {
    return Card(
      child: Row(
        children: [
          if (arrows)
            IconButton(
                onPressed: () => setState(() => _weekOffset--),
                icon: const Icon(Icons.chevron_left)),
          Expanded(
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: children))),
          if (arrows)
            IconButton(
                onPressed: () => setState(() => _weekOffset++),
                icon: const Icon(Icons.chevron_right)),
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
              borderRadius: BorderRadius.circular(12)),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _summaryCard(
          String label, String value, IconData icon, String detailTitle) =>
      Card(
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SuperAdminAnalyticsDetailScreen(
                title: detailTitle,
                filter: SuperAdminDateFilterSelection(
                  period: SuperAdminAnalyticsPeriod.values[_period.index],
                  label: _filterValue,
                  range: _range,
                ),
                ordersService: widget.ordersService,
                menuService: widget.menuService,
                feedbackService: widget.feedbackService,
                superAdminService: widget.superAdminService,
              ),
            ),
          ),
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: AppTheme.primary),
                    const SizedBox(height: 10),
                    Text(label,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800)),
                    const Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.chevron_right,
                            color: AppTheme.textMuted))
                  ])),
        ),
      );

  String get _filterValue {
    switch (_period) {
      case _AdminPeriod.day:
        return _dateFormat.format(_day);
      case _AdminPeriod.month:
        return DateFormat('MMMM yyyy').format(_month);
      case _AdminPeriod.year:
        return '$_year';
      case _AdminPeriod.custom:
        return _customRange == null
            ? 'Choose a range'
            : '${_dateFormat.format(_range.start)} - ${_dateFormat.format(_range.end.subtract(const Duration(days: 1)))}';
    }
  }

  Widget _managerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Manager Management',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ..._managers.map(_managerCard),
        const SizedBox(height: 8),
        OutlinedButton.icon(
            onPressed: _showAddManager,
            icon: const Icon(Icons.add),
            label: const Text('Add Manager')),
      ],
    );
  }

  Widget _managerCard(ManagedManager manager) {
    final visible = _visibleManagerPasswords.contains(manager.id);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
            backgroundColor: AppTheme.primaryMuted,
            child: Icon(Icons.person_outline, color: AppTheme.primary)),
        title: Text(manager.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
            '${manager.managerId}  •  ${visible ? (manager.passwordPlain ?? 'Password unavailable') : manager.passwordMasked}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: visible ? 'Hide password' : 'Show password',
              icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() {
                if (visible) {
                  _visibleManagerPasswords.remove(manager.id);
                } else {
                  _visibleManagerPasswords.add(manager.id);
                }
              }),
            ),
            IconButton(
              tooltip: 'Delete manager',
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              onPressed: () => _confirmDeleteManager(manager),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteManager(ManagedManager manager) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Remove this manager?'),
          content: const Text('They will no longer be able to log in.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                setDialogState(() {});
                try {
                  await widget.superAdminService.deleteManager(manager.id);
                  if (!mounted) return;
                  setState(() {
                    _managers = _managers
                        .where((item) => item.id != manager.id)
                        .toList();
                    _visibleManagerPasswords.remove(manager.id);
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Manager deleted')),
                  );
                } catch (_) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                          content: Text('Unable to remove manager.')),
                    );
                  }
                }
              },
              child: const Text('Remove'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddManager() async {
    final manager = await showDialog<ManagedManager>(
      context: context,
      builder: (_) => _CreateManagerDialog(
        superAdminService: widget.superAdminService,
      ),
    );
    if (!mounted || manager == null) return;
    setState(() => _managers = [..._managers, manager]);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manager created')),
    );
  }
}

class _CreateManagerDialog extends StatefulWidget {
  const _CreateManagerDialog({required this.superAdminService});

  final SuperAdminService superAdminService;

  @override
  State<_CreateManagerDialog> createState() => _CreateManagerDialogState();
}

class _CreateManagerDialogState extends State<_CreateManagerDialog> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _submitting = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _idController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final manager = await widget.superAdminService.createManager(
        name: _nameController.text,
        managerId: _idController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, manager);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Unable to create manager. Check the ID and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Manager'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Manager Name'),
          ),
          TextField(
            controller: _idController,
            decoration: const InputDecoration(labelText: 'Manager ID'),
          ),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Hide password' : 'Show password',
                icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Manager'),
        ),
      ],
    );
  }
}
