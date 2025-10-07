import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/root_shell.dart';
import 'package:mobile/injection.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../../../core/auth/token_manager.dart';
import 'login_page.dart';
import 'user_agreement_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _agree = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _smsCodeController = TextEditingController();

  // 控制密码是否可见
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  // 验证码相关状态
  bool _isLoadingSms = false;
  bool _canSendSms = true;
  int _countdownSeconds = 0;
  String? _smsId;

  // 注册状态
  bool _isRegistering = false;

  // 校验状态
  String? _nameError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmError;
  String? _smsCodeError;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateName);
    _phoneController.addListener(_validatePhone);
    _passwordController.addListener(_validatePassword);
    _confirmController.addListener(_validateConfirm);
    _smsCodeController.addListener(_validateSmsCode);
  }

  void _validateName() {
    setState(() {
      final name = _nameController.text;
      if (name.isEmpty) {
        _nameError = "Please enter username";
      } else if (name.length > 25) {
        _nameError = "Username cannot exceed 25 characters";
      } else {
        _nameError = null;
      }
    });
  }

  void _validatePhone() {
    setState(() {
      final v = _phoneController.text;
      if (v.isEmpty) {
        _phoneError = "Please enter phone";
      } else if (!RegExp(r'^[0-9]{10,11}$').hasMatch(v)) {
        _phoneError = "Please use correct number!";
      } else {
        _phoneError = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      final v = _passwordController.text;
      if (v.isEmpty) {
        _passwordError = "Please enter password";
      } else if (v.length < 8) {
        _passwordError = "Password must be at least 8 characters";
      } else if (v.length > 20) {
        _passwordError = "Password must be at most 20 characters";
      } else if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,20}$').hasMatch(v)) {
        _passwordError = "Password must contain letters and numbers";
      } else {
        _passwordError = null;
      }
    });
  }

  void _validateConfirm() {
    setState(() {
      final v = _confirmController.text;
      if (v.isEmpty) {
        _confirmError = "Please confirm password";
      } else if (v != _passwordController.text) {
        _confirmError = "Please recheck your password!";
      } else {
        _confirmError = null;
      }
    });
  }

  void _validateSmsCode() {
    setState(() {
      final v = _smsCodeController.text;
      if (v.isEmpty) {
        _smsCodeError = "Please enter verification code";
      } else if (!RegExp(r'^\d{4}$').hasMatch(v)) {
        _smsCodeError = "Please enter 4-digit code";
      } else {
        _smsCodeError = null;
      }
    });
  }

  // 发送验证码
  Future<void> _sendSmsCode() async {
    if (_phoneError != null || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number first')),
      );
      return;
    }

    setState(() {
      _isLoadingSms = true;
    });

    try {
      final authDataSource = ServiceLocator().get<AuthRemoteDataSource>();
      final response = await authDataSource.sendSmsCode(
        mobile: _phoneController.text,
        type: 'register',
      );

      setState(() {
        _smsId = response.smsId;
        _canSendSms = false;
        _countdownSeconds = 60;
      });

      // 开始倒计时
      _startCountdown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification code: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingSms = false;
      });
    }
  }

  // 倒计时
  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
        _startCountdown();
      } else if (mounted) {
        setState(() {
          _canSendSms = true;
        });
      }
    });
  }

  // 注册
  Future<void> _register() async {
    if (!_isFormValid) return;

    setState(() {
      _isRegistering = true;
    });

    try {
      final authDataSource = ServiceLocator().get<AuthRemoteDataSource>();
      final response = await authDataSource.register(
        username: _nameController.text,
        mobile: _phoneController.text,
        password: _passwordController.text,
        confirmPassword: _confirmController.text,
        smsCode: _smsCodeController.text,
        smsId: _smsId ?? '',
        agreeTerms: _agree,
      );

      if (mounted) {
        // 保存Token和用户信息
        await TokenManager.instance.saveTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          expiresIn: response.expiresIn,
          userInfo: {
            'username': response.user.username,
            'userId': response.user.userId,
            'mobile': response.user.mobile,
            'avatar': response.user.avatar,
          },
        );
        
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Success"),
            content: Text("Welcome ${response.user.username}! Registration successful!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 关闭弹窗
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const RootShell()),
                    (route) => false,
                  );
                },
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }

  bool get _isFormValid =>
      _nameError == null &&
      _phoneError == null &&
      _passwordError == null &&
      _confirmError == null &&
      _smsCodeError == null &&
      _nameController.text.isNotEmpty &&
      _phoneController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmController.text.isNotEmpty &&
      _smsCodeController.text.isNotEmpty &&
      _smsId != null &&
      _agree;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 顶部绿色渐变 + LOGO
            Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CE8A7), Color(0xFFB2F7E2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(60),
                ),
              ),
              child: Center(
                child: Image.asset(
                  "assets/icons/logo.png",
                  width: 150,
                  height: 150,
                ),
              ),
            ),

            // 表单
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Sign up",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      "User Name",
                      _nameController,
                      _nameError,
                      maxLength: 25,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      "Mobile number",
                      _phoneController,
                      _phoneError,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // 验证码输入框
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildField(
                            "Verification Code",
                            _smsCodeController,
                            _smsCodeError,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _canSendSms && !_isLoadingSms ? _sendSmsCode : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _canSendSms 
                                    ? const Color(0xFF4CE8A7) 
                                    : Colors.grey.shade400,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoadingSms
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _canSendSms 
                                          ? "Send" 
                                          : "${_countdownSeconds}s",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      "Password",
                      _passwordController,
                      _passwordError,
                      obscureText: !_passwordVisible,
                      toggleVisibility: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                      isPassword: true,
                      visible: _passwordVisible,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      "Confirm password",
                      _confirmController,
                      _confirmError,
                      obscureText: !_confirmVisible,
                      toggleVisibility: () {
                        setState(() {
                          _confirmVisible = !_confirmVisible;
                        });
                      },
                      isPassword: true,
                      visible: _confirmVisible,
                    ),
                    const SizedBox(height: 16),

                    // 条款复选框
                    Row(
                      children: [
                        Checkbox(
                          value: _agree,
                          onChanged: (v) => setState(() => _agree = v ?? false),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UserAgreementPage(),
                                ),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(text: "I agree with "),
                                  TextSpan(
                                    text: "Terms & Conditions",
                                    style: TextStyle(
                                      color: Color(0xFF32C286),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sign up 按钮
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isFormValid && !_isRegistering ? _register : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CE8A7),
                          disabledBackgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isRegistering
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text("Sign up"),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 分割线 Or
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text("Or"),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 三个彩色按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                      "assets/images/Google.png",
                      width: 26,
                      height: 26,
                      ),
                      const SizedBox(width: 16),
                      Image.asset(
                      "assets/images/Apple.png",
                      width: 26,
                      height: 26,
                      ),
                      const SizedBox(width: 16),
                      Image.asset(
                      "assets/images/Facebook.png",
                      width: 26,
                      height: 26,
                      ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Already have account
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                            children: [
                              const TextSpan(text: "Already have an account? "),
                              TextSpan(
                                text: "Log in",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 输入框（带✓/! + 密码小眼睛） =====
  Widget _buildField(
    String label,
    TextEditingController controller,
    String? error, {
    bool obscureText = false,
    TextInputType? keyboardType,
    VoidCallback? toggleVisibility,
    bool isPassword = false,
    bool visible = false,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      visible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: toggleVisibility,
                  )
                : (error == null && controller.text.isNotEmpty
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : (error != null
                        ? const Icon(Icons.error, color: Colors.red)
                        : null)),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text(error,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          )
      ],
    );
  }

  // ===== 社交按钮 =====
  Widget _buildSocialCircle(Widget child) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.white,
      child: child,
    );
  }
}
