import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/auth/token_manager.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/update_user_profile_usecase.dart';
import '../../../file/data/datasources/file_remote_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  
  const EditProfilePage({Key? key, this.initialData}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  
  String? _selectedGender;
  DateTime? _selectedBirthday;
  String? _avatarUrl;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _originalUsername; // 保存原始用户名

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.initialData != null) {
      _originalUsername = widget.initialData!['username'] ?? '';
      _usernameController.text = _originalUsername ?? '';
      _emailController.text = widget.initialData!['email'] ?? '';
      _locationController.text = widget.initialData!['location'] ?? '';
      _bioController.text = widget.initialData!['bio'] ?? '';
      _avatarUrl = widget.initialData!['avatar'];
      
      // 设置性别
      int gender = widget.initialData!['gender'] ?? 0;
      if (gender == 1) {
        _selectedGender = 'male';
      } else if (gender == 2) {
        _selectedGender = 'female';
      } else {
        _selectedGender = 'unknown';
      }
      
      // 设置生日
      String? birthdayStr = widget.initialData!['birthday'];
      if (birthdayStr != null && birthdayStr.isNotEmpty) {
        try {
          _selectedBirthday = DateTime.parse(birthdayStr);
        } catch (e) {
          print('Error parsing birthday: $e');
        }
      }
    } else {
      // 如果没有传入数据，尝试从TokenManager获取基本用户信息
      _loadUserInfoFromTokenManager();
    }
  }

  Future<void> _loadUserInfoFromTokenManager() async {
    try {
      final tokenManager = TokenManager.instance;
      final userInfo = await tokenManager.getUserInfo();
      if (userInfo != null) {
        setState(() {
          _originalUsername = userInfo['username'] ?? '';
          _usernameController.text = _originalUsername ?? '';
          _emailController.text = userInfo['email'] ?? '';
          _avatarUrl = userInfo['avatar'];
          _selectedGender = 'unknown'; // Default gender
        });
      }
    } catch (e) {
      print('Failed to load user info from TokenManager: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    _showMaintenanceDialog();
  }

  Future<void> _uploadAvatar() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isUploading = true;
    });

    try {
      // 使用真实的API调用上传头像
      final apiClient = ApiClient();
      
      final bytes = await _selectedImage!.readAsBytes();
      final uri = Uri.parse('${apiClient.baseUrl}/user/avatar/upload');
      
      final request = http.MultipartRequest('POST', uri);
      
      // 获取文件扩展名并设置正确的Content-Type
      final filename = _selectedImage!.path.split('/').last;
      final extension = filename.split('.').last.toLowerCase();
      String contentType;
      
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg'; // 默认
      }
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType.parse(contentType),
        ),
      );
      
      final token = await TokenManager.instance.getAccessToken();
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['code'] == 200) {
          setState(() {
            _avatarUrl = jsonData['data']['url'];
          });
          _showSuccessMessage('头像上传成功');
        } else {
          _showErrorDialog(jsonData['message'] ?? '头像上传失败');
        }
      } else {
        _showErrorDialog('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('头像上传失败: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );
    
    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    _showMaintenanceDialog();
  }

  int _getGenderValue() {
    switch (_selectedGender) {
      case 'male':
        return 1;
      case 'female':
        return 2;
      default:
        return 0;
    }
  }

  String _getGenderText() {
    switch (_selectedGender) {
      case 'male':
        return '男';
      case 'female':
        return '女';
      default:
        return '未知';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF32C286),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '编辑资料',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF32C286)),
                    ),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(
                      color: Color(0xFF32C286),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像部分
              _buildAvatarSection(),
              
              const SizedBox(height: 30),
              
              // 基本信息
              _buildBasicInfoSection(),
              
              const SizedBox(height: 30),
              
              // 个人资料
              _buildPersonalInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF32C286),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? Image.network(
                              _avatarUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar();
                              },
                            )
                          : _buildDefaultAvatar(),
                ),
              ),
              if (_isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF32C286),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '点击相机图标更换头像',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[300],
      child: const Icon(
        Icons.person,
        size: 50,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '基本信息',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        // 用户名
        _buildTextField(
          controller: _usernameController,
          label: '用户名',
          hint: '请输入用户名',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入用户名';
            }
            if (value.trim().length < 2) {
              return '用户名至少2个字符';
            }
            if (value.trim().length > 20) {
              return '用户名不能超过20个字符';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // 邮箱
        _buildTextField(
          controller: _emailController,
          label: '邮箱',
          hint: '请输入邮箱地址（可选）',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return '请输入有效的邮箱地址';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '个人资料',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        // 性别选择
        _buildGenderSelector(),
        
        const SizedBox(height: 16),
        
        // 生日选择
        _buildBirthdaySelector(),
        
        const SizedBox(height: 16),
        
        // 位置
        _buildTextField(
          controller: _locationController,
          label: '位置',
          hint: '请输入所在位置（可选）',
        ),
        
        const SizedBox(height: 16),
        
        // 个人简介
        _buildTextField(
          controller: _bioController,
          label: '个人简介',
          hint: '介绍一下自己吧（可选）',
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF32C286), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '性别',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildGenderOption('unknown', '未知'),
              _buildDivider(),
              _buildGenderOption('male', '男'),
              _buildDivider(),
              _buildGenderOption('female', '女'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String value, String label) {
    final isSelected = _selectedGender == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? const Color(0xFF32C286) : Colors.black87,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check,
                color: Color(0xFF32C286),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey[200],
    );
  }

  Widget _buildBirthdaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '生日',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectBirthday,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  _selectedBirthday != null
                      ? '${_selectedBirthday!.year}年${_selectedBirthday!.month}月${_selectedBirthday!.day}日'
                      : '请选择生日（可选）',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedBirthday != null ? Colors.black87 : Colors.grey[400],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.build, color: Color(0xFF32C286)),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).maintenance),
          ],
        ),
        content: Text(AppLocalizations.of(context).maintenanceMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).ok),
          ),
        ],
      ),
    );
  }
}
