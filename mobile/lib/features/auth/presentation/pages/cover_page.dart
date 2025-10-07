import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'package:mobile/root_shell.dart';
import '../../../../core/auth/auth_state_manager.dart';

// 上方绿色区域的自定义形状 (Vector 3)
class TopGreenShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(0.0, -0.85),
        end: Alignment(0.0, 1.0),
        colors: [
          Color.fromRGBO(76, 232, 167, 0.7),
          Color.fromRGBO(76, 232, 167, 0.2),
        ],
        stops: [0.053856, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    
    // 根据SVG路径数据创建路径，按比例缩放到当前尺寸
    final scaleX = size.width / 402;
    final scaleY = size.height / 198;
    
    path.moveTo(249.81 * scaleX, 133.859 * scaleY);
    path.cubicTo(214.266 * scaleX, 148 * scaleY, 222.276 * scaleX, 157.45 * scaleY, 201.751 * scaleX, 173.253 * scaleY);
    path.cubicTo(181.226 * scaleX, 189.055 * scaleY, 184.229 * scaleX, 188.404 * scaleY, 148.185 * scaleX, 195.475 * scaleY);
    path.cubicTo(112.14 * scaleX, 202.545 * scaleY, 96.1202 * scaleX, 180.828 * scaleY, 62.5787 * scaleX, 178.808 * scaleY);
    path.cubicTo(29.0372 * scaleX, 176.788 * scaleY, -1 * scaleX, 198 * scaleY, -1 * scaleX, 198 * scaleY);
    path.lineTo(-1 * scaleX, -2 * scaleY);
    path.lineTo(403 * scaleX, -2 * scaleY);
    path.lineTo(403 * scaleX, 88.404 * scaleY);
    path.cubicTo(403 * scaleX, 88.404 * scaleY, 379.471 * scaleX, 129.313 * scaleY, 343.426 * scaleX, 144.97 * scaleY);
    path.cubicTo(307.382 * scaleX, 160.626 * scaleY, 285.354 * scaleX, 119.717 * scaleY, 249.81 * scaleX, 133.859 * scaleY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// 下方绿色区域的自定义形状 (Vector 4)
class BottomGreenShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(-0.5, 1.0),
        end: Alignment(1.0, -0.5),
        colors: [
          Color.fromRGBO(76, 232, 167, 0.7),
          Color.fromRGBO(76, 232, 167, 0.2),
        ],
        stops: [0.053856, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    
    // 根据SVG路径数据创建路径，按比例缩放到当前尺寸
    final scaleX = size.width / 402;
    final scaleY = size.height / 501;
    
    path.moveTo(328.5 * scaleX, 30.5 * scaleY);
    path.cubicTo(259 * scaleX, 0.500008 * scaleY, 207.5 * scaleX, 57 * scaleY, 170 * scaleX, 51.5 * scaleY);
    path.cubicTo(132.5 * scaleX, 46 * scaleY, 113 * scaleX, 17.316 * scaleY, 68 * scaleX, 24 * scaleY);
    path.cubicTo(23 * scaleX, 30.684 * scaleY, 0 * scaleX, 0.5 * scaleY, 0 * scaleX, 0.5 * scaleY);
    path.lineTo(0 * scaleX, 501 * scaleY);
    path.lineTo(403 * scaleX, 501 * scaleY);
    path.lineTo(403 * scaleX, 73 * scaleY);
    path.cubicTo(403 * scaleX, 73 * scaleY, 398 * scaleX, 60.5 * scaleY, 328.5 * scaleX, 30.5 * scaleY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CoverPage extends StatelessWidget {
  final Function(Locale)? onLanguageChanged;
  
  const CoverPage({super.key, this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 基于402x874的设计比例计算缩放因子
    final designWidth = 402.0;
    final designHeight = 874.0;
    final scaleX = screenWidth / designWidth;
    final scaleY = screenHeight / designHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY; // 使用较小的缩放比例保持比例
    
    return Scaffold(
      body: Stack(
        children: [
          // 上方绿色自定义形状区域 (Vector 3)
          Positioned(
            top: -2 * scaleY,
            left: -1 * scaleX,
            child: CustomPaint(
              size: Size(404 * scaleX, 200 * scaleY),
              painter: TopGreenShapePainter(),
            ),
          ),
          
          // 中间Logo图片
          Positioned(
            top: 209 * scaleY,
            left: 16 * scaleX,
            child: Container(
              width: 370 * scaleX,
              height: 173 * scaleY,
              child: Center(
                child: Image.asset(
                  'assets/icons/logo.png',
                  width: 370 * scaleX,
                  height: 173 * scaleY,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 370 * scaleX,
                      height: 173 * scaleY,
                      color: Colors.grey[300],
                      child: Center(
                        child: Text(
                          'FliFli',
                          style: TextStyle(
                            fontSize: 48 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // 下方绿色自定义形状区域 (Vector 4)
          Positioned(
            top: 373.5 * scaleY,
            left: 0,
            child: CustomPaint(
              size: Size(403 * scaleX, 500.5 * scaleY),
              painter: BottomGreenShapePainter(),
            ),
          ),
          
          // 中间按钮区域
          Positioned(
            top: 580 * scaleY,
            left: 76 * scaleX,
            child: Container(
              width: 250 * scaleX,
              height: 173 * scaleY,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Sign up 按钮
                  SizedBox(
                    width: 250 * scaleX,
                    height: 48 * scaleY,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CE8A7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20 * scale),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  // Log in 按钮
                  SizedBox(
                    width: 250 * scaleX,
                    height: 48 * scaleY,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20 * scale),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Log in',
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  // Continue as guest 按钮
                  GestureDetector(
                    onTap: () async {
                      // 设置guest模式（清除token）
                      await AuthStateManager.instance.setGuestMode();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RootShell(),
                        ),
                      );
                    },
                    child: Container(
                      width: 250 * scaleX,
                      height: 48 * scaleY,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                      child: Center(
                        child: Text(
                          'Continue as guest',
                          style: TextStyle(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
