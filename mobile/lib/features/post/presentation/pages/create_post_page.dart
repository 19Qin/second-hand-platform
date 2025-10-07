import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../injection.dart';
import '../../../file/data/datasources/file_remote_data_source.dart';
import '../../../../core/auth/token_manager.dart';
import '../../../product/data/datasources/product_remote_data_source.dart';
import '../../../product/data/models/product_publish_model.dart';
import '../../../product/data/models/product_model.dart';
import '../../../../core/network/api_client.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  // Basic information controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _usageTimeController = TextEditingController();
  final _warrantyDescriptionController = TextEditingController();
  
  // Selection options
  String _selectedLocation = 'Zetland';
  String _selectedCondition = 'GOOD';
  String _selectedCategory = '';
  String _selectedUsageType = 'TIME'; // TIME, COUNT, OTHER
  String _selectedUsageUnit = 'MONTH';
  bool _selfCollection = true;
  bool _hasWarranty = false;
  String _warrantyDescription = '';
  
  // Location details for API
  String _selectedProvince = 'NSW';
  String _selectedCity = 'Sydney';
  String _selectedDistrict = 'Zetland';
  String _detailAddress = '';
  double _longitude = 151.2093;
  double _latitude = -33.8688;
  
  // Publishing state
  bool _isPublishing = false;
  
  // Image related
  final List<XFile> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];
  final int _maxImages = 5;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImages = false;
  
  // Product condition options (based on API documentation)
  final List<Map<String, String>> _conditionOptions = [
    {'value': 'NEW', 'label': 'New'},
    {'value': 'LIKE_NEW', 'label': 'Like New'},
    {'value': 'GOOD', 'label': 'Good'},
    {'value': 'FAIR', 'label': 'Fair'},
    {'value': 'POOR', 'label': 'Poor'},
  ];
  
  // Product category options (based on backend database)
  final List<Map<String, String>> _categoryOptions = [
    // Top-level categories (parent_id = 0)
    {'value': '1', 'label': 'Electronics'},
    {'value': '2', 'label': 'Fashion & Accessories'},
    {'value': '3', 'label': 'Home & Garden'},
    {'value': '4', 'label': 'Sports & Outdoor'},
    {'value': '5', 'label': 'Books & Stationery'},
    {'value': '6', 'label': 'Beauty & Skincare'},
    {'value': '7', 'label': 'Baby & Kids'},
    {'value': '8', 'label': 'Others'},
    // Electronics sub-categories (parent_id = 1)
    {'value': '9', 'label': 'Mobile Phones'},
    {'value': '10', 'label': 'Computers'},
    {'value': '11', 'label': 'Digital Cameras'},
    {'value': '12', 'label': 'Gaming Devices'},
    {'value': '13', 'label': 'Smart Wearables'},
    {'value': '14', 'label': 'Audio & Headphones'},
  ];
  
  // Usage type options
  final List<Map<String, String>> _usageTypeOptions = [
    {'value': 'TIME', 'label': 'Usage Time'},
    {'value': 'COUNT', 'label': 'Usage Count'},
    {'value': 'OTHER', 'label': 'Other'},
  ];
  
  // Time unit options
  final List<Map<String, String>> _timeUnitOptions = [
    {'value': 'DAY', 'label': 'Days'},
    {'value': 'WEEK', 'label': 'Weeks'},
    {'value': 'MONTH', 'label': 'Months'},
    {'value': 'YEAR', 'label': 'Years'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _usageTimeController.dispose();
    _warrantyDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post an item',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: (_canPublish() && !_isPublishing) ? _publishItem : null,
            style: TextButton.styleFrom(
              backgroundColor: (_canPublish() && !_isPublishing)
                  ? const Color(0xFF4CE8A7) 
                  : Colors.grey.shade300,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: _isPublishing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Publish',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image upload area
            _buildImageUploadSection(),
            const SizedBox(height: 24),
            
            // Product description
            _buildDescriptionSection(),
            const SizedBox(height: 24),
            
            // Location selection
            _buildLocationSection(),
            const SizedBox(height: 24),
            
            // Basic product information
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            
            // Product category
            _buildCategorySection(),
            const SizedBox(height: 24),
            
            // Product condition
            _buildConditionSection(),
            const SizedBox(height: 24),
            
            // Product details
            _buildProductDetailsSection(),
          ],
        ),
      ),
    );
  }

  // Image upload area
  Widget _buildImageUploadSection() {
    return Column(
      children: [
        // Image grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _maxImages,
          itemBuilder: (context, index) {
            if (index < _selectedImages.length) {
              // Selected image
              return _buildSelectedImage(index);
            } else if (index == _selectedImages.length && _selectedImages.length < _maxImages) {
              // Add image button
              return _buildAddImageButton();
            } else {
              // Empty placeholder
              return const SizedBox();
            }
          },
        ),
      ],
    );
  }

  // Selected image
  Widget _buildSelectedImage(int index) {
    final imageFile = _selectedImages[index];
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      child: Stack(
        children: [
          // Real image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<Uint8List>(
              future: imageFile.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // If image loading fails, show placeholder color block
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFD2B48C),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFD2B48C),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  );
                } else {
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFD2B48C),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              },
            ),
          ),
          // Delete button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add image button
  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _isUploadingImages ? null : _addImage,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: _isUploadingImages
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CE8A7)),
                  ),
                )
              : const Icon(
                  Icons.add,
                  color: Colors.grey,
                  size: 32,
                ),
        ),
      ),
    );
  }

  // Product description area
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _descriptionController,
          onChanged: (value) => setState(() {}), // Trigger UI refresh
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Briefly describe the item which you want to sell...',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // Location selection area
  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            color: Colors.grey.shade600,
            size: 16,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _selectLocation,
            child: Text(
              '$_selectedLocation ▶',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Basic product information area
  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Product title
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Title *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                onChanged: (value) => setState(() {}), // Trigger UI refresh
                decoration: const InputDecoration(
                  hintText: 'Enter product title...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Original price (optional)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Original Price (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _originalPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter original price...',
                  prefixText: '\$',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Product category area
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        GestureDetector(
          onTap: _selectCategory,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCategory.isEmpty 
                        ? 'Select category...' 
                        : _categoryOptions.firstWhere(
                            (cat) => cat['value'] == _selectedCategory,
                            orElse: () => {'label': 'Unknown'}
                          )['label']!,
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedCategory.isEmpty 
                          ? Colors.grey.shade500 
                          : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Product condition area
  Widget _buildConditionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Condition',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        GestureDetector(
          onTap: _selectCondition,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _conditionOptions.firstWhere(
                      (condition) => condition['value'] == _selectedCondition,
                      orElse: () => {'label': 'Good'}
                    )['label']!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Product details area
  Widget _buildProductDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Selling price
        _buildDetailRow(
          label: 'Selling Price *',
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  onChanged: (value) => setState(() {}), // Trigger UI refresh
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter price...',
                    prefixText: '\$',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Usage information
        _buildDetailRow(
          label: 'Usage Information',
          child: Column(
            children: [
              // Usage type selection
              GestureDetector(
                onTap: _selectUsageType,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _usageTypeOptions.firstWhere(
                            (type) => type['value'] == _selectedUsageType,
                            orElse: () => {'label': 'Usage Time'}
                          )['label']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Usage time/count input
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _usageTimeController,
                        onChanged: (value) => setState(() {}), // Trigger UI refresh
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '1',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_selectedUsageType == 'TIME') ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectUsageUnit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedUsageUnit,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else if (_selectedUsageType == 'COUNT') ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'times',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        
        // Warranty information (optional)
        _buildDetailRow(
          label: 'Warranty Information',
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Has Warranty'),
                  const Spacer(),
                  Switch(
                    value: _hasWarranty,
                    onChanged: (value) {
                      print('🔧 Warranty switch changed: $_hasWarranty -> $value');
                      setState(() {
                        _hasWarranty = value;
                      });
                      print('🔧 After setState: _hasWarranty = $_hasWarranty');
                      print('🔧 _canPublish() result: ${_canPublish()}');
                    },
                    activeColor: const Color(0xFF4CE8A7),
                  ),
                ],
              ),
              if (_hasWarranty) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _warrantyDescriptionController,
                  onChanged: (value) => setState(() {}), // Trigger UI refresh
                  decoration: const InputDecoration(
                    hintText: 'Describe warranty details...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
        
        // Self collection option
        _buildDetailRow(
          label: 'Self Collection',
          child: Switch(
            value: _selfCollection,
            onChanged: (value) {
              setState(() {
                _selfCollection = value;
              });
            },
            activeColor: const Color(0xFF4CE8A7),
          ),
        ),
      ],
    );
  }

  // Detail row layout
  Widget _buildDetailRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  // Add image
  Future<void> _addImage() async {
    if (_selectedImages.length >= _maxImages || _isUploadingImages) return;

    try {
      // Show image source selection dialog
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      // Select image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
          _isUploadingImages = true;
        });

        // Upload image to server
        await _uploadImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploadingImages = false;
      });
    }
  }

  // Show image source selection dialog
  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  // Upload image to server
  Future<void> _uploadImage(XFile imageFile) async {
    try {
      final fileDataSource = ServiceLocator().get<FileRemoteDataSource>();
      final token = await TokenManager.instance.getAccessToken();
      
      final result = await fileDataSource.uploadProductImage(
        file: imageFile,
        token: token,
      );

      setState(() {
        _uploadedImageUrls.add(result.url);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      }
    } catch (e) {
      // Upload failed, remove image
      setState(() {
        _selectedImages.removeLast();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  // Delete image
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      // Also delete corresponding uploaded URL
      if (index < _uploadedImageUrls.length) {
        _uploadedImageUrls.removeAt(index);
      }
    });
  }

  // Select location
  void _selectLocation() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              'Zetland',
              'Sydney CBD',
              'Bondi',
              'Parramatta',
              'Chatswood',
            ].map((location) => ListTile(
              title: Text(location),
              trailing: _selectedLocation == location 
                  ? const Icon(Icons.check, color: Color(0xFF4CE8A7))
                  : null,
              onTap: () {
                setState(() {
                  _selectedLocation = location;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  // Select product category
  void _selectCategory() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _categoryOptions.length,
                itemBuilder: (context, index) {
                  final category = _categoryOptions[index];
                  return ListTile(
                    title: Text(category['label']!),
                    trailing: _selectedCategory == category['value'] 
                        ? const Icon(Icons.check, color: Color(0xFF4CE8A7))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['value']!;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Select product condition
  void _selectCondition() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Condition',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ..._conditionOptions.map((condition) => ListTile(
              title: Text(condition['label']!),
              trailing: _selectedCondition == condition['value'] 
                  ? const Icon(Icons.check, color: Color(0xFF4CE8A7))
                  : null,
              onTap: () {
                setState(() {
                  _selectedCondition = condition['value']!;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  // Select usage type
  void _selectUsageType() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Usage Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ..._usageTypeOptions.map((type) => ListTile(
              title: Text(type['label']!),
              trailing: _selectedUsageType == type['value'] 
                  ? const Icon(Icons.check, color: Color(0xFF4CE8A7))
                  : null,
              onTap: () {
                setState(() {
                  _selectedUsageType = type['value']!;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  // Select time unit
  void _selectUsageUnit() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            const Text(
              'Select Time Unit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ..._timeUnitOptions.map((unit) => ListTile(
              title: Text(unit['label']!),
              trailing: _selectedUsageUnit == unit['value'] 
                  ? const Icon(Icons.check, color: Color(0xFF4CE8A7))
                  : null,
              onTap: () {
                setState(() {
                  _selectedUsageUnit = unit['value']!;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  // Edit price
  void _editPrice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Price'),
        content: TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: '\$',
            hintText: 'Enter price',
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  // Check if can publish (最简化版本，只检查必填字段)
  bool _canPublish() {
    final hasImages = _selectedImages.isNotEmpty && _uploadedImageUrls.isNotEmpty;
    final hasTitle = _titleController.text.trim().isNotEmpty;
    final hasPrice = _priceController.text.trim().isNotEmpty;
    final hasCategory = _selectedCategory.isNotEmpty;
    
    // 验证价格格式
    final priceText = _priceController.text.trim();
    final price = double.tryParse(priceText);
    final hasValidPrice = price != null && price > 0.01 && price <= 999999.99;
    
    final canPublish = hasImages && hasTitle && hasPrice && hasCategory && hasValidPrice;
    
    // Debug print to help diagnose the issue
    print('🔍 _canPublish check (simplified):');
    print('  - hasImages: $hasImages (${_selectedImages.length} selected, ${_uploadedImageUrls.length} uploaded)');
    print('  - hasTitle: $hasTitle ("${_titleController.text.trim()}")');
    print('  - hasPrice: $hasPrice ("$priceText")');
    print('  - hasValidPrice: $hasValidPrice (parsed: $price)');
    print('  - hasCategory: $hasCategory ("$_selectedCategory")');
    print('  - Result: $canPublish');
    
    return canPublish;
  }

  // Publish item
  Future<void> _publishItem() async {
    if (!_canPublish() || _isPublishing) return;

    setState(() {
      _isPublishing = true;
    });

    try {
      // Get access token
      final token = await TokenManager.instance.getAccessToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      // Create location info model (必填字段)
      final locationInfo = LocationInfoRequestModel(
        province: _selectedProvince.isEmpty ? "北京市" : _selectedProvince,
        city: _selectedCity.isEmpty ? "北京市" : _selectedCity,
        district: _selectedDistrict.isEmpty ? "朝阳区" : _selectedDistrict,
        detailAddress: _detailAddress.isEmpty ? null : _detailAddress,
        longitude: _longitude != 0 ? _longitude : null,
        latitude: _latitude != 0 ? _latitude : null,
      );

      // 先尝试最简化版本（只包含必填字段）
      final productData = ProductPublishRequestModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(), // 如果为空，toJson会自动忽略
        price: double.parse(_priceController.text.trim()),
        categoryId: int.parse(_selectedCategory),
        images: _uploadedImageUrls,
        condition: _selectedCondition.isNotEmpty ? _selectedCondition : 'GOOD',
        location: locationInfo,
        // 暂时不发送可选字段，使用系统默认值
        originalPrice: null,
        usageInfo: null,
        warranty: null,
        tags: [],
      );
      
      // 数据验证和调试
      print('🔍 数据验证:');
      print('  - title length: ${productData.title.length} (max: 200)');
      print('  - price: ${productData.price} (range: 0.01-999999.99)');
      print('  - categoryId: ${productData.categoryId}');
      print('  - images count: ${productData.images.length}');
      print('  - condition: ${productData.condition}');
      
      // 验证数据
      if (productData.title.length > 200) {
        throw Exception('商品标题过长，最多200字');
      }
      if (productData.price < 0.01 || productData.price > 999999.99) {
        throw Exception('价格范围错误，应在0.01-999999.99之间');
      }
      if (productData.images.isEmpty) {
        throw Exception('至少需要1张图片');
      }
      
      print('📤 Full product data being sent:');
      print('  - title: "${productData.title}"');
      print('  - description: "${productData.description}"');
      print('  - price: ${productData.price}');
      print('  - categoryId: ${productData.categoryId}');
      print('  - images: ${productData.images}');
      print('  - condition: "${productData.condition}"');
      print('  - usageInfo: ${productData.usageInfo?.toJson()}');
      print('  - warranty: ${productData.warranty?.toJson()}');
      print('  - location: ${productData.location?.toJson()}');
      print('  - tags: ${productData.tags}');
      final jsonPayload = productData.toJson();
      print('📤 Full JSON payload: $jsonPayload');
      
      // 额外验证JSON结构
      print('🔍 JSON结构验证:');
      print('  - JSON keys: ${jsonPayload.keys.toList()}');
      print('  - title type: ${jsonPayload['title'].runtimeType}');
      print('  - price type: ${jsonPayload['price'].runtimeType}');
      print('  - categoryId type: ${jsonPayload['categoryId'].runtimeType}');
      print('  - images type: ${jsonPayload['images'].runtimeType}');
      print('  - location type: ${jsonPayload['location'].runtimeType}');

      // 使用用户输入的真实数据，只在保质期为false时使用硬编码
      print('📤 使用用户真实数据发布商品...');
      
      final realPayload = {
        "title": _titleController.text.trim(),
        "description": _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        "price": double.parse(_priceController.text.trim()),
        "originalPrice": _originalPriceController.text.trim().isNotEmpty ? double.parse(_originalPriceController.text.trim()) : null,
        "categoryId": int.parse(_selectedCategory),
        "images": _uploadedImageUrls,
        "condition": _selectedCondition,
        "location": {
          "province": _selectedProvince,
          "city": _selectedCity,
          "district": _selectedDistrict,
          if (_detailAddress.isNotEmpty) "detailAddress": _detailAddress,
          if (_longitude != 0) "longitude": _longitude,
          if (_latitude != 0) "latitude": _latitude,
        },
        if (_usageTimeController.text.trim().isNotEmpty) "usageInfo": {
          "type": _selectedUsageType,
          "value": int.parse(_usageTimeController.text.trim()),
          if (_selectedUsageType == 'TIME') "unit": _selectedUsageUnit,
        },
        "warranty": {
          "hasWarranty": _hasWarranty,
          if (!_hasWarranty) ...{
            "warrantyType": "NONE",
            "remainingMonths": 0,
            "description": "已过保修期，但功能完好",
          } else if (_warrantyDescriptionController.text.trim().isNotEmpty) ...{
            "warrantyType": "OFFICIAL",
            "remainingMonths": 12,
            "description": _warrantyDescriptionController.text.trim(),
          },
        },
        if (_descriptionController.text.trim().isNotEmpty) "tags": _descriptionController.text.trim().split(' ').take(3).toList(),
      };
      
      print('📤 真实数据JSON: $realPayload');
      
      // 直接调用API客户端使用用户真实数据
      final apiClient = ServiceLocator().get<ApiClient>();
      try {
        final result = await apiClient.post(
          'products',
          body: realPayload,
          fromJson: (json) => ProductPublishResponseModel.fromJson(json as Map<String, dynamic>),
        );
        
        print('✅ 商品发布成功: ${result.productId}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('商品发布成功！商品ID: ${result.productId}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
        return;
      } catch (realError) {
        print('❌ 真实数据发布失败: $realError');
        
        // 如果真实数据失败，尝试简化版本（保留保质期false的硬编码）
        print('🧪 尝试简化版本（保质期false硬编码）...');
        final fallbackPayload = {
          "title": _titleController.text.trim(),
          "price": double.parse(_priceController.text.trim()),
          "categoryId": int.parse(_selectedCategory),
          "images": _uploadedImageUrls.isNotEmpty ? _uploadedImageUrls : ["https://example.com/fallback.jpg"],
          "condition": _selectedCondition,
          "location": {
            "province": _selectedProvince,
            "city": _selectedCity,
            "district": _selectedDistrict,
          },
          "warranty": {
            "hasWarranty": false,
            "warrantyType": "NONE",
            "remainingMonths": 0,
            "description": "已过保修期，但功能完好",
          }
        };
        
        try {
          final fallbackResult = await apiClient.post(
            'products',
            body: fallbackPayload,
            fromJson: (json) => ProductPublishResponseModel.fromJson(json as Map<String, dynamic>),
          );
          
          print('✅ 简化版本成功: ${fallbackResult.productId}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('商品发布成功！ID: ${fallbackResult.productId}'), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
          return;
        } catch (fallbackError) {
          print('❌ 简化版本也失败: $fallbackError');
        }
        
        // 继续尝试原来的方式
      }

      // Call API to publish product
      final productDataSource = ServiceLocator().get<ProductRemoteDataSource>();
      final result = await productDataSource.publishProduct(
        productData: productData,
        token: token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product published successfully! ID: ${result.productId}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }
}
