import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Test',
      home: ImageTestPage(),
    );
  }
}

class ImageTestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Test')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Luxuries Showcase:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              width: 200,
              height: 200,
              child: Image.asset(
                'assets/images/luxuries_showcase.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.red,
                    child: Center(
                      child: Text('Error loading luxuries image'),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 30),
            Text('Electronics Showcase:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              width: 200,
              height: 200,
              child: Image.asset(
                'assets/images/electronics_showcase.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.red,
                    child: Center(
                      child: Text('Error loading electronics image'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



