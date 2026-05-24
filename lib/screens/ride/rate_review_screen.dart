import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';



class RateReviewScreen extends StatefulWidget {
  const RateReviewScreen({super.key});

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends State<RateReviewScreen> {
  String? _dealId;
  bool _submitting = false;
  bool _loading = true;
  String _captainName = 'your captain';
  int _rating = 0;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _dealId = ModalRoute.of(context)?.settings.arguments as String?;
      await _loadDeal();
    });
  }

  Future<void> _loadDeal() async {
    if (_dealId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final deal = await Provider.of<FirestoreService>(context, listen: false).getDeal(_dealId!);
      if (mounted) {
        setState(() {
          _captainName = deal['captain']?['name'] ?? deal['ride']?['captainName'] ?? 'your captain';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }
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
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
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
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCCBFA3), width: 1)),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('Rate Your Ride', style: TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              CircleAvatar(radius: 44, backgroundColor: AppColors.primary.withOpacity(0.1), child: const Text('AH', style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w800))),
              const SizedBox(height: 16),
              Text('How was your ride with $_captainName?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 8),
              const Text('Your feedback helps us improve.', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              
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
                        color: index < _rating ? AppColors.primary : const Color(0xFFCCBFA3),
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
                        color: isSelected ? AppColors.primary : AppColors.white,
                        border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFCCBFA3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(color: isSelected ? AppColors.white : AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w700),
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
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    hintText: 'Write your experience here...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitting ? null : () async {
  if (_rating == 0) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a rating')));
    return;
  }
  setState(() => _submitting = true);
  try {
    if (_dealId != null) {
      final review = [
        _commentController.text.trim(),
        if (_selectedTags.isNotEmpty) _selectedTags.join(', '),
      ].where((s) => s.isNotEmpty).join(' · ');
      await Provider.of<FirestoreService>(context, listen: false).rateDeal(
        _dealId!,
        _rating,
        review,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your feedback!')));
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  } catch (e) {
    setState(() => _submitting = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
  }
},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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



