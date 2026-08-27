import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryDonutChart extends StatelessWidget {
  final Map<String, int> categoryData;

  const CategoryDonutChart({super.key, required this.categoryData});

  static const _categoryColors = {
    'salud': Color(0xFF4CAF50),
    'trabajo': Color(0xFF2196F3),
    'estudio': Color(0xFF9C27B0),
    'finanzas': Color(0xFF4CAF50),
    'hogar': Color(0xFFFF9800),
    'social': Color(0xFFE91E63),
    'ocio': Color(0xFF00BCD4),
    'otro': Color(0xFF9E9E9E),
  };

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) return const SizedBox.shrink();

    final total = categoryData.values.fold(0, (a, b) => a + b);
    final entries = categoryData.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Por categoría',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: List.generate(entries.length, (i) {
                          final entry = entries[i];
                          final percentage = entry.value / total;
                          return PieChartSectionData(
                            color: _categoryColors[entry.key] ??
                                _categoryColors['otro']!,
                            value: percentage * 100,
                            title:
                                '${(percentage * 100).toInt()}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: entries.map((e) {
                        final color = _categoryColors[e.key] ??
                            _categoryColors['otro']!;
                        final label = _categoryLabel(e.key);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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

  String _categoryLabel(String key) {
    switch (key) {
      case 'salud': return 'Salud';
      case 'trabajo': return 'Trabajo';
      case 'estudio': return 'Estudio';
      case 'finanzas': return 'Finanzas';
      case 'hogar': return 'Hogar';
      case 'social': return 'Social';
      case 'ocio': return 'Ocio';
      default: return 'Otro';
    }
  }
}
