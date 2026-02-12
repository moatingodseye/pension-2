import 'dart:convert';
import 'package:shared/models.dart';
import 'apiService.dart';
import 'apiResponse.dart';

class SnapshotService {
  Future<List<AccountSnapshot>> getSnapshots(int accountId) async {
    final list = await ApiService.getList('snapshot/$accountId');
    return list.map((e) => AccountSnapshot.fromJson(e)).toList();
  }

  Future<ApiResponse> createSnapshot(AccountSnapshot snapshot) async {
    final response = await ApiService.post('snapshot', snapshot.toJson());
    return ApiResponse.fromJson(response);
  }
}
