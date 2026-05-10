import 'package:flutter/material.dart';

// ── Result model ──────────────────────────────────────────────────────────────

class LapanganFilterResult {
  final DateTime? selectedDate; // null = flexible / no date filter
  final String? selectedTimeRange; // null = all times  e.g. "06-10"

  const LapanganFilterResult({
    this.selectedDate,
    this.selectedTimeRange,
  });

  bool get hasActiveFilter => selectedDate != null || selectedTimeRange != null;
}

// ── Internal time option model ────────────────────────────────────────────────

class _TimeOption {
  final String label;
  final String sublabel;
  final IconData icon;

  const _TimeOption({
    required this.label,
    required this.sublabel,
    required this.icon,
  });
}

// ── Main widget ───────────────────────────────────────────────────────────────

class LapanganFilterSheet extends StatefulWidget {
  final LapanganFilterResult? initialFilter;

  const LapanganFilterSheet({super.key, this.initialFilter});

  /// Show the bottom sheet and return the user's filter choice.
  static Future<LapanganFilterResult?> show(
    BuildContext context, {
    LapanganFilterResult? initialFilter,
  }) {
    return showModalBottomSheet<LapanganFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LapanganFilterSheet(initialFilter: initialFilter),
    );
  }

  @override
  State<LapanganFilterSheet> createState() => _LapanganFilterSheetState();
}

class _LapanganFilterSheetState extends State<LapanganFilterSheet>
    with SingleTickerProviderStateMixin {
  // ── Tab controller ────────────────────────────────────────────
  late TabController _tabController;
  final List<String> _tabs = ['Activity Date', 'Activity Time'];

  // ── Date state ────────────────────────────────────────────────
  bool _isFlexible = true;
  DateTime? _pickedDate;
  late DateTime _focusedMonth;

  // ── Time state ────────────────────────────────────────────────
  int _selectedTimeIndex = 0; // 0 = Semua

  static const List<_TimeOption> _timeOptions = [
    _TimeOption(
      label: 'Semua',
      sublabel: 'Waktu',
      icon: Icons.wb_sunny_outlined,
    ),
    _TimeOption(
      label: '06-10',
      sublabel: 'Pagi',
      icon: Icons.wb_twilight_outlined,
    ),
    _TimeOption(
      label: '11-14',
      sublabel: 'Siang',
      icon: Icons.wb_sunny_rounded,
    ),
    _TimeOption(
      label: '15-17',
      sublabel: 'Sore',
      icon: Icons.wb_cloudy_outlined,
    ),
    _TimeOption(
      label: '18-22',
      sublabel: 'Malam',
      icon: Icons.nightlight_round_outlined,
    ),
  ];

  // ── Init ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    final init = widget.initialFilter;
    if (init != null) {
      _isFlexible = init.selectedDate == null;
      _pickedDate = init.selectedDate;
      if (init.selectedTimeRange != null) {
        final idx =
            _timeOptions.indexWhere((t) => t.label == init.selectedTimeRange);
        _selectedTimeIndex = idx >= 0 ? idx : 0;
      }
    }

    _focusedMonth = _pickedDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────

  void _apply() {
    Navigator.of(context).pop(
      LapanganFilterResult(
        selectedDate: _isFlexible ? null : _pickedDate,
        selectedTimeRange: _selectedTimeIndex == 0
            ? null
            : _timeOptions[_selectedTimeIndex].label,
      ),
    );
  }

  void _reset() {
    setState(() {
      _isFlexible = true;
      _pickedDate = null;
      _focusedMonth = DateTime.now();
      _selectedTimeIndex = 0;
    });
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildTabBar(),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDateTab(),
                _buildTimeTab(),
              ],
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  // ── Handle ────────────────────────────────────────────────────

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFDDDDDD),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: const Color(0xFF1A1A2E),
          unselectedLabelColor: const Color(0xFF9E9E9E),
          labelStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.all(4),
          tabs: _tabs.map((t) => Tab(text: t, height: 38)).toList(),
        ),
      ),
    );
  }

  // ── Date tab ──────────────────────────────────────────────────

  Widget _buildDateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildDateToggleRow(),
          const SizedBox(height: 20),
          _buildInlineCalendar(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDateToggleRow() {
    return Row(
      children: [
        Expanded(
          child: _dateToggleBtn(
            label: 'Flexible',
            active: _isFlexible,
            onTap: () => setState(() {
              _isFlexible = true;
              _pickedDate = null;
            }),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _dateToggleBtn(
            label: 'Select Date',
            active: !_isFlexible,
            onTap: () => setState(() {
              _isFlexible = false;
              _pickedDate ??= DateTime.now();
            }),
          ),
        ),
      ],
    );
  }

  Widget _dateToggleBtn({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1565C0) : Colors.white,
            border: Border.all(
          color: active ? const Color(0xFF1565C0) : const Color(0xFFDDDDDD),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (active) ...[
              const Icon(Icons.check_circle, size: 16, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineCalendar() {
    final now = DateTime.now();
    return Column(
      children: List.generate(3, (offset) {
        final month =
            DateTime(_focusedMonth.year, _focusedMonth.month + offset, 1);
        return _buildMonthCalendar(month, now);
      }),
    );
  }

  Widget _buildMonthCalendar(DateTime month, DateTime now) {
    const fullMonthNames = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final startOffset =
        DateTime(month.year, month.month, 1).weekday - 1; // Mon = 0

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${fullMonthNames[month.month]} ${month.year}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        // Weekday labels
        Row(
          children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: (d == 'Sab' || d == 'Min')
                            ? const Color(0xFFC62828)
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        // Day grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox.shrink();

            final day = index - startOffset + 1;
            final date = DateTime(month.year, month.month, day);
            final today = DateTime(now.year, now.month, now.day);
            final isPast = date.isBefore(today);
            final isToday = DateUtils.isSameDay(date, now);
            final isSelected = !_isFlexible &&
                _pickedDate != null &&
                DateUtils.isSameDay(date, _pickedDate!);
            final isWeekend = date.weekday == DateTime.saturday ||
                date.weekday == DateTime.sunday;

            return GestureDetector(
              onTap: isPast
                  ? null
                  : () => setState(() {
                        _isFlexible = false;
                        _pickedDate = date;
                      }),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : isToday
                          ? const Color(0xFFE8F5E9)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: const Color(0xFF2E7D32), width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : isPast
                              ? const Color(0xFFCCCCCC)
                              : isWeekend
                                  ? const Color(0xFF1565C0)
                                  : const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Time tab ──────────────────────────────────────────────────

  Widget _buildTimeTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.55,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _timeOptions.length,
        itemBuilder: (context, index) {
          final opt = _timeOptions[index];
          final isSelected = _selectedTimeIndex == index;

          return GestureDetector(
            onTap: () => setState(() => _selectedTimeIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFEEEEEE),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    opt.icon,
                    size: 22,
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF9E9E9E),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    opt.sublabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isSelected
                          ? const Color(0xFF2E7D32).withOpacity(0.7)
                          : const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Bottom actions ────────────────────────────────────────────

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        color: Colors.white,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _reset,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Reset',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: _apply,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
