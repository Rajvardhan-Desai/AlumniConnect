import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:alumniconnect/widgets/user_avatar.dart'; // Import the UserAvatar widget
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
  String? _selectedCourse;
  String? _selectedYear;
  String? _selectedCity;
  String? _selectedDesignation;
  bool _hasSearched = false;
  bool _isLoading = false;
  bool _hasMore = true;
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
      _showErrorDialog('Error fetching filter options. Please try again later.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Set<String>> _fetchUniqueFilterOptions(String childName) async {
    final snapshot = await _database.child('alumni').orderByChild(childName).get();
    final options = <String>{};

    if (snapshot.exists) {
      for (var child in snapshot.children) {
        final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(child.value as Map);
        options.add(data[childName]);
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
      _showErrorDialog('Error fetching suggested alumni. Please try again later.');
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
        final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(child.value as Map);
        if (data['year'] == widget.currentYear && data['uid'] != _currentUser?.uid) {
          results.add(data);
          _lastKey = child.key;
        }
      }
    }

    return results;
  }

  Future<void> _searchAlumni(String query) async {
    if (query.isEmpty &&
        _selectedCourse == null &&
        _selectedYear == null &&
        _selectedCity == null &&
        _selectedDesignation == null) {
      setState(() {
        _searchResults.clear();
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _hasSearched = true;
      _isLoading = true;
    });

    try {
      final snapshot = await _database
          .child('alumni')
          .orderByChild('name')
          .startAt(query)
          .endAt('$query\uf8ff')
          .get();

      final results = _filterResults(snapshot);

      if (mounted) {
        setState(() {
          _searchResults = results;
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

  List<Map<dynamic, dynamic>> _filterResults(DataSnapshot snapshot) {
    final results = <Map<dynamic, dynamic>>[];

    if (snapshot.exists) {
      for (var child in snapshot.children) {
        final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(child.value as Map);
        if ((_selectedCourse == null || data['course'] == _selectedCourse) &&
            (_selectedYear == null || data['year'] == _selectedYear) &&
            (_selectedCity == null || data['city'] == _selectedCity) &&
            (_selectedDesignation == null || data['designation'] == _selectedDesignation) &&
            data['uid'] != _currentUser?.uid) {
          results.add(data);
        }
      }
    }

    return results;
  }

  Future<void> _fetchMoreSuggestedAlumni() async {
    if (!_hasMore) return;
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
      _showErrorDialog('Error fetching more suggested alumni. Please try again later.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    _searchAlumni(_searchController.text.trim());
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _clearSearch() {
    setState(() {
      _selectedCourse = null;
      _selectedYear = null;
      _selectedCity = null;
      _selectedDesignation = null;
      _searchController.clear();
      _searchResults.clear();
      _hasSearched = false;
    });

    _fetchSuggestedAlumni();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              CustomDropdown(
                label: 'Course',
                value: _selectedCourse,
                items: ['', ..._courses],
                onChanged: (value) {
                  setState(() {
                    _selectedCourse = value?.isEmpty == true ? null : value;
                  });
                },
                isExpanded: true,
              ),
              const SizedBox(height: 16.0),
              CustomDropdown(
                label: 'Graduation Year',
                value: _selectedYear,
                items: ['', ..._years],
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value?.isEmpty == true ? null : value;
                  });
                },
                isExpanded: true,
              ),
              const SizedBox(height: 16.0),
              CustomDropdown(
                label: 'City',
                value: _selectedCity,
                items: ['', ..._cities],
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value?.isEmpty == true ? null : value;
                  });
                },
                isExpanded: true,
              ),
              const SizedBox(height: 16.0),
              CustomDropdown(
                label: 'Designation',
                value: _selectedDesignation,
                items: ['', ..._designations],
                onChanged: (value) {
                  setState(() {
                    _selectedDesignation = value?.isEmpty == true ? null : value;
                  });
                },
                isExpanded: true,
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Apply'),
                  ),
                  ElevatedButton(
                    onPressed: _clearSearch,
                    style: ElevatedButton.styleFrom(),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ],
          ),
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
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16.0),
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
        child: const Icon(Icons.filter_alt, color: Color(0xff986ae7)),
      ),
    );
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
      return const Center(child: Text('No results found'));
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
                message:
                'Suggested based on your course (${widget.currentCourse}) and graduation year (${widget.currentYear}).',
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

class CustomDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final bool isExpanded;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      isExpanded: isExpanded,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item.isEmpty ? 'None' : item,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
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
