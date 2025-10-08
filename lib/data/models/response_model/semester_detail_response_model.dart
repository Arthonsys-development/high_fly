class SemesterTreasureDetailItem {
  int? id;
  String? name;
  String? semesterStartDate;
  String? semesterEndDate;
  String? semesterLogo;
  String? price;
  String? createdAt;
  String? guessTitle;
  String? guessDescription;
  bool? isPurchase;
  String? nextGuessIn;
  CurrentGuess? currentGuess;
  List<SemesterTreasure>? semesterTreasure;

  SemesterTreasureDetailItem(
      {this.id,
        this.name,
        this.semesterStartDate,
        this.semesterEndDate,
        this.semesterLogo,
        this.price,
        this.createdAt,
        this.guessTitle,
        this.guessDescription,
        this.isPurchase,
        this.nextGuessIn,
        this.currentGuess,
        this.semesterTreasure});

  SemesterTreasureDetailItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    semesterStartDate = json['semester_start_date'];
    semesterEndDate = json['semester_end_date'];
    semesterLogo = json['semester_logo'];
    price = json['price'];
    createdAt = json['created_at'];
    guessTitle = json['guess_title'];
    guessDescription = json['guess_description'];
    isPurchase = json['is_purchase'];
    nextGuessIn = json['next_guess_in'];
    currentGuess = json['current_guess'] != null
        ? CurrentGuess.fromJson(json['current_guess'])
        : null;
    if (json['semester_treasure'] != null) {
      semesterTreasure = <SemesterTreasure>[];
      json['semester_treasure'].forEach((v) {
        semesterTreasure!.add(SemesterTreasure.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['semester_start_date'] = semesterStartDate;
    data['semester_end_date'] = semesterEndDate;
    data['semester_logo'] = semesterLogo;
    data['price'] = price;
    data['created_at'] = createdAt;
    data['guess_title'] = guessTitle;
    data['guess_description'] = guessDescription;
    data['is_purchase'] = isPurchase;
    data['next_guess_in'] = nextGuessIn;
    if (currentGuess != null) {
      data['current_guess'] = currentGuess!.toJson();
    }
    if (semesterTreasure != null) {
      data['semester_treasure'] =
          semesterTreasure!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CurrentGuess {
  String? latitude;
  String? longitude;

  CurrentGuess({this.latitude, this.longitude});

  CurrentGuess.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}

class SemesterTreasure {
  int? id;
  String? latitude;
  String? longitude;
  String? createdAt;

  SemesterTreasure({this.id, this.latitude, this.longitude, this.createdAt});

  SemesterTreasure.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['created_at'] = createdAt;
    return data;
  }
}