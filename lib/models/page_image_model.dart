class PageImageModel {
  final int id;
  final String title;
  final String subTitle;
  final String description;
  final String imageUrl;
  final int sortOrder;
  final String status;

  const PageImageModel({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.description,
    required this.imageUrl,
    required this.sortOrder,
    required this.status,
  });

  factory PageImageModel.fromJson(Map<String, dynamic> j) => PageImageModel(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        subTitle: j['subTitle'] as String? ?? '',
        description: j['description'] as String? ?? '',
        imageUrl: j['imageUrl'] as String? ?? '',
        sortOrder: j['sortOrder'] as int? ?? 0,
        status: j['status'] as String? ?? '',
      );
}
