import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:alumniconnect/widgets/user_avatar.dart';
import 'view_profile_page.dart';

class SearchPage extends StatefulWidget {
  final String currentCourse;
  final String currentYear;

  const SearchPage({
    super.key,
    required this.currentCourse,
    required this.currentYear,
  });

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  List<Map<dynamic, dynamic>> _searchResults = [];
  List<Map<dynamic, dynamic>> _suggestedResults = [];
  List<String>? _selectedCourses;
  List<String>? _selectedYears;
  List<String>? _selectedCities;
  List<String>? _selectedDesignations;
  bool _hasSearched = false;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _filtersApplied = false; // Added to track if filters are applied
  final int _pageSize = 10;
  String? _lastKey;

  final List<String> _courses = [
    'Civil & Rural Engineering',
    'Information Technology',
    'Computer Engineering',
    'Electronics & Tele-communication Engineering',
    'Electrical Engineering',
    'Mechanical Engineering',
  ];

  final List<String> _years = List.generate(
    DateTime.now().year - 1956,
    (index) => (DateTime.now().year - index).toString(),
  );

  List<String> _cities = [];
  List<String> _designations = [];

  final GlobalKey _tooltipKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchSuggestedAlumni();
    _fetchFilterOptions();
  }

  Future<void> _fetchFilterOptions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final cities = await _fetchUniqueFilterOptions('city');
      final designations = await _fetchUniqueFilterOptions('designation');

      if (mounted) {
        setState(() {
          _cities = cities.toList();
          _designations = designations.toList();
        });
      }
    } catch (error) {
      _showErrorDialog(
          'Error fetching filter options. Please try again later.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Set<String>> _fetchUniqueFilterOptions(String childName) async {
    final snapshot =
        await _database.child('alumni').orderByChild(childName).get();
    final options = <String>{};

    if (snapshot.exists) {
      for (var child in snapshot.children) {
        final Map<dynamic, dynamic> data =
            Map<dynamic, dynamic>.from(child.value as Map);
        options.add(data[childName] ?? 'Unknown');
      }
    }

    return options;
  }

  Future<void> _fetchSuggestedAlumni() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await _database
          .child('alumni')
          .orderByChild('course')
          .equalTo(widget.currentCourse)
          .limitToFirst(_pageSize)
          .get();

      final results = _processSnapshot(snapshot);

      if (mounted) {
        setState(() {
          _suggestedResults = results;
          _hasMore = snapshot.children.length == _pageSize;
        });
      }
    } catch (error) {
      _showErrorDialog(
          'Error fetching suggested alumni. Please try again later.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<dynamic, dynamic>> _processSnapshot(DataSnapshot snapshot) {
    final results = <Map<dynamic, dynamic>>[];

    if (snapshot.exists) {
      for (var child in snapshot.children) {
        final Map<dynamic, dynamic> data =
            Map<dynamic, dynamic>.from(child.value as Map);
        if (data['uid'] != _currentUser?.uid) {
          results.add(data);
          _lastKey = child.key;
        }
      }
    }

    return results;
  }

  Future<void> _searchAlumni(String query) async {
    setState(() {
      _hasSearched = true;
      _isLoading = true;
    });

    List<Map<dynamic, dynamic>> results = [];

    try {
      // If no courses are selected, fetch all alumni records
      if (_selectedCourses == null || _selectedCourses!.isEmpty) {
        final snapshot = await _database.child('alumni').get();
        results = _processSnapshot(snapshot);
      } else {
        // Fetch records for each selected course
        for (String course in _selectedCourses!) {
          final snapshot = await _database
              .child('alumni')
              .orderByChild('course')
              .equalTo(course)
              .get();

          results.addAll(_processSnapshot(snapshot));
        }
      }

      // Apply client-side filters after fetching
      final filteredResults = results.where((result) {
        final matchYear = _selectedYears == null ||
            _selectedYears!.isEmpty ||
            _selectedYears!.contains(result['year']);
        final matchCity = _selectedCities == null ||
            _selectedCities!.isEmpty ||
            _selectedCities!.contains(result['city']);
        final matchDesignation = _selectedDesignations == null ||
            _selectedDesignations!.isEmpty ||
            _selectedDesignations!.contains(result['designation']);
        final matchQuery = query.isEmpty ||
            (result['name'] as String)
                .toLowerCase()
                .contains(query.toLowerCase());

        return matchYear && matchCity && matchDesignation && matchQuery;
      }).toList();

      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
        });
      }
    } catch (error) {
      _showErrorDialog('Error searching alumni. Please try again later.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreSuggestedAlumni() async {
    if (!_hasMore || _lastKey == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _database
          .child('alumni')
          .orderByChild('course')
          .equalTo(widget.currentCourse)
          .startAfter(_lastKey)
          .limitToFirst(_pageSize)
          .get();

      final results = _processSnapshot(snapshot);

      if (mounted) {
        setState(() {
          _suggestedResults.addAll(results);
          _hasMore = snapshot.children.length == _pageSize;
        });
      }
    } catch (error) {
      _showErrorDialog(
          'Error fetching more suggested alumni. Please try again later.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters(List<String> courses, List<String> years,
      List<String> cities, List<String> designations) {
    setState(() {
      _selectedCourses = courses;
      _selectedYears = years;
      _selectedCities = cities;
      _selectedDesignations = designations;
      _filtersApplied = true; // Mark that filters have been applied
    });

    _searchAlumni(_searchController.text.trim());

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _clearSearch() {
    setState(() {
      _selectedCourses = null;
      _selectedYears = null;
      _selectedCities = null;
      _selectedDesignations = null;
      _searchController.clear();
      _searchResults.clear();
      _hasSearched = false;
      _filtersApplied = false; // Reset the filter indication
    });

    _fetchSuggestedAlumni();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FilterSheet(
          courses: _courses,
          years: _years,
          cities: _cities,
          designations: _designations,
          selectedCourses: _selectedCourses,
          selectedYears: _selectedYears,
          selectedCities: _selectedCities,
          selectedDesignations: _selectedDesignations,
          onCourseChanged: (value) {
            setState(() {
              _selectedCourses = value;
            });
          },
          onYearChanged: (value) {
            setState(() {
              _selectedYears = value;
            });
          },
          onCityChanged: (value) {
            setState(() {
              _selectedCities = value;
            });
          },
          onDesignationChanged: (value) {
            setState(() {
              _selectedDesignations = value;
            });
          },
          onApply: () => _applyFilters(
              _selectedCourses ?? [],
              _selectedYears ?? [],
              _selectedCities ?? [],
              _selectedDesignations ?? []),
          onClear: _clearSearch,
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.white,
            ),
            title: Container(
              height: 10.0,
              color: Colors.white,
            ),
            subtitle: Container(
              height: 10.0,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  void _navigateToProfile(Map<dynamic, dynamic> userProfile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewProfilePage(
          userProfile: Map<String, dynamic>.from(userProfile),
        ),
      ),
    );
  }

  void _showTooltip(BuildContext context) {
    final dynamic tooltip = _tooltipKey.currentState;
    tooltip.ensureTooltipVisible();
    Future.delayed(const Duration(seconds: 3), () {
      if (tooltip.mounted) {
        tooltip.deactivate();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16.0),
            if (_hasSearched)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Results",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Wrap(
                      alignment: WrapAlignment
                          .start, // Align chips to the start (left)
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _buildFilterChips(),
                    ),
                    const Divider(),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? _buildShimmerPlaceholder()
                  : _hasSearched
                      ? _buildSearchResults()
                      : _buildSuggestedResults(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFilterSheet(context),
        tooltip: 'Filters',
        child: Stack(
          children: [
            Icon(
              _filtersApplied ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: const Color(0xff986ae7),
            ),
            if (_filtersApplied)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  final Map<String, Color> _filterColors = {
    'Course': const Color(0xffdfd8fd),
    'Graduation Year': const Color(0xfffdd0ec),
    'City': const Color(0xffffd2cc),
    'Designation': const Color(0xffd3f1a7),
  };

  final Map<String, Color> _textColors = {
    'Course': const Color(0xff5b47bf),
    'Graduation Year': const Color(0xffd63f9e),
    'City': const Color(0xffef840c),
    'Designation': const Color(0xff528105),
  };

  List<Widget> _buildFilterChips() {
    final chips = <Widget>[];

    if (_selectedCourses != null && _selectedCourses!.isNotEmpty) {
      chips.addAll(_selectedCourses!.map((course) {
        return Chip(
          label: Text(
            course,
            style: TextStyle(
                color: _textColors['Course'],
                fontWeight: FontWeight.bold), // Use darker text color
          ),
          backgroundColor:
              _filterColors['Course'], // Use background color for Course
          deleteIconColor: _textColors['Course'],
          onDeleted: () {
            setState(() {
              _selectedCourses!.remove(course);
              _handleFilterChange();
            });
          },
        );
      }).toList());
    }

    if (_selectedYears != null && _selectedYears!.isNotEmpty) {
      chips.addAll(_selectedYears!.map((year) {
        return Chip(
          label: Text(
            year,
            style: TextStyle(
                color: _textColors['Graduation Year'],
                fontWeight: FontWeight.bold), // Use darker text color
          ),
          backgroundColor: _filterColors['Graduation Year'], // Use background color for Graduation Year
          deleteIconColor: _textColors['Graduation Year'],
          onDeleted: () {
            setState(() {
              _selectedYears!.remove(year);
              _handleFilterChange();
            });
          },
        );
      }).toList());
    }

    if (_selectedCities != null && _selectedCities!.isNotEmpty) {
      chips.addAll(_selectedCities!.map((city) {
        return Chip(
          label: Text(
            city,
            style:
                TextStyle(color: _textColors['City'],fontWeight: FontWeight.bold), // Use darker text color
          ),
          backgroundColor:
              _filterColors['City'], // Use background color for City
          deleteIconColor: _textColors['City'],
          onDeleted: () {
            setState(() {
              _selectedCities!.remove(city);
              _handleFilterChange();
            });
          },
        );
      }).toList());
    }

    if (_selectedDesignations != null && _selectedDesignations!.isNotEmpty) {
      chips.addAll(_selectedDesignations!.map((designation) {
        return Chip(
          label: Text(
            designation,
            style: TextStyle(
                color: _textColors['Designation'],fontWeight: FontWeight.bold), // Use darker text color
          ),
          backgroundColor: _filterColors[
              'Designation'], // Use background color for Designation
          deleteIconColor: _textColors['Designation'],
          onDeleted: () {
            setState(() {
              _selectedDesignations!.remove(designation);
              _handleFilterChange();
            });
          },
        );
      }).toList());
    }

    return chips;
  }

  void _handleFilterChange() {
    if ((_selectedCourses == null || _selectedCourses!.isEmpty) &&
        (_selectedYears == null || _selectedYears!.isEmpty) &&
        (_selectedCities == null || _selectedCities!.isEmpty) &&
        (_selectedDesignations == null || _selectedDesignations!.isEmpty)) {
      // All filters are cleared, show suggested alumni
      setState(() {
        _hasSearched = false;
        _filtersApplied = false;
      });
      _fetchSuggestedAlumni();
    } else {
      // Apply the remaining filters
      _applyFilters(_selectedCourses!, _selectedYears!, _selectedCities!,
          _selectedDesignations!);
    }
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search by name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _clearSearch();
                },
              ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _searchAlumni(_searchController.text.trim()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('No records found'));
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return AlumniListTile(
          result: result,
          navigateToProfile: _navigateToProfile,
        );
      },
    );
  }

  Widget _buildSuggestedResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Suggested',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showTooltip(context),
              child: Tooltip(
                key: _tooltipKey,
                margin: const EdgeInsets.only(left: 6.0, right: 6.0),
                message:
                    'Suggested based on your course and graduation year\n (${widget.currentCourse}, ${widget.currentYear}).',
                child: const Icon(Icons.info_outline, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _suggestedResults.isEmpty
              ? const Center(child: Text('No suggestions available'))
              : ListView.builder(
                  itemCount: _suggestedResults.length,
                  itemBuilder: (context, index) {
                    final result = _suggestedResults[index];
                    return AlumniListTile(
                      result: result,
                      navigateToProfile: _navigateToProfile,
                    );
                  },
                ),
        ),
        if (_hasMore)
          Center(
            child: ElevatedButton(
              onPressed: _fetchMoreSuggestedAlumni,
              child: const Text('Load More'),
            ),
          ),
      ],
    );
  }
}

class FilterSheet extends StatefulWidget {
  final List<String> courses;
  final List<String> years;
  final List<String> cities;
  final List<String> designations;
  final List<String>? selectedCourses;
  final List<String>? selectedYears;
  final List<String>? selectedCities;
  final List<String>? selectedDesignations;
  final ValueChanged<List<String>> onCourseChanged;
  final ValueChanged<List<String>> onYearChanged;
  final ValueChanged<List<String>> onCityChanged;
  final ValueChanged<List<String>> onDesignationChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const FilterSheet({
    super.key,
    required this.courses,
    required this.years,
    required this.cities,
    required this.designations,
    required this.selectedCourses,
    required this.selectedYears,
    required this.selectedCities,
    required this.selectedDesignations,
    required this.onCourseChanged,
    required this.onYearChanged,
    required this.onCityChanged,
    required this.onDesignationChanged,
    required this.onApply,
    required this.onClear,
  });

  @override
  FilterSheetState createState() => FilterSheetState();
}

class FilterSheetState extends State<FilterSheet> {
  String _selectedCategory = 'Course';
  Map<String, List<String>> _filterOptions = {};
  Map<String, List<String>> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    _filterOptions = {
      'Course': widget.courses,
      'Graduation Year': widget.years,
      'City': widget.cities,
      'Designation': widget.designations,
    };

    _selectedOptions = {
      'Course': widget.selectedCourses ?? [],
      'Graduation Year': widget.selectedYears ?? [],
      'City': widget.selectedCities ?? [],
      'Designation': widget.selectedDesignations ?? [],
    };
  }

  int _selectedFilterCount() {
    return _selectedOptions.values.where((list) => list.isNotEmpty).length;
  }

  String _getFilterTitle() {
    int count = _selectedFilterCount();
    return count > 0 ? 'Filters ($count)' : 'Filters';
  }

  void _clearFilters() {
    setState(() {
      _selectedOptions.forEach((key, value) {
        value.clear();
      });
    });
    widget.onClear();
  }

  void _applyFilters() {
    // Check if any filter has been selected
    if (_selectedFilterCount() == 0) {
      Navigator.pop(context); // Close the filter sheet
      return; // Do nothing if no filters are selected
    }

    widget.onCourseChanged(_selectedOptions['Course']!);
    widget.onYearChanged(_selectedOptions['Graduation Year']!);
    widget.onCityChanged(_selectedOptions['City']!);
    widget.onDesignationChanged(_selectedOptions['Designation']!);
    widget.onApply();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          // Close Button with Dynamic Title
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getFilterTitle(),
                  style: const TextStyle(fontSize: 18),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Row(
              children: [
                // Filter Categories
                Container(
                  width: 150,
                  color: const Color(0xfff5f0ff),
                  child: ListView(
                    children: _filterOptions.keys.map((category) {
                      return ListTile(
                        title: Text(
                          category,
                          style: TextStyle(
                            fontWeight: _selectedCategory == category
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _selectedCategory == category
                                ? const Color(0xff986ae7)
                                : Colors.black,
                          ),
                        ),
                        trailing: _selectedOptions[category]!.isNotEmpty
                            ? Text(
                                '${_selectedOptions[category]!.length}',
                                style: const TextStyle(
                                    color: Color(0xff986ae7), fontSize: 16),
                              )
                            : null,
                        selected: _selectedCategory == category,
                       // Set the background color for selected tile
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
                // Filter Options
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8.0),
                    children: _filterOptions[_selectedCategory]!.map((option) {
                      return CheckboxListTile(
                        title: Text(option),
                        value: _selectedOptions[_selectedCategory]!
                            .contains(option),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedOptions[_selectedCategory]!.add(option);
                            } else {
                              _selectedOptions[_selectedCategory]!
                                  .remove(option);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Bottom Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _clearFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xffff1f1f),
                    side: const BorderSide(color: const Color(0xffff7777)),
                  ),
                  child: const Text('Clear Filters'),
                ),
                ElevatedButton(
                  onPressed: _selectedFilterCount() > 0 ? _applyFilters : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedFilterCount() > 0
                        ? const Color(0xff986ae7)
                        : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Show Results'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AlumniListTile extends StatelessWidget {
  final Map<dynamic, dynamic> result;
  final Function(Map<dynamic, dynamic>) navigateToProfile;

  const AlumniListTile({
    super.key,
    required this.result,
    required this.navigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    final String uid = result['uid'] ?? 'unknown';
    final String? blurHash = result['blurHash'];

    return ListTile(
      leading: Hero(
        tag: 'profileImage-$uid',
        child: UserAvatar(
          imageUrl: result['imageUrl'],
          blurHash: blurHash,
          radius: 25,
        ),
      ),
      title: Hero(
        tag: 'profileName-$uid',
        child: Material(
          color: Colors.transparent,
          child: Text(
            result['name'] ?? 'No Name',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      subtitle: Hero(
        tag: 'profileEmail-$uid',
        child: Material(
          color: Colors.transparent,
          child: Text(result['email'] ?? 'No Email'),
        ),
      ),
      onTap: () => navigateToProfile(result),
    );
  }
}
