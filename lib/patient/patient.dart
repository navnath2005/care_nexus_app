class Patient {
  final int id;
  final String name;
  final int age;

  Patient({required this.id, required this.name, required this.age});

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      age: json['age'],
    );
  }
}
