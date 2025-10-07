import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PaymentMethodsPage extends StatefulWidget {
  final Function(Map<String, String>) onCardSelected;

  const PaymentMethodsPage({
    Key? key,
    required this.onCardSelected,
  }) : super(key: key);

  @override
  _PaymentMethodsPageState createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  String selectedCardId = "2512"; // 默认选中第一张卡
  
  // 新卡片输入控制器
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  final List<Map<String, String>> cards = [
    {
      "id": "2512",
      "number": "**** **** **** 2512",
      "isDefault": "true",
    },
    {
      "id": "6688",
      "number": "**** **** **** 6688",
      "isDefault": "false",
    },
    {
      "id": "2851",
      "number": "**** **** **** 2851",
      "isDefault": "false",
    },
  ];

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Payment methods",
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select existing card 部分
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select existing card",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // 卡片列表
                  ...cards.map((card) {
                    final isSelected = selectedCardId == card["id"];
                    final isDefault = card["isDefault"] == "true";
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCardId = card["id"]!;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                            // VISA 标签
                            Container(
                              width: 45,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF222357),
                                      Color(0xFF254AA5),
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    "VISA",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            
                            // 卡号
                            Text(
                              card["number"]!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                            
                            // Default 标签
                            if (isDefault) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(0xFF32C286),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  "Default",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            
                            Spacer(),
                            
                            // 选择圆圈
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected 
                                    ? Color(0xFF32C286) 
                                    : Colors.grey.shade400,
                                  width: 2,
                                ),
                                color: Colors.white,
                              ),
                              child: isSelected
                                ? Container(
                                    margin: EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF32C286),
                                    ),
                                  )
                                : null,
                            ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            
            // 分隔线
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
            
            SizedBox(height: 24),
            
            // Input new card 部分
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Input new card",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // 卡号输入
                  _buildInputField(
                    label: "Card number",
                    controller: _cardNumberController,
                    placeholder: "1234 1234 1234 1234",
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  
                  // 过期日期和安全码
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: "Exp date",
                          controller: _expiryController,
                          placeholder: "mm/yy",
                          keyboardType: TextInputType.datetime,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(
                          label: "Security code",
                          controller: _cvvController,
                          placeholder: "CCV",
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // 持卡人姓名
                  _buildInputField(
                    label: "Card hold's name",
                    controller: _nameController,
                    placeholder: "Enter card holder's name",
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40),
          ],
        ),
      ),
      
      // Apply 按钮
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              if (selectedCardId.isNotEmpty) {
                final selectedCard = cards.firstWhere((card) => card["id"] == selectedCardId);
                widget.onCardSelected(selectedCard);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF32C286),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              "Apply",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF32C286)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

