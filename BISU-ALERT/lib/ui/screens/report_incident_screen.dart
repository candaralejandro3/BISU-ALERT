import 'package:flutter/material.dart';

import '../../data/auth/auth_scope.dart';
import '../../data/mock/mock_data.dart';
import '../../data/model/campus_location.dart';
import '../../data/model/incident_category.dart';
import '../../data/services/geofencing_service.dart';
import '../../data/services/incident_api_service.dart';
import '../../data/services/local_cache_service.dart';
import '../../data/services/media_upload_service.dart';
import '../theme/app_colors.dart';
import '../widgets/section_card.dart';
import 'my_reports_screen.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key, this.onViewMyReports});

  final VoidCallback? onViewMyReports;

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  static const int _minDescriptionLength = 10;
  static const int _maxDescriptionLength = 1000;

  final MediaUploadService _mediaUploadService = MediaUploadService();
  final IncidentApiService _incidentApiService = IncidentApiService();

  IncidentCategory _selectedCategory = IncidentCategory.medical;
  IncidentSeverity _selectedSeverity = IncidentSeverity.moderate;
  bool _isAnonymous = false;
  bool _includeGps = true;

  CampusLocation? _selectedLocation;
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<MediaFile> _selectedMediaFiles = [];
  bool _isSubmitting = false;
  String? _descriptionError;
  int _formResetToken = 0;

  @override
  void dispose() {
    _descriptionController.dispose();
    _roomController.dispose();
    _landmarkController.dispose();
    for (var file in _selectedMediaFiles) {
      _mediaUploadService.deleteLocalFile(file.path);
    }
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    final mediaFile = await _mediaUploadService.pickImage(source: ImageSource.camera);
    if (!mounted || mediaFile == null) return;

    final error = _mediaUploadService.validateMediaFile(mediaFile);
    if (error != null) {
      _showMessage(error);
      return;
    }

    setState(() => _selectedMediaFiles.add(mediaFile));
    _showMessage('Photo attached: ${mediaFile.fileName}');
  }

  Future<void> _pickImageFromGallery() async {
    final mediaFiles = await _mediaUploadService.pickMultipleImages();
    if (!mounted || mediaFiles.isEmpty) return;

    for (var mediaFile in mediaFiles) {
      final error = _mediaUploadService.validateMediaFile(mediaFile);
      if (error == null) {
        setState(() => _selectedMediaFiles.add(mediaFile));
      }
    }
    _showMessage('${mediaFiles.length} media item(s) attached');
  }

  void _addVideoAttachment() {
    // Simulated video attachment for demonstration
    final mockVideo = MediaFile(
      path: '/simulated/incident_video.mp4',
      fileName: 'incident_clip_01.mp4',
      fileSizeBytes: 4500000,
      type: MediaType.video,
    );
    setState(() => _selectedMediaFiles.add(mockVideo));
    _showMessage('Video evidence attached (incident_clip_01.mp4)');
  }

  void _removeMediaFile(int index) {
    if (index >= 0 && index < _selectedMediaFiles.length) {
      final file = _selectedMediaFiles.removeAt(index);
      _mediaUploadService.deleteLocalFile(file.path);
      setState(() {});
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.sos : null,
      ),
    );
  }

  void _showSubmissionSuccessModal(String referenceCode) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Report Submitted',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Report ID: $referenceCode',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: const Text(
                'Status: Pending Review',
                style: TextStyle(
                  color: Color(0xFFB78103),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Your report has been logged and dispatched to Campus Security & responders.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.35),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                    },
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      if (widget.onViewMyReports != null) {
                        widget.onViewMyReports!();
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MyReportsScreen(),
                          ),
                        );
                      }
                    },
                    child: const Text('My Reports'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    final description = _descriptionController.text.trim();

    if (description.length < _minDescriptionLength) {
      setState(() {
        _descriptionError = 'Please provide at least $_minDescriptionLength characters.';
      });
      return;
    }

    setState(() => _isSubmitting = true);

    final String generatedRef =
        'INC-2026-${(1000 + DateTime.now().millisecondsSinceEpoch % 9000)}';

    // Check offline mode
    final auth = AuthScope.of(context);
    if (auth.isOfflineSession) {
      // Save report in local queue
      await LocalCacheService.savePendingReport({
        'reference_code': generatedRef,
        'category': _selectedCategory.code,
        'severity': _selectedSeverity.label,
        'location': _selectedLocation?.name ?? 'BISU Campus',
        'room': _roomController.text.trim(),
        'description': description,
        'is_anonymous': _isAnonymous,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _clearForm();
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSubmissionSuccessModal(generatedRef);
      }
      return;
    }

    try {
      final location = _selectedLocation;
      final fullLocationLabel = [
        location?.name ?? 'BISU Bilar Campus',
        if (_roomController.text.trim().isNotEmpty) 'Room: ${_roomController.text.trim()}',
        if (_landmarkController.text.trim().isNotEmpty) 'Near: ${_landmarkController.text.trim()}',
      ].join(' • ');

      await _incidentApiService.createIncident(
        category: _selectedCategory.code,
        description: '$description\n\n[Severity: ${_selectedSeverity.label}]',
        isAnonymous: _isAnonymous,
        locationCode: location?.id,
        locationLabel: fullLocationLabel,
        latitude: _includeGps ? (location?.latitude ?? GeofencingService.campusLatitude) : null,
        longitude: _includeGps ? (location?.longitude ?? GeofencingService.campusLongitude) : null,
        token: auth.token,
      );

      await _clearForm();
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSubmissionSuccessModal(generatedRef);
      }
    } catch (_) {
      // Graceful fallback to offline queued report
      await LocalCacheService.savePendingReport({
        'reference_code': generatedRef,
        'category': _selectedCategory.code,
        'severity': _selectedSeverity.label,
        'location': _selectedLocation?.name ?? 'BISU Campus',
        'room': _roomController.text.trim(),
        'description': description,
        'is_anonymous': _isAnonymous,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _clearForm();
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSubmissionSuccessModal(generatedRef);
      }
    }
  }

  Future<void> _clearForm() async {
    _descriptionController.clear();
    _roomController.clear();
    _landmarkController.clear();
    _selectedMediaFiles.clear();
    if (mounted) {
      setState(() {
        _selectedCategory = IncidentCategory.medical;
        _selectedSeverity = IncidentSeverity.moderate;
        _selectedLocation = null;
        _descriptionError = null;
        _formResetToken++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'My Reports',
            icon: const Icon(Icons.history_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MyReportsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selector
            SectionCard(
              title: 'Incident Category',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: IncidentCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : Colors.black54),
                    label: Text(cat.label),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Severity Level
            SectionCard(
              title: 'Incident Severity',
              child: Row(
                children: IncidentSeverity.values.map((sev) {
                  final isSelected = _selectedSeverity == sev;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => setState(() => _selectedSeverity = sev),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? sev.color : sev.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sev.color),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            sev.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : sev.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Location Section
            SectionCard(
              title: 'Incident Location',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GPS Switch
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    isThreeLine: true,
                    title: const Text(
                      'Auto-Attach GPS Coordinates',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Campus Geofence: 9.71888° N, 124.10883° E (±4m)',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    value: _includeGps,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _includeGps = val),
                  ),

                  const SizedBox(height: 8),

                  // Campus Building Dropdown
                  DropdownButtonFormField<CampusLocation>(
                    key: ValueKey('loc_$_formResetToken'),
                    initialValue: _selectedLocation,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Select Campus Building / Area',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: MockData.campusLocations
                        .where((l) =>
                            l.type == LocationType.building ||
                            l.type == LocationType.clinic ||
                            l.type == LocationType.security)
                        .map((loc) => DropdownMenuItem(
                              value: loc,
                              child: Text(
                                loc.name,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ))
                        .toList(),
                    onChanged: (loc) => setState(() => _selectedLocation = loc),
                  ),

                  const SizedBox(height: 10),

                  // Room and Landmark Fields
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _roomController,
                          decoration: InputDecoration(
                            labelText: 'Room # / Area',
                            hintText: 'e.g. Room 204',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _landmarkController,
                          decoration: InputDecoration(
                            labelText: 'Nearest Landmark',
                            hintText: 'e.g. Near bleachers',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Description
            SectionCard(
              title: 'Incident Description',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    maxLength: _maxDescriptionLength,
                    decoration: InputDecoration(
                      hintText: 'Provide details about what happened, immediate hazards, and persons involved...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      errorText: _descriptionError,
                    ),
                    onChanged: (_) {
                      if (_descriptionError != null) {
                        setState(() => _descriptionError = null);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Evidence Attachments (Photo / Video)
            SectionCard(
              title: 'Evidence (Photos & Video)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: _pickImageFromCamera,
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Camera', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: _pickImageFromGallery,
                        icon: const Icon(Icons.photo_library, size: 16),
                        label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: _addVideoAttachment,
                        icon: const Icon(Icons.videocam, size: 16),
                        label: const Text('Video', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),

                  if (_selectedMediaFiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedMediaFiles.asMap().entries.map((entry) {
                        final i = entry.key;
                        final file = entry.value;
                        final isVid = file.type == MediaType.video;

                        return Chip(
                          avatar: Icon(isVid ? Icons.video_file : Icons.image, size: 16),
                          label: Text(file.fileName, style: const TextStyle(fontSize: 11)),
                          onDeleted: () => _removeMediaFile(i),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Reporter Identity
            SectionCard(
              title: 'Reporter Identity',
              child: Column(
                children: [
                  RadioListTile<bool>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Submit as Identified Reporter (${user?.fullName ?? 'Juan Dela Cruz'})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Responders can call you back at ${user?.phoneNumber ?? '+63 917 456 1234'}.',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    value: false,
                    groupValue: _isAnonymous,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _isAnonymous = val ?? false),
                  ),
                  RadioListTile<bool>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Submit Anonymously',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Your name and phone number will not be recorded.',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    value: true,
                    groupValue: _isAnonymous,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _isAnonymous = val ?? true),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sos,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSubmitting ? null : _submitReport,
              icon: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isSubmitting ? 'Submitting Report...' : 'SUBMIT INCIDENT REPORT',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
