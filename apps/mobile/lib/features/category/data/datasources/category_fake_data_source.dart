import '../models/category_model.dart';
import 'category_remote_data_source.dart';

class CategoryFakeDataSource implements CategoryRemoteDataSource {
  @override
  Future<List<CategoryModel>> fetchCategories({
    int parentId = 0,
    bool isActive = true,
    bool includeChildren = true,
  }) async {
    // mimic endpoint filtering by parentId
    final top = _all.where((c) => c.parentId == parentId).toList();
    if (!includeChildren) {
      return top
          .map((c) => CategoryModel(
                id: c.id,
                name: c.name,
                icon: c.icon,
                parentId: c.parentId,
                sortOrder: c.sortOrder,
                isActive: c.isActive,
                productCount: c.productCount,
                children: const [],
              ))
          .toList();
    }
    return top;
  }
}

final _all = <CategoryModel>[
  CategoryModel(
    id: 1,
    name: '数码电子',
    icon: 'https://cdn.fliliy.com/icons/electronics.svg',
    parentId: 0,
    sortOrder: 1,
    isActive: true,
    productCount: 1250,
    children: [
      CategoryModel(
        id: 11,
        name: '手机',
        icon: 'https://cdn.fliliy.com/icons/phone.svg',
        parentId: 1,
        sortOrder: 1,
        isActive: true,
        productCount: 680,
      ),
      CategoryModel(
        id: 12,
        name: '电脑',
        icon: 'https://cdn.fliliy.com/icons/computer.svg',
        parentId: 1,
        sortOrder: 2,
        isActive: true,
        productCount: 420,
      ),
    ],
  ),
  CategoryModel(
    id: 2,
    name: '服装鞋帽',
    icon: 'https://cdn.fliliy.com/icons/clothing.svg',
    parentId: 0,
    sortOrder: 2,
    isActive: true,
    productCount: 890,
  ),
];
