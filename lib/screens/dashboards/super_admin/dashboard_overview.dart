// lib/screens/super_admin/dashboard_overview.dart
import 'dart:math';
import 'package:flutter/material.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    // Grid responsiveness
    int crossAxisCount = 2;
    if (size.width > 1200) {
      crossAxisCount = 4;
    } else if (size.width > 900) crossAxisCount = 3;

    // Static summary data (placeholder values)
    final List<_SummaryItem> items = [
      _SummaryItem('Total Restaurants', '24', Icons.restaurant),
      _SummaryItem('Total Customers', '1,420', Icons.people),
      _SummaryItem('Active Orders', '58', Icons.delivery_dining),
      _SummaryItem('Completed Orders', '3,410', Icons.check_circle_outline),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Welcome back, Super Admin 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              Text(
                _formatDate(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary cards grid
          LayoutBuilder(builder: (context, constraints) {
            // Use GridView.builder inside a fixed-height container would be messy in scroll view;
            // Use Wrap to get responsive wrapping behaviour
            final double itemWidth = (constraints.maxWidth - (16 * (crossAxisCount - 1))) / crossAxisCount;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: items
                  .map((it) => SizedBox(
                        width: itemWidth < 260 ? constraints.maxWidth : itemWidth,
                        child: _SummaryCard(item: it),
                      ))
                  .toList(),
            );
          }),

          const SizedBox(height: 28),

          // Performance Overview title
          Text(
            'Performance Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 12),

          // Performance cards: Bar chart and Line chart
          LayoutBuilder(
            builder: (context, constraints) {
              final bool sideBySide = constraints.maxWidth >= 800;
              final double chartWidth = sideBySide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
              return sideBySide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: chartWidth, child: _RestaurantActivityCard()),
                        const SizedBox(width: 16),
                        SizedBox(width: chartWidth, child: _WeeklyCustomersCard()),
                      ],
                    )
                  : Column(
                      children: [
                        _RestaurantActivityCard(),
                        const SizedBox(height: 16),
                        _WeeklyCustomersCard(),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _SummaryItem {
  final String title;
  final String value;
  final IconData icon;
  _SummaryItem(this.title, this.value, this.icon);
}

class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;
  const _SummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 3,
      color: colors.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Row(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: colors.onSecondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 30, color: colors.tertiary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.tertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: TextStyle(
                      color: colors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------- Restaurant Activity Card (Bar Chart) --------------------
class _RestaurantActivityCard extends StatefulWidget {
  @override
  State<_RestaurantActivityCard> createState() => _RestaurantActivityCardState();
}

class _RestaurantActivityCardState extends State<_RestaurantActivityCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Mock data: active vs inactive counts per category (here only one group for simplicity)
  final List<double> activeData = [8, 10, 9, 12, 11]; // sample active restaurants per day
  final List<double> inactiveData = [2, 1, 3, 1, 2]; // sample inactive per day
  final List<String> labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    // trigger animation on build
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _maxValue() {
    double max = 1;
    for (var v in activeData) {
      if (v + 0 > max) max = v;
    }
    for (var v in inactiveData) {
      if (v + 0 > max) max = v;
    }
    return max * 1.3; // add headroom
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final max = _maxValue();

    return Card(
      elevation: 2,
      color: colors.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restaurant Activity Summary',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: colors.tertiary)),
            const SizedBox(height: 8),
            Text('Active vs Inactive (last 5 working days)',
                style: TextStyle(fontSize: 12, color: colors.onSecondary.withOpacity(0.85))),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final t = Curves.easeOut.transform(_controller.value);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(labels.length, (i) {
                      final activeH = (activeData[i] / max) * 1.0 * t;
                      final inactiveH = (inactiveData[i] / max) * 1.0 * t;
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // stacked bars: active on top, inactive below (or side-by-side)
                            Container(
                              width: 18,
                              height: 180 * inactiveH,
                              decoration: BoxDecoration(
                                color: colors.tertiary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 18,
                              height: 180 * activeH,
                              decoration: BoxDecoration(
                                color: colors.tertiary.withOpacity(0.30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(labels[i],
                                style: TextStyle(fontSize: 12, color: colors.tertiary)),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _legendDot(colors.onSecondary, 'Active'),
                const SizedBox(width: 12),
                _legendDot(colors.onSecondary.withOpacity(0.25), 'Inactive'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondary)),
      ],
    );
  }
}

/// -------------------- Weekly Customers Card (Animated Line Chart) --------------------
class _WeeklyCustomersCard extends StatefulWidget {
  @override
  State<_WeeklyCustomersCard> createState() => _WeeklyCustomersCardState();
}

class _WeeklyCustomersCardState extends State<_WeeklyCustomersCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Mock weekly customer data (7 days)
  final List<double> data = [12, 18, 20, 27, 22, 30, 35];
  final List<String> labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _maxY() => (data.reduce(max)) * 1.2;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxY = _maxY();

    return Card(
      elevation: 2,
      color: colors.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly New Customers',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.tertiary)),
            const SizedBox(height: 8),
            Text('Customer growth rate over the last 7 days',
                style: TextStyle(fontSize: 12, color: colors.onSecondary.withOpacity(0.85))),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _LineChartPainter(
                      animationPercent: Curves.easeOut.transform(_controller.value),
                      data: data,
                      labels: labels,
                      lineColor: colors.tertiary,
                      axisColor: colors.tertiary,
                      fillColor: colors.tertiary.withOpacity(0.30),
                      maxY: maxY,
                    ),
                    child: Container(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final double animationPercent;
  final List<double> data;
  final List<String> labels;
  final Color lineColor;
  final Color axisColor;
  final Color fillColor;
  final double maxY;

  _LineChartPainter({
    required this.animationPercent,
    required this.data,
    required this.labels,
    required this.lineColor,
    required this.axisColor,
    required this.fillColor,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintAxis = Paint()..color = axisColor..strokeWidth = 1;
    final paintLine = Paint()..color = lineColor..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final paintFill = Paint()..color = fillColor..style = PaintingStyle.fill;

    final double leftPadding = 30;
    final double bottomPadding = 30;
    final double w = size.width - leftPadding - 8;
    final double h = size.height - bottomPadding - 12;

    // Draw horizontal grid lines
    final int gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final dy = 12 + (h / gridLines) * i;
      canvas.drawLine(Offset(leftPadding, dy), Offset(leftPadding + w, dy), paintAxis);
    }

    // Map data to points
    final int n = data.length;
    if (n < 2) return;

    final double stepX = w / (n - 1);
    final List<Offset> points = [];
    for (int i = 0; i < n; i++) {
      final dx = leftPadding + (stepX * i);
      final dy = 12 + h - (data[i] / maxY) * h * animationPercent;
      points.add(Offset(dx, dy));
    }

    // Fill area under line
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.lineTo(points.last.dx, size.height - bottomPadding);
    path.lineTo(points.first.dx, size.height - bottomPadding);
    path.close();
    canvas.drawPath(path, paintFill);

    // Draw line path (smooth)
    final pathLine = Path();
    pathLine.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      // simple quadratic smoothing
      final prev = points[i - 1];
      final curr = points[i];
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      pathLine.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    // last segment to final point
    final last = points.last;
    pathLine.lineTo(last.dx, last.dy);
    canvas.drawPath(pathLine, paintLine);

    // Draw small circular points
    final paintPoint = Paint()..color = lineColor;
    for (var p in points) {
      canvas.drawCircle(p, 3.0, paintPoint);
    }

    // Draw labels on X axis
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < labels.length; i++) {
      final tp = TextSpan(text: labels[i], style: TextStyle(color: axisColor, fontSize: 10));
      textPainter.text = tp;
      textPainter.layout();
      final dx = leftPadding + (stepX * i) - textPainter.width / 2;
      final dy = size.height - bottomPadding + 6;
      textPainter.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.animationPercent != animationPercent || oldDelegate.data != data;
  }
}
