class AppSecrets {
  static const llmApiKey = String.fromEnvironment('LLM_API_KEY');
  static const llmEndpoint = String.fromEnvironment(
    'LLM_ENDPOINT',
    defaultValue: 'https://api.openai.com/v1/chat/completions',
  );
  static const llmProvider = String.fromEnvironment(
    'LLM_PROVIDER',
    defaultValue: 'auto',
  );
  static const llmModel = String.fromEnvironment(
    'LLM_MODEL',
    defaultValue: 'gpt-4o-mini',
  );
  static const mapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const fcmWebVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');
  static const openWeatherApiKey = String.fromEnvironment('OPENWEATHER_API_KEY');
  static const cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'de9vss4ti',
  );
  static const cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'notes_upload',
  );
  static const ocrApiKey = String.fromEnvironment('OCR_API_KEY');
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '179357566644-oedf89kckoa8jgnaeic6klri17r7mc5n.apps.googleusercontent.com',
  );
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '179357566644-oedf89kckoa8jgnaeic6klri17r7mc5n.apps.googleusercontent.com',
  );
  static const ilovePdfApiKey = String.fromEnvironment('ILOVEPDF_API_KEY');
  static const ilovePdfCompressEndpoint = String.fromEnvironment(
    'ILOVEPDF_COMPRESS_ENDPOINT',
  );
  static const paymentApiEndpoint = String.fromEnvironment(
    'PAYMENT_API_ENDPOINT',
  );
  static const paymentApiKey = String.fromEnvironment('PAYMENT_API_KEY');
}
