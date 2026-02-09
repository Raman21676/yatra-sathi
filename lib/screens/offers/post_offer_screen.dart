import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class PostOfferScreen extends StatefulWidget {
  final VehicleOffer? offerToEdit;
  
  const PostOfferScreen({super.key, this.offerToEdit});

  @override
  State<PostOfferScreen> createState() => _PostOfferScreenState();
}

class _PostOfferScreenState extends State<PostOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _seatsController = TextEditingController();
  final _fareController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();

  String _vehicleType = 'Car';
  DateTime _leaveTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _reachTime = DateTime.now().add(const Duration(hours: 3));
  
  File? _vehiclePhoto;
  bool _isUploading = false;
  double _uploadProgress = 0;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService();

  bool get isEditMode => widget.offerToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _initializeForEdit();
    } else {
      _initializeDefaults();
    }
  }

  void _initializeDefaults() {
    // Set contact number to user's phone
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _contactController.text = user.phone;
    }
  }

  void _initializeForEdit() {
    final offer = widget.offerToEdit!;
    _vehicleType = offer.vehicleType;
    _vehicleNumberController.text = offer.vehicleNumber;
    _seatsController.text = offer.seatsTotal.toString();
    _fareController.text = offer.fare.toString();
    _fromController.text = offer.fromLocation;
    _toController.text = offer.toLocation;
    _descriptionController.text = offer.description ?? '';
    _contactController.text = offer.contactNumber;
    _leaveTime = offer.leaveTime;
    _reachTime = offer.reachTime;
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _seatsController.dispose();
    _fareController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _vehiclePhoto = File(pickedFile.path);
        });
      }
    } catch (e) {
      Helpers.showSnackBar(context, 'Failed to pick image: $e', isError: true);
    }
  }

  Future<void> _selectDateTime(bool isLeaveTime) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isLeaveTime ? _leaveTime : _reachTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isLeaveTime ? _leaveTime : _reachTime,
        ),
      );

      if (time != null) {
        setState(() {
          final newDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          
          if (isLeaveTime) {
            _leaveTime = newDateTime;
            // Auto-adjust reach time if needed
            if (_reachTime.isBefore(_leaveTime)) {
              _reachTime = _leaveTime.add(const Duration(hours: 2));
            }
          } else {
            if (newDateTime.isBefore(_leaveTime)) {
              Helpers.showSnackBar(
                context,
                'Arrival time must be after departure time',
                isError: true,
              );
              return;
            }
            _reachTime = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate photo for new offers
    if (!isEditMode && _vehiclePhoto == null) {
      Helpers.showSnackBar(
        context,
        'Please upload a vehicle photo',
        isError: true,
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      String? photoUrl;
      String? photoPublicId;

      // Upload photo if selected
      if (_vehiclePhoto != null) {
        final uploadResult = await _cloudinary.uploadImage(
          _vehiclePhoto!,
          folder: 'yatra_sathi/vehicles',
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );

        if (uploadResult != null) {
          photoUrl = uploadResult['url'];
          photoPublicId = uploadResult['public_id'];
        } else {
          throw Exception('Failed to upload vehicle photo');
        }
      }

      if (!mounted) return;

      final offerProvider = Provider.of<OfferProvider>(context, listen: false);

      if (isEditMode) {
        // Update existing offer
        final request = UpdateOfferRequest(
          vehicleType: _vehicleType,
          vehicleNumber: _vehicleNumberController.text.trim().toUpperCase(),
          vehiclePhoto: photoUrl,
          vehiclePhotoPublicId: photoPublicId,
          seatsTotal: int.parse(_seatsController.text.trim()),
          fare: double.parse(_fareController.text.trim()),
          fromLocation: _fromController.text.trim(),
          toLocation: _toController.text.trim(),
          leaveTime: _leaveTime,
          reachTime: _reachTime,
          description: _descriptionController.text.trim(),
          contactNumber: _contactController.text.trim(),
        );

        final success = await offerProvider.updateOffer(
          widget.offerToEdit!.id,
          request,
        );

        if (success && mounted) {
          Helpers.showSnackBar(context, 'Offer updated successfully');
          Navigator.pop(context);
        } else if (mounted) {
          Helpers.showSnackBar(
            context,
            offerProvider.error ?? 'Failed to update offer',
            isError: true,
          );
        }
      } else {
        // Create new offer
        final request = CreateOfferRequest(
          vehicleType: _vehicleType,
          vehicleNumber: _vehicleNumberController.text.trim().toUpperCase(),
          vehiclePhoto: photoUrl,
          seatsTotal: int.parse(_seatsController.text.trim()),
          fare: double.parse(_fareController.text.trim()),
          fromLocation: _fromController.text.trim(),
          toLocation: _toController.text.trim(),
          leaveTime: _leaveTime,
          reachTime: _reachTime,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          contactNumber: _contactController.text.trim(),
        );

        final offer = await offerProvider.createOffer(request);

        if (offer != null && mounted) {
          Helpers.showSnackBar(context, 'Ride posted successfully!');
          Navigator.pop(context);
        } else if (mounted) {
          Helpers.showSnackBar(
            context,
            offerProvider.error ?? 'Failed to create offer',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerProvider = Provider.of<OfferProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Ride' : 'Post a Ride'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(UIConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Photo Upload
                  Center(
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(
                            UIConstants.defaultRadius,
                          ),
                          border: Border.all(
                            color: Colors.grey[400]!,
                            style: BorderStyle.solid,
                          ),
                          image: _vehiclePhoto != null
                              ? DecorationImage(
                                  image: FileImage(_vehiclePhoto!),
                                  fit: BoxFit.cover,
                                )
                              : (isEditMode &&
                                      widget.offerToEdit?.vehiclePhoto != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        widget.offerToEdit!.vehiclePhoto,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                        ),
                        child: _vehiclePhoto == null &&
                                (!isEditMode ||
                                    widget.offerToEdit?.vehiclePhoto == null)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 48,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to upload vehicle photo',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (!isEditMode)
                                    Text(
                                      '* Required',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Vehicle Type
                  const Text(
                    'Vehicle Type',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.vehicleTypes.map((type) {
                      final isSelected = _vehicleType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: _isUploading
                            ? null
                            : (selected) {
                                if (selected) {
                                  setState(() {
                                    _vehicleType = type;
                                  });
                                }
                              },
                        selectedColor: const Color(UIConstants.primaryColor),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Vehicle Number
                  TextFormField(
                    controller: _vehicleNumberController,
                    enabled: !_isUploading,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Number *',
                      hintText: 'BA 1 KHA 1234',
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter vehicle number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Seats and Fare Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _seatsController,
                          enabled: !_isUploading,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Seats *',
                            hintText: '4',
                            prefixIcon: Icon(Icons.event_seat),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final seats = int.tryParse(value);
                            if (seats == null || seats < 1 || seats > 50) {
                              return '1-50 seats';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _fareController,
                          enabled: !_isUploading,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Fare per seat *',
                            hintText: '500',
                            prefixIcon: const Icon(Icons.money),
                            prefixText: '${NepalConstants.currencySymbol} ',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final fare = double.tryParse(value);
                            if (fare == null || fare < 0) {
                              return 'Invalid fare';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Route
                  TextFormField(
                    controller: _fromController,
                    enabled: !_isUploading,
                    decoration: InputDecoration(
                      labelText: 'From Location *',
                      hintText: 'Kathmandu',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (value) {
                          _fromController.text = value;
                        },
                        itemBuilder: (context) {
                          return AppConstants.popularLocations.map((location) {
                            return PopupMenuItem(
                              value: location,
                              child: Text(location),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter departure location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _toController,
                    enabled: !_isUploading,
                    decoration: InputDecoration(
                      labelText: 'To Location *',
                      hintText: 'Pokhara',
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (value) {
                          _toController.text = value;
                        },
                        itemBuilder: (context) {
                          return AppConstants.popularLocations.map((location) {
                            return PopupMenuItem(
                              value: location,
                              child: Text(location),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter destination';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Date and Time
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _isUploading ? null : () => _selectDateTime(true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Departure Time *',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              Helpers.formatDateTime(_leaveTime),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _isUploading ? null : () => _selectDateTime(false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Arrival Time *',
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            child: Text(
                              Helpers.formatDateTime(_reachTime),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_isUploading,
                    maxLines: 3,
                    maxLength: AppConstants.maxDescriptionLength,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Any additional information about the ride...',
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Contact Number
                  TextFormField(
                    controller: _contactController,
                    enabled: !_isUploading,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Contact Number *',
                      hintText: NepalConstants.phoneHint,
                      prefixIcon: const Icon(Icons.phone),
                      prefixText: '${NepalConstants.countryCode} ',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter contact number';
                      }
                      if (!Helpers.isValidNepalPhone(value)) {
                        return 'Invalid Nepal phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading || offerProvider.isLoading
                          ? null
                          : _submit,
                      child: _isUploading || offerProvider.isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(_isUploading
                                    ? 'Uploading ${(_uploadProgress * 100).toInt()}%'
                                    : 'Saving...'),
                              ],
                            )
                          : Text(
                              isEditMode ? 'Update Ride' : 'Post Ride',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
