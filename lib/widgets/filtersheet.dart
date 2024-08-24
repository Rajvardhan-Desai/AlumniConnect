import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class FilterSheet extends StatelessWidget {
  final List<String> courses;
  final List<String> years;
  final List<String> cities;
  final List<String> designations;
  final String? selectedCourse;
  final String? selectedYear;
  final String? selectedCity;
  final String? selectedDesignation;
  final ValueChanged<String?> onCourseChanged;
  final ValueChanged<String?> onYearChanged;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onDesignationChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const FilterSheet({
    super.key,
    required this.courses,
    required this.years,
    required this.cities,
    required this.designations,
    required this.selectedCourse,
    required this.selectedYear,
    required this.selectedCity,
    required this.selectedDesignation,
    required this.onCourseChanged,
    required this.onYearChanged,
    required this.onCityChanged,
    required this.onDesignationChanged,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ListView(
                    children: [
                      FilterOption(
                        label: 'Course',
                        options: courses,
                        selectedOption: selectedCourse,
                        onChanged: onCourseChanged,
                      ),
                      FilterOption(
                        label: 'Graduation Year',
                        options: years,
                        selectedOption: selectedYear,
                        onChanged: onYearChanged,
                      ),
                      FilterOption(
                        label: 'City',
                        options: cities,
                        selectedOption: selectedCity,
                        onChanged: onCityChanged,
                      ),
                      FilterOption(
                        label: 'Designation',
                        options: designations,
                        selectedOption: selectedDesignation,
                        onChanged: onDesignationChanged,
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(),
                Expanded(
                  flex: 2,
                  child: ListView(
                    children: [
                      FilterChipGroup(
                        label: 'Course',
                        options: courses,
                        selectedOption: selectedCourse,
                        onChanged: onCourseChanged,
                      ),
                      FilterChipGroup(
                        label: 'Graduation Year',
                        options: years,
                        selectedOption: selectedYear,
                        onChanged: onYearChanged,
                      ),
                      FilterChipGroup(
                        label: 'City',
                        options: cities,
                        selectedOption: selectedCity,
                        onChanged: onCityChanged,
                      ),
                      FilterChipGroup(
                        label: 'Designation',
                        options: designations,
                        selectedOption: selectedDesignation,
                        onChanged: onDesignationChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onClear,
                child: const Text('Clear Filters'),
              ),
              ElevatedButton(
                onPressed: onApply,
                child: const Text('Show Results'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FilterChipGroup extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String?> onChanged;

  const FilterChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: options.map((option) {
              return FilterChip(
                label: Text(option),
                selected: selectedOption == option,
                onSelected: (selected) {
                  onChanged(selected ? option : null);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class FilterOption extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String?> onChanged;

  const FilterOption({
    super.key,
    required this.label,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: options.map((option) {
              return FilterChip(
                label: Text(option),
                selected: selectedOption == option,
                onSelected: (selected) {
                  onChanged(selected ? option : null);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
