import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/places_service.dart';
import '../utils/app_colors.dart';

class PlacesAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final ValueChanged<LatLng>? onPlaceSelected;

  const PlacesAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.onPlaceSelected,
  });

  @override
  State<PlacesAutocompleteField> createState() => _PlacesAutocompleteFieldState();
}

class _PlacesAutocompleteFieldState extends State<PlacesAutocompleteField> {
  final PlacesService _places = PlacesService();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlay;
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), _removeOverlay);
    }
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final query = widget.controller.text;
      if (query.trim().length < 2) {
        if (mounted) {
          setState(() {
            _suggestions = [];
            _loading = false;
          });
          _removeOverlay();
        }
        return;
      }

      if (mounted) setState(() => _loading = true);
      final results = await _places.autocomplete(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
      if (results.isNotEmpty && _focusNode.hasFocus) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();
    _overlay = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 40,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, color: AppColors.moss, size: 20),
                    title: Text(
                      item.description,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    onTap: () => _selectSuggestion(item),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    _removeOverlay();
    _focusNode.unfocus();

    final details = await _places.placeDetails(suggestion.placeId);
    if (!mounted || details == null) return;

    final label = details.formattedAddress.isNotEmpty
        ? details.formattedAddress
        : details.name;

    widget.controller.text = label;
    widget.onPlaceSelected?.call(LatLng(details.lat, details.lng));
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        validator: widget.validator,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon, color: AppColors.moss, size: 20),
          suffixIcon: _loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.sage),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.moss, width: 2),
          ),
        ),
      ),
    );
  }
}
