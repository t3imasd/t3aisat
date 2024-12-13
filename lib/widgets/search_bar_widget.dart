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
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: MediaQuery.of(context).size.width * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: _buildSearchField(),
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
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearSearch,
                  )
                : _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
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
              itemBuilder: (context, index) =>
                  _buildResultItem(_results[index]),
            ),
          ),
      ],
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
      if (!mounted) return; // Verificar si el widget sigue montado
      
      setState(() => _isLoading = true);
      final results = await _searchService.searchAddress(query);
      
      if (!mounted) return; // Verificar nuevamente después de la operación asíncrona
      
      setState(() {
        _results = results;
        _isLoading = false;
      });
    });
  }
}
