class User {
  final int id;
  final String email;
  final String firstname;
  final String lastname;
  final String role;
  final int? chefId;
  final String? chefName;
  final String? profileImageUrl;
  final PersonalInfo? personalInfo;
  final ProfessionalInfo? professionalInfo;

  User({
    required this.id,
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.role,
    this.chefId,
    this.chefName,
    this.profileImageUrl,
    this.personalInfo,
    this.professionalInfo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      email: json['email'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      role: json['role'],
      chefId: json['chefId'],
      chefName: json['chefName'],
      profileImageUrl: json['profileImageUrl'],
      personalInfo: json['personalInfo'] != null
          ? PersonalInfo.fromJson(json['personalInfo'])
          : null,
      professionalInfo: json['professionalInfo'] != null
          ? ProfessionalInfo.fromJson(json['professionalInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstname': firstname,
      'lastname': lastname,
      'role': role,
      'chefId': chefId,
      'chefName': chefName,
      'profileImageUrl': profileImageUrl,
      'personalInfo': personalInfo?.toJson(),
      'professionalInfo': professionalInfo?.toJson(),
    };
  }

  String get fullName => '$firstname $lastname';
}

class PersonalInfo {
  final String? cin;
  final String? dateOfBirth;
  final String? placeOfBirth;
  final String? nationality;
  final String? maritalStatus;
  final int? numberOfChildren;
  final String? address;
  final String? city;
  final String? country;
  final String? phone;
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactPhone;

  PersonalInfo({
    this.cin,
    this.dateOfBirth,
    this.placeOfBirth,
    this.nationality,
    this.maritalStatus,
    this.numberOfChildren,
    this.address,
    this.city,
    this.country,
    this.phone,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactPhone,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      cin: json['cin'],
      dateOfBirth: json['date_of_birth'],
      placeOfBirth: json['place_of_birth'],
      nationality: json['nationality'],
      maritalStatus: json['marital_status'],
      numberOfChildren: json['number_of_children'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      phone: json['phone'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactRelationship: json['emergency_contact_relationship'],
      emergencyContactPhone: json['emergency_contact_phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cin': cin,
      'date_of_birth': dateOfBirth,
      'place_of_birth': placeOfBirth,
      'nationality': nationality,
      'marital_status': maritalStatus,
      'number_of_children': numberOfChildren,
      'address': address,
      'city': city,
      'country': country,
      'phone': phone,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_relationship': emergencyContactRelationship,
      'emergency_contact_phone': emergencyContactPhone,
    };
  }
}

class ProfessionalInfo {
  final String? employeeId;
  final String? department;
  final String? position;
  final String? grade;
  final String? hireDate;
  final String? contractType;
  final double? salary;
  final String? rib;
  final String? bankName;
  final String? cnss;
  final String? mutuelle;

  ProfessionalInfo({
    this.employeeId,
    this.department,
    this.position,
    this.grade,
    this.hireDate,
    this.contractType,
    this.salary,
    this.rib,
    this.bankName,
    this.cnss,
    this.mutuelle,
  });

  factory ProfessionalInfo.fromJson(Map<String, dynamic> json) {
    return ProfessionalInfo(
      employeeId: json['employee_id'],
      department: json['department'],
      position: json['position'],
      grade: json['grade'],
      hireDate: json['hire_date'],
      contractType: json['contract_type'],
      salary: json['salary'] != null ? double.parse(json['salary'].toString()) : null,
      rib: json['rib'],
      bankName: json['bank_name'],
      cnss: json['cnss'],
      mutuelle: json['mutuelle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'department': department,
      'position': position,
      'grade': grade,
      'hire_date': hireDate,
      'contract_type': contractType,
      'salary': salary,
      'rib': rib,
      'bank_name': bankName,
      'cnss': cnss,
      'mutuelle': mutuelle,
    };
  }
}
