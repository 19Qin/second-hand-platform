import 'package:flutter/material.dart';
import 'token_manager.dart';
import '../../features/auth/presentation/pages/login_page.dart';

/// 认证状态管理器
class AuthStateManager {
  static const String _isGuestKey = 'is_guest_user';
  
  static AuthStateManager? _instance;
  static AuthStateManager get instance {
    _instance ??= AuthStateManager._();
    return _instance!;
  }
  
  AuthStateManager._();

  /// 设置用户为游客模式
  Future<void> setGuestMode() async {
    await TokenManager.instance.clearTokens();
    // 可以在这里添加其他游客模式的设置
  }

  /// 检查用户是否为游客
  Future<bool> isGuestUser() async {
    final hasToken = await TokenManager.instance.hasValidToken();
    return !hasToken;
  }

  /// 检查用户是否已登录
  Future<bool> isLoggedIn() async {
    return await TokenManager.instance.hasValidToken();
  }

  /// 显示登录提示对话框
  Future<void> showLoginRequiredDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF32C286).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 40,
                  color: Color(0xFF32C286),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '需要登录',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '此功能需要登录后才能使用，请先登录您的账户。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _navigateToLogin(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF32C286),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '去登录',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 导航到登录页面
  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  /// 检查并处理需要登录的操作
  Future<bool> checkAuthAndShowDialog(BuildContext context) async {
    final isGuest = await isGuestUser();
    if (isGuest) {
      await showLoginRequiredDialog(context);
      return false; // 用户未登录，阻止操作
    }
    return true; // 用户已登录，允许操作
  }
}
