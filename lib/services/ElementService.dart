import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:mindcare_app/models/ElementModel.dart';
import 'package:mindcare_app/services/UserService.dart';

class ElementService extends ChangeNotifier {
  final String baseURL = 'mindcare.allsites.es';
  final storage = const FlutterSecureStorage();
  bool isLoading = true;
  final List<ElementData> elements = [];

  static String id_user = '';
  static String type = '';

  Future<ElementResponse> getElements() async {
    try {
      final url = Uri.http(baseURL, '/public/api/elements',
          {'id': UserService.userId.toString()});
      String? authToken = await readToken();
      isLoading = true;
      notifyListeners();

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        ElementResponse elementResponse = ElementResponse.fromJson(json);
        elements.clear();
        elements.addAll(elementResponse.data!);
        isLoading = false;
        notifyListeners();
        return elementResponse;
      } else {
        isLoading = false;
        notifyListeners();
        throw Exception(
            'Failed to load elements. Status code: ${response.statusCode}');
      }
    } catch (error) {
      isLoading = false;
      notifyListeners();
      throw Exception('Error: $error');
    }
  }

  Future addElement(
    int id_user,
    String type_user,
    String type,
    String description,
    DateTime date,
    int mood_id,
    int emotion_id,
  ) async {
    final Map<String, dynamic> elementData = {
      'id_user': id_user,
      'type_user': type_user,
      'type': type,
      'description': description,
      'date': date,
      'mood_id': mood_id,
      'emotion_id': emotion_id,
    };

    final url = Uri.http(baseURL, '/public/api/newElement', {});
    String? authToken = await readToken();

    final response = await http.post(url,
        headers: {
          'Accept': 'application/json',
          "Authorization": "Bearer $authToken",
        },
        body: json.encode(elementData));

    final Map<String, dynamic> decoded = json.decode(response.body);

    if (decoded['success'] == true) {
      ElementService.id_user = decoded['data']['id_user'].toString();
      ElementService.type = decoded['data']['type'].toString();
      return 'success';
    } else {
      // Control de errores de email, pasar a control de errores de objeto.
      // if (decoded['data']['error'] == "Email don't confirmed") {
      //   return 'Email not confimed';
      // } else if (decoded['data']['error'] == "User don't activated") {
      //   return 'User not activated';
      // } else {
      //   return decoded['message'];
      // }
    }
  }

  Future<String> readToken() async {
    return await storage.read(key: 'token') ?? '';
  }
}
