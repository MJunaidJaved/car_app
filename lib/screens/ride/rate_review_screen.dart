import 'package:flutter/material.dart';
import '../../widgets/app_widgets.dart';

class _C {
  static const primary   = Color(0xFF414833); // Primary Action
  static const dark      = Color(0xFF414833); // Header/Black
  static const accent    = Color(0xFF737A5D); // Accent
  static const black     = Color(0xFF414833);
  static const white     = Color(0xFFF5E3D2);
  static const textDark  = Color(0xFF414833);
  static const textMuted = Color(0xFF737A5D);
  static const bg        = Color(0xFFF5E3D2);
}

class RateReviewScreen extends StatefulWidget {
  const RateReviewScreen({super.key});

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends State<RateReviewScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _selectedTags = [];
  
  final List<String> _tags = ["Great driver", "On time", "Safe driving", "Clean car", "Friendly"];

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Custom Header Row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCCBFA3), width: 1)),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.black, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('Rate Your Ride', style: TextStyle(color: _C.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              CircleAvatar(radius: 44, backgroundColor: _C.primary.withOpacity(0.1), child: const Text('AH', style: TextStyle(color: _C.primary, fontSize: 24, fontWeight: FontWeight.w800))),
              const SizedBox(height: 16),
              const Text('How was your ride with Ahmed?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _C.textDark)),
              const SizedBox(height: 8),
              const Text('Your feedback helps us improve.', style: TextStyle(color: _C.textMuted, fontSize: 14)),
              
              const SizedBox(height: 40),
              
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: index < _rating ? _C.primary : const Color(0xFFCCBFA3),
                        size: 44,
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 32),
              
              // Tags
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _tags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () => _toggleTag(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? _C.primary : _C.white,
                        border: Border.all(color: isSelected ? _C.primary : const Color(0xFFCCBFA3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(color: isSelected ? _C.white : _C.textMuted, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
              // Text field
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _C.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 15, color: _C.textDark, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    hintText: 'Write your experience here...',
                    hintStyle: TextStyle(color: _C.textMuted),
                    border: InputBorder.none,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your feedback!')));
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.primary,
                    foregroundColor: _C.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}



