import 'package:flutter/material.dart';
import 'package:mobile/features/product/presentation/pages/product_detail_page.dart';

class NearbyPage extends StatefulWidget {
  const NearbyPage({super.key});
  
  @override
  NearbyPageState createState() => NearbyPageState();
}

class NearbyPageState extends State<NearbyPage> {
  String selectedPlace = "Rosebery";
  String selectedCategory = "Discount";
  String selectedSidebar = "New In";
  String selectedTag = "";
  bool showDetailedMap = false; // 控制是否显示详细地图

  final List<Map<String, dynamic>> places = [
    {"name": "Rosebery", "items": "150 items", "image": "assets/images/rosebery.png"},
    {"name": "Waterloo", "items": "99 items", "image": "assets/images/waterloo_detailed.png"},
    {"name": "Zetland", "items": "108 items", "image": null},
  ];

  final Map<String, List<Map<String, dynamic>>> categories = {
    "Discount": [
      {
        "id": "ps5_handle_001",
        "name": "Sony PS5 Wireless Handle",
        "price": 199.0,
        "image": "assets/images/ps5.png",
        "tags": ["Price match", "100% authentic"],
      },
      {
        "id": "ps4_handle_001", 
        "name": "Sony PS4 Wireless Handle",
        "price": 68.0,
        "image": "assets/images/ps4.png",
        "tags": ["Only PS4", "100% authentic"],
      },
      {
        "id": "ps5_dual_001",
        "name": "Sony Dualsense PS5 Handle",
        "price": 178.0,
        "image": "assets/images/ps5_dual.png",
        "tags": ["Hot", "Professional inspection"],
      },
      {
        "id": "ps5_blue_001",
        "name": "Blue Hearts PS5 Handle",
        "price": 188.0,
        "image": "assets/images/ps5_blue.png",
        "tags": ["Rare color", "100% authentic"],
      },
    ],
    "Accessories": [],
    "Watches": [],
    "Clothes": [],
  };

