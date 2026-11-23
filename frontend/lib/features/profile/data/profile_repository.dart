import 'profile_model.dart';
import '../../../core/network/api_client.dart'; // Make sure this path is correct

class ProfileRepository {
  
  final ApiClient _apiClient = ApiClient(); 

  Future<ProfileModel> getMyProfile() async {
    try {
      
      final response = await _apiClient.dio.get('/profile/me');
      return ProfileModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }
}