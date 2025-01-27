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
  String? _errorMessage;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchField(),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
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
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        decoration: TextDecoration.none,
      ),
      decoration: const InputDecoration(
        hintText: 'Buscar dirección...',
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide.none,
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide.none,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: _onSearchChanged,
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
      if (context.findAncestorStateOfType<ParcelMapScreenState>() != null) {
        context.findAncestorStateOfType<ParcelMapScreenState>()!.setSearchBarActive(true);
      }

      // Verificar si es un par de coordenadas
      if (_isCoordinates(query)) {
        _handleCoordinates(query);
        return;
      }
    }

    // Si no son coordenadas, proceder con la búsqueda normal
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      
      setState(() => _isLoading = true);
      final results = await _searchService.searchAddress(query);
      
      if (!mounted) return;
      
      setState(() {
        _results = results;
        _isLoading = false;
        _errorMessage = null;
      });
    });
  }

  bool _isCoordinates(String query) {
    // Pattern for coordinates: two decimal numbers separated by comma
    final coordPattern = RegExp(r'^[-]?\d+\.?\d*,\s*[-]?\d+\.?\d*$');
    return coordPattern.hasMatch(query);
  }

  void _handleCoordinates(String query) {
    final coords = query.split(',').map((s) => double.tryParse(s.trim())).toList();
    
    if (coords.length == 2 && coords[0] != null && coords[1] != null) {
      final lat = coords[0]!;
      final lon = coords[1]!;

      // Validar rangos de coordenadas
      if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
        setState(() {
          _errorMessage = null;
          _results = [
            SearchResult(
              name: 'Coordenadas',
              address: '$lat, $lon',
              latitude: lat,
              longitude: lon,
            )
          ];
        });
      } else {
        setState(() {
          _errorMessage = 'Coordenadas fuera de rango';
          _results = [];
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Formato inválido. Use: latitud, longitud';
        _results = [];
      });
    }
  }
}