  // 公共刷新方法
  void refreshNearby() {
    // 重新加载附近页面的数据
    setState(() {
      // 这里可以添加重新加载附近商品数据的逻辑
      // 目前NearbyPage使用的是静态数据，所以只需要触发UI重建
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: Colors.orange,
            ),
            SizedBox(height: 24),
            Text(
              'Feature Under Development',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'The Nearby feature is currently being developed.\nPlease check back later!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // 可以添加返回首页或其他操作
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Thank you for your patience!'),
                    backgroundColor: Color(0xFF32C286),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF32C286),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Got it',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 保留原有的build方法作为注释，以备将来开发使用
  /*
  Widget _buildOriginalNearbyPage(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ✅ 顶部地图：1/2 屏
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            child: Stack(
              children: [
                // 根据选择显示不同地图
                Image.asset(
                  showDetailedMap ? "assets/images/waterloo_detailed.png" : "assets/images/map.png",
                  fit: BoxFit.cover, 
                  width: double.infinity, 
                  height: double.infinity
                ),
                // 返回按钮（仅在详细地图时显示）
                if (showDetailedMap)
                  Positioned(
                    top: 50,
                    left: 16,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showDetailedMap = false;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back, color: Colors.black, size: 20),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      itemCount: places.length,
                      itemBuilder: (context, index) {
                        final place = places[index];
                        final isSelected = selectedPlace == place["name"];
                        final hasImage = place["image"] != null;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedPlace = place["name"];
                              // 如果点击的是Waterloo，显示详细地图
                              if (place["name"] == "Waterloo") {
                                showDetailedMap = true;
                              } else {
                                showDetailedMap = false;
                              }
                            });
                          },
                          child: Container(
                            width: 160,
                            margin: EdgeInsets.only(right: 12),
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                if (hasImage)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      place["image"],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                SizedBox(width: 8),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place["name"],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      place["items"],
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ 下方内容
          Expanded(
            child: Row(
              children: [
                // 左侧导航栏
                Container(
                  width: 80,
                  color: Colors.grey.shade100,
                  child: ListView(
                    children: [
                      SidebarItem("New In", selectedSidebar == "New In", () {
                        setState(() => selectedSidebar = "New In");
                      }),
                      SidebarItem("Sale", selectedSidebar == "Sale", () {
                        setState(() => selectedSidebar = "Sale");
                      }),
                      SidebarItem("50% off", selectedSidebar == "50% off", () {
                        setState(() => selectedSidebar = "50% off");
                      }),
                      SidebarItem("Brand", selectedSidebar == "Brand", () {
                        setState(() => selectedSidebar = "Brand");
                      }),
                      SidebarItem("Trends", selectedSidebar == "Trends", () {
                        setState(() => selectedSidebar = "Trends");
                      }),
                      SidebarItem("Women", selectedSidebar == "Women", () {
                        setState(() => selectedSidebar = "Women");
                      }),
                      SidebarItem("Men", selectedSidebar == "Men", () {
                        setState(() => selectedSidebar = "Men");
                      }),
                      SidebarItem("Kids", selectedSidebar == "Kids", () {
                        setState(() => selectedSidebar = "Kids");
                      }),
                    ],
                  ),
                ),

                // 主体内容
                Expanded(
                  child: ListView(
                    children: [
                      // 分类导航
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 12),
                        child: Row(
                          children: [
                            CategoryIconNoBorder(
                              image: "assets/images/discount.png",
                              label: "Discount",
                              selected: selectedCategory == "Discount",
                              onTap: () =>
                                  setState(() => selectedCategory = "Discount"),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CategoryIcon(
                                    image: "assets/images/accessories.png",
                                    label: "Accessories",
                                    selected: selectedCategory == "Accessories",
                                    onTap: () => setState(
                                        () => selectedCategory = "Accessories"),
                                  ),
                                  CategoryIcon(
                                    image: "assets/images/watches.png",
                                    label: "Watches",
                                    selected: selectedCategory == "Watches",
                                    onTap: () =>
                                        setState(() => selectedCategory = "Watches"),
                                  ),
                                  CategoryIcon(
                                    image: "assets/images/clothes.png",
                                    label: "Clothes",
                                    selected: selectedCategory == "Clothes",
                                    onTap: () =>
                                        setState(() => selectedCategory = "Clothes"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 横幅广告
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset("assets/images/banner.png",
                              fit: BoxFit.cover),
                        ),
                      ),

                      // 标签 + 搜索框
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            TagButton(
                              text: "Free shipping",
                              selected: selectedTag == "Free shipping",
                              onTap: () {
                                setState(() {
                                  selectedTag =
                                      selectedTag == "Free shipping"
                                          ? ""
                                          : "Free shipping";
                                });
                              },
                            ),
                            SizedBox(width: 8),
                            TagButton(
                              text: "Self-collect",
                              selected: selectedTag == "Self-collect",
                              onTap: () {
                                setState(() {
                                  selectedTag =
                                      selectedTag == "Self-collect"
                                          ? ""
                                          : "Self-collect";
                                });
                              },
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: "Search...",
                                    hintStyle: TextStyle(color: Colors.grey),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    filled: true,
                                    fillColor: Colors.grey.shade200,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 商品卡片
                      if (categories[selectedCategory]!.isNotEmpty)
                        ...categories[selectedCategory]!
                            .map((p) => buildProductCard(context, p))
                            .toList()
                      else
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(
                              child: Text("No items available",
                                  style: TextStyle(color: Colors.grey))),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 商品卡片
  Widget buildProductCard(BuildContext context, Map<String, dynamic> product) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 点击图片进入详情
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(productId: product["id"]),
                  ),
                );
              },
              child: Image.asset(product["image"],
                  width: 80, height: 80, fit: BoxFit.cover),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 点击标题进入详情
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailPage(productId: product["id"]),
                        ),
                      );
                    },
                    child: Text(product["name"],
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: (product["tags"] as List<String>)
                        .map((tag) => Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(tag,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 10)),
                            ))
                        .toList(),
                  ),
                  SizedBox(height: 6),
                  Text("\$${product["price"]}",
                      style: TextStyle(fontSize: 16, color: Colors.red)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // 显示功能即将上线的提示
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('聊天功能即将上线，敬请期待！'),
                    backgroundColor: Color(0xFF32C286),
                  ),
                );
              },
              child: Text("Chat", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// 左侧导航栏
class SidebarItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const SidebarItem(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        color: selected ? Colors.white : Colors.transparent,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Theme.of(context).colorScheme.primary : Colors.black,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// 分类图标（有边框）
class CategoryIcon extends StatelessWidget {
  final String image;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryIcon(
      {required this.image,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: selected
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                  : Border.all(color: Colors.grey.shade200),
            ),
            child: Image.asset(image, width: 60, height: 60),
          ),
          SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

// 分类图标（无边框 → 专门给 Discount）
class CategoryIconNoBorder extends StatelessWidget {
  final String image;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryIconNoBorder({
    required this.image,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            child: Image.asset(image, width: 60, height: 60),
          ),
          SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

// 标签按钮
class TagButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const TagButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Theme.of(context).colorScheme.primary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  */
}
