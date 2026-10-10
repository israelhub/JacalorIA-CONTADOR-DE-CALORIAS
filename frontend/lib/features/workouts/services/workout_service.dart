import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../auth/service/auth_service.dart';
import '../helpers/workout_formatters.dart';
import '../models/workout_models.dart';

class WorkoutService {
  const WorkoutService();

  static String get _baseUrl => ApiConfig.baseUrl;

  Future<WorkoutOverview> fetchWorkouts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/workouts'),
      headers: _headers(),
    );
    return WorkoutOverview.fromJson(
      _decodeMap(response, 'carregar os treinos'),
    );
  }

  Future<WorkoutOverview> importFromText(String text) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/workouts/import'),
      headers: _headers(json: true),
      body: jsonEncode({'text': text}),
    );
    return WorkoutOverview.fromJson(
      _decodeMap(response, 'organizar o texto com a IA'),
    );
  }

  Future<WorkoutRoutine> createRoutine({required String name}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/workouts/routines'),
      headers: _headers(json: true),
      body: jsonEncode({'name': name}),
    );
    return WorkoutRoutine.fromJson(_decodeMap(response, 'criar o treino'));
  }

  Future<WorkoutRoutine> renameRoutine({
    required String routineId,
    required String name,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/workouts/routines/$routineId'),
      headers: _headers(json: true),
      body: jsonEncode({'name': name}),
    );
    return WorkoutRoutine.fromJson(_decodeMap(response, 'renomear o treino'));
  }

  Future<void> deleteRoutine({required String routineId}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/workouts/routines/$routineId'),
      headers: _headers(),
    );
    _ensureSuccess(response, 'apagar o treino');
  }

  Future<WorkoutExercise> createExercise({
    required String routineId,
    required String name,
    required int sets,
    required int reps,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/workouts/routines/$routineId/exercises'),
      headers: _headers(json: true),
      body: jsonEncode({'name': name, 'sets': sets, 'reps': reps}),
    );
    return WorkoutExercise.fromJson(_decodeMap(response, 'criar o exercício'));
  }

  Future<WorkoutExercise> updateExercise({
    required String exerciseId,
    required String name,
    required int sets,
    required int reps,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/workouts/exercises/$exerciseId'),
      headers: _headers(json: true),
      body: jsonEncode({'name': name, 'sets': sets, 'reps': reps}),
    );
    return WorkoutExercise.fromJson(
      _decodeMap(response, 'atualizar o exercício'),
    );
  }

  Future<void> deleteExercise({required String exerciseId}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/workouts/exercises/$exerciseId'),
      headers: _headers(),
    );
    _ensureSuccess(response, 'apagar o exercício');
  }

  Future<WorkoutExercise> upsertLoad({
    required String exerciseId,
    required double weight,
    required DateTime recordedAt,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/workouts/exercises/$exerciseId/loads'),
      headers: _headers(json: true),
      body: jsonEncode({
        'weight': weight,
        'recordedAt': toWorkoutDateQuery(recordedAt),
      }),
    );
    return WorkoutExercise.fromJson(_decodeMap(response, 'registrar a carga'));
  }

  Future<void> deleteLoad({required String loadId}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/workouts/loads/$loadId'),
      headers: _headers(),
    );
    _ensureSuccess(response, 'apagar a carga');
  }

  Map<String, String> _headers({bool json = false}) {
    final token = AuthService.globalToken;
    if (token == null || token.isEmpty) {
      throw Exception('Sessão inválida. Faça login novamente.');
    }

    return <String, String>{
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _decodeMap(http.Response response, String action) {
    if (response.body.isEmpty) {
      _ensureSuccess(response, action);
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception('Resposta inválida ao $action.');
    }

    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String && message.isNotEmpty) {
        throw Exception(message);
      }
    }

    throw Exception('Não foi possível $action.');
  }

  void _ensureSuccess(http.Response response, String action) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception('Não foi possível $action.');
  }
}
