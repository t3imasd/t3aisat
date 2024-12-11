// lib/widgets/search_bar_widget.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/search_service.dart';
import '../model/search_result.dart';

class ExpandableSearchBar extends StatefulWidget {
  final Function(SearchResult) onLocationSelected;
  
  const ExpandableSearchBar({
    super.key, 
    required this.onLocationSelected,
  });

  @override
  State<ExpandableSearchBar> createState() => _ExpandableSearchBarState();
}

class _ExpandableSearchBarState extends State<ExpandableSearchBar> {
  bool _isExpanded = false;
  final _searchController = TextEditingController();
  final _searchService = MapboxSearchService();
  Timer? _debounce;
  List<SearchResult> _results = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? MediaQuery.of(context).size.width * 0.7 : 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: _isExpanded ? _buildSearchField() : _buildSearchIcon(),
    );
  }

  Widget _buildSearchField() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar dirección...',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: InputBorder.none,
            suffixIcon: _isLoading 
              ? const CircularProgressIndicator() 
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSearch,
                ),
          ),
          onChanged: _onSearchChanged,
        ),
        if (_results.isNotEmpty)
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (context, index) => _buildResultItem(_results[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchIcon() {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () {
        setState(() {
          _isExpanded = true;
        });
      },
    );
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _results.clear();
      _isExpanded = false;
    });
  }

  Widget _buildResultItem(SearchResult result) {
    return ListTile(
      title: Text(result.name),
      subtitle: Text(result.address),
      onTap: () {
        widget.onLocationSelected(result);
        _clearSearch();
      },
    );
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);
      final results = await _searchService.searchAddress(query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    });
  }
}