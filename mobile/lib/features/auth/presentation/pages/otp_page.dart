import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/root_shell.dart';
import 'package:mobile/injection.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../../../core/auth/token_manager.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;
  final String? smsId;
  final bool isLogin;

  const OtpPage({
    super.key, 
    required this.phoneNumber,
    this.smsId,
    this.isLogin = false,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(4, (_) => FocusNode()); // ✅ 每个输入框的焦点

  late Timer _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsRemaining = 60;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() => _canResend = true);
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyCode() async {
    // 获取输入的验证码
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 4-digit verification code')),
      );
      return;
    }

    if (widget.smsId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid verification session')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final authDataSource = ServiceLocator().get<AuthRemoteDataSource>();
      final response = await authDataSource.loginWithSms(
        mobile: widget.phoneNumber,
        smsCode: code,
        smsId: widget.smsId!,
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
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  // 重发验证码
  Future<void> _resendCode() async {
    try {
      final authDataSource = ServiceLocator().get<AuthRemoteDataSource>();
      await authDataSource.sendSmsCode(
        mobile: widget.phoneNumber,
        type: widget.isLogin ? 'login' : 'register',
      );

      _startCountdown();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend code: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone = widget.phoneNumber.length >= 10
        ? "${widget.phoneNumber.substring(0, 3)} **** ${widget.phoneNumber.substring(widget.phoneNumber.length - 3)}"
        : widget.phoneNumber;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter 4 Digit Code",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Enter 4 digit code that you receive on your phone",
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text("(+61 $maskedPhone)",
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),

            // ✅ 验证码输入框（自动跳下一个）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) {
                return SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    onChanged: (value) {
                      if (value.isNotEmpty && i < 3) {
                        FocusScope.of(context)
                            .requestFocus(_focusNodes[i + 1]); // ✅ 跳到下一个框
                      }
                      if (value.isEmpty && i > 0) {
                        FocusScope.of(context)
                            .requestFocus(_focusNodes[i - 1]); // ⬅️ 删除时回到上一个
                      }
                    },
                    decoration: InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // ✅ Not received? + 倒计时 or Resend
            Center(
              child: _canResend
                  ? TextButton(
                      onPressed: _resendCode,
                      child: Text(
                        "Resend code",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        const Text("Not received?",
                            style: TextStyle(fontSize: 14, color: Colors.grey)),
                        Text("Resend available in $_secondsRemaining s",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // 验证按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CE8A7),
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text("Verify"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
