import 'package:hive/hive.dart';

part 'client.g.dart';

@HiveType(typeId: 2)
class Client extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? company;

  @HiveField(3)
  String? email;

  @HiveField(4)
  String? phone;

  @HiveField(5)
  String? address;

  Client({
    required this.id,
    required this.name,
    this.company,
    this.email,
    this.phone,
    this.address,
  });
}


