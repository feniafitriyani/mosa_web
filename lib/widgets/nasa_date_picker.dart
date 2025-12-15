import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NasaDatePicker extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final bool isVisible;

  const NasaDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.isVisible,
  });

  @override
  State<NasaDatePicker> createState() => _NasaDatePickerState();
}

class _NasaDatePickerState extends State<NasaDatePicker> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'NASA Satellite Date',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('yyyy-MM-dd').format(widget.selectedDate),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              IconButton(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.calendar_today, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Available: 2000-01-01 to ${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)))}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime.now().subtract(const Duration(days: 1)),
      helpText: 'Select NASA Satellite Date',
      cancelText: 'Cancel',
      confirmText: 'OK',
    );
    
    if (picked != null && picked != widget.selectedDate) {
      widget.onDateChanged(picked);
    }
  }
}