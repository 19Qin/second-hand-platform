// 👇 ONLY import the entity. No models, no data sources here.
import '../../domain/entities/category.dart';

const mockCategories = <CategoryEntity>[
  CategoryEntity(
    id: 1,
    name: 'Luxuries',
    // icon omitted → treated as null
    parentId: 0,
    sortOrder: 1,
    isActive: true,
    productCount: 1250,
    children: [
      CategoryEntity(
        id: 11,
        name: '手机',
        icon: null, // explicitly blank
        parentId: 1,
        sortOrder: 1,
        isActive: true,
        productCount: 680,
      ),
      CategoryEntity(
        id: 12,
        name: '电脑',
        // icon omitted
        parentId: 1,
        sortOrder: 2,
        isActive: true,
        productCount: 420,
      ),
    ],
  ),
  CategoryEntity(
    id: 2,
    name: 'Electronic',
    icon: null, // explicitly blank
    parentId: 0,
    sortOrder: 2,
    isActive: true,
    productCount: 890,
  ),
];
