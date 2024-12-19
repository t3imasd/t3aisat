// lib/widgets/search_bar_widget.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/search_service.dart';
import '../model/search_result.dart';
import '../screens/parcel_map_screen.dart';

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
          style: const TextStyle(  // Style for the text written the user
            fontSize: 16.0,
            fontWeight: FontWeight.normal,
            decoration: TextDecoration.none,  // Eliminate underlined
          ),
          decoration: const InputDecoration(
            hintText: 'Buscar dirección...',
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide.none, // Esto elimina el subrayado
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide.none, // Esto elimina el subrayado cuando está enfocado
            ),
            border: InputBorder.none, // Esto también ayuda a eliminar bordes
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    if (query.isNotEmpty) {
      // Si hay texto, marcamos el SearchBar como activo
      // para evitar que se oculte automáticamente
      if (context.findAncestorStateOfType<ParcelMapScreenState>() != null) {
        context.findAncestorStateOfType<ParcelMapScreenState>()!.setSearchBarActive(true);
      }
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      
      setState(() => _isLoading = true);
      final results = await _searchService.searchAddress(query);
      
      if (!mounted) return;
      
      setState(() {
        _results = results;
        _isLoading = false;
      });
    });
  }
}
