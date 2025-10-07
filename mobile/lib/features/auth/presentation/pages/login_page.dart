import 'package:flutter/material.dart';
import 'otp_page.dart';
import 'signup_page.dart';
import 'user_agreement_page.dart';
import 'package:mobile/root_shell.dart';
import 'package:mobile/injection.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../../../core/auth/token_manager.dart';
import '../../../../core/l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agree = false;
  bool _usePassword = false; // 是否使用密码登录

  // 登录状态
  bool _isLoading = false;

  // 错误提示
  String? _phoneError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
    _passwordController.addListener(_validatePassword);
    // 用户进入登录页面时，清除之前的认证状态
    _clearPreviousAuthState();
  }

  Future<void> _clearPreviousAuthState() async {
    try {
      // 获取refreshToken
      final refreshToken = await TokenManager.instance.getRefreshToken();
      
      if (refreshToken != null) {
        // 如果有refreshToken，调用logout接口
        final authDataSource = ServiceLocator().get<AuthRemoteDataSource>();
        await authDataSource.logout(refreshToken: refreshToken);
      }
    } catch (e) {
      // 即使接口调用失败，也要清除本地数据
      print('自动logout失败: $e');
    } finally {
      // 清除本地Token
      await TokenManager.instance.clearTokens();
    }
  }

  // 校验手机号
  void _validatePhone() {
    final v = _phoneController.text;
    setState(() {
      if (v.isEmpty) {
        _phoneError = "Please enter phone number";
      } else if (!RegExp(r'^[0-9]{10,11}$').hasMatch(v)) {
        _phoneError = "Invalid phone number";
      } else {
        _phoneError = null;
      }
    });
  }

  // 校验密码（仅密码登录时检查）
  void _validatePassword() {
    final v = _passwordController.text;
    if (_usePassword) {
      setState(() {
        if (v.isEmpty) {
          _passwordError = "Please enter password";
        } else if (v.length < 8) {
          _passwordError = "Password must be at least 8 characters";
        } else {
          _passwordError = null;
        }
      });
    }
  }

  // 是否允许点击按钮
  bool get _isFormValid {
    if (!_agree || _phoneError != null || _phoneController.text.isEmpty || _isLoading) {
      return false;
    }
    if (_usePassword) {
      return _passwordError == null && _passwordController.text.isNotEmpty;
    }
    return true; // 验证码模式只要求手机号
  }

  // 密码登录
  Future<void> _loginWithPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authDataSource = ServiceLocator().get<AuthRemoteDataSource>();
      final response = await authDataSource.loginWithPassword(
        mobile: _phoneController.text,
        password: _passwordController.text,
        rememberMe: true,
      );

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome back, ${response.user.username}!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RootShell()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 发送短信验证码
  Future<void> _sendSmsCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authDataSource = ServiceLocator().get<AuthRemoteDataSource>();
      final response = await authDataSource.sendSmsCode(
        mobile: _phoneController.text,
        type: 'login',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent successfully')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpPage(
              phoneNumber: _phoneController.text,
              smsId: response.smsId,
              isLogin: true,
            ),
          ),
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
        _isLoading = false;
      });
    }
  }

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

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).login,
                      style:
                          const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Please login to your account",
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // 手机号输入
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).mobileNumber,
                      border: const OutlineInputBorder(),
                      errorText: _phoneError,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // 如果是密码登录，显示密码框
                  if (_usePassword) ...[
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).password,
                        border: const OutlineInputBorder(),
                        errorText: _passwordError,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              children: [
                                const TextSpan(text: "I agree with "),
                                TextSpan(
                                  text: AppLocalizations.of(context).termsAndConditions,
                                  style: const TextStyle(
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

                  // 登录按钮
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isFormValid
                          ? () {
                              if (_usePassword) {
                                _loginWithPassword();
                              } else {
                                _sendSmsCode();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CE8A7),
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(_usePassword
                              ? "Login with password"
                              : "Get verify number"),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 切换密码登录 / 验证码登录
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _usePassword = !_usePassword;
                          _validatePassword();
                        });
                      },
                      child: Text(
                        _usePassword ? "Use SMS code instead" : "Enter password",
                        style: const TextStyle(
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                        ),
                      ),
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

                  // 三个社交按钮
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

                  // Continue as guest -> RootShell
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const RootShell()),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 14, color: Colors.black),
                          children: [
                            TextSpan(text: "Continue as guest"),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 去注册
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpPage(),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: "Sign Up",
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
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSocialCircle(Widget child) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.white,
      child: child,
    );
  }
}
