class AppSecrets {
  static const llmApiKey = String.fromEnvironment('LLM_API_KEY');
  static const llmEndpoint = String.fromEnvironment(
    'LLM_ENDPOINT',
    defaultValue: 'https://api.openai.com/v1_1/dqpzscxju/auto/upload', // Optimized for your cloud
  );
  static const llmModel = String.fromEnvironment(
    'LLM_MODEL',
    defaultValue: 'gpt-4o-mini',
  );
  static const mapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const fcmWebVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');
  static const openWeatherApiKey = String.fromEnvironment('OPENWEATHER_API_KEY');
  
  // Cloudinary configuration for Member 3
  static const cloudinaryCloudName = 'dqpzscxju'; 
  static const cloudinaryUploadPreset = 'ml_default'; // Default preset, change if you created a specific one

  static const ocrApiKey = String.fromEnvironment('OCR_API_KEY');
  static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  static const ilovePdfApiKey = String.fromEnvironment('ILOVEPDF_API_KEY');
  static const ilovePdfCompressEndpoint = String.fromEnvironment('ILOVEPDF_COMPRESS_ENDPOINT');
  static const paymentApiEndpoint = String.fromEnvironment('PAYMENT_API_ENDPOINT');
  static const paymentApiKey = String.fromEnvironment('PAYMENT_API_KEY');
}
