import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StoreSidebar extends StatefulWidget {
  final void Function(Map<String, dynamic> filters) onApply;
  const StoreSidebar({super.key, required this.onApply});

  @override
  State<StoreSidebar> createState() => _StoreSidebarState();
}

class _StoreSidebarState extends State<StoreSidebar> {
  final _nameController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  String? _selectedCategory;
  String? _selectedCondition;
  double _minRating = 0;

  void _resetFilters() {
    setState(() {
      _nameController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedCategory = null;
      _selectedCondition = null;
      _minRating = 0;
    });
    widget.onApply({});
  }

  void _applyFilters() {
    widget.onApply({
      'name': _nameController.text,
      'minPrice': double.tryParse(_minPriceController.text),
      'maxPrice': double.tryParse(_maxPriceController.text),
      'category': _selectedCategory,
      'condition': _selectedCondition,
      'minRating': _minRating,
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        Text(
          loc.filters,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: 24),
        ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            loc.searchAndPrice,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: loc.searchByName),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: loc.minPrice,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: loc.maxPrice,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            loc.categoryAndCondition,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items:
                  ['venta', 'alquiler']
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e == 'venta' ? loc.sale : loc.rent),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              decoration: const InputDecoration(), // Sin labelText
              hint: Text(loc.selectCategory),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              items:
                  ['nuevo', 'usado']
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e == 'nuevo' ? loc.newCondition : loc.usedCondition),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _selectedCondition = v),
              decoration: const InputDecoration(), // Sin labelText
              hint: Text(loc.selectCondition),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            loc.minRating,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            Row(
              children: [
                Text(loc.minRatingLabel),
                Expanded(
                  child: Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: _minRating.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _minRating = v),
                  ),
                ),
                Text(_minRating.toStringAsFixed(0)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.filter_alt),
                label: Text(loc.applyFilters),
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(loc.reset),
                onPressed: _resetFilters,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
