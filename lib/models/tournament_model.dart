int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

class TournamentModel {
  final int id;
  final int venueId;
  final String name;
  final String tournamentDate;
  final String location;
  final String startTime;
  final String endTime;
  final String category;
  final String genderCategory;
  final String? description;
  final String? videoUrl;
  final String? bannerImage;
  final String status;
  final String? venueName;

  const TournamentModel({
    required this.id,
    required this.venueId,
    required this.name,
    required this.tournamentDate,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.category,
    required this.genderCategory,
    this.description,
    this.videoUrl,
    this.bannerImage,
    required this.status,
    this.venueName,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> j) => TournamentModel(
        id:             _parseInt(j['id']) ?? 0,
        venueId:        _parseInt(j['venueId']) ?? 0,
        name:           j['name'] as String? ?? '',
        tournamentDate: j['tournamentDate'] as String? ?? '',
        location:       j['location'] as String? ?? '',
        startTime:      j['startTime'] as String? ?? '',
        endTime:        j['endTime'] as String? ?? '',
        category:       j['category'] as String? ?? '',
        genderCategory: j['genderCategory'] as String? ?? '',
        description:    j['description'] as String?,
        videoUrl:       j['videoUrl'] as String?,
        bannerImage:    j['bannerImage'] as String?,
        status:         j['status'] as String? ?? 'Active',
        venueName:      j['venueName'] as String?,
      );
}

class TournamentPagination {
  final int total;
  final int page;
  final int limit;
  final int pages;

  const TournamentPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  bool get hasNext => page < pages;

  factory TournamentPagination.fromJson(Map<String, dynamic> j) =>
      TournamentPagination(
        total: _parseInt(j['total']) ?? 0,
        page:  _parseInt(j['page']) ?? 1,
        limit: _parseInt(j['limit']) ?? 10,
        pages: _parseInt(j['pages']) ?? 1,
      );
}

class TournamentSearchResult {
  final List<TournamentModel> tournaments;
  final TournamentPagination pagination;

  const TournamentSearchResult({
    required this.tournaments,
    required this.pagination,
  });
}
