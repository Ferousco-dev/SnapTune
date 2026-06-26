import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:photo_manager/photo_manager.dart';

class FaceDetectionService {
  FaceDetector? _detector;

  FaceDetector get _faceDetector {
    return _detector ??= FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableClassification: false,
        enableLandmarks: false,
        enableTracking: false,
        minFaceSize: 0.1,
      ),
    );
  }

  // Returns number of faces detected in the asset. Returns 0 on any error.
  Future<int> countFaces(AssetEntity asset) async {
    try {
      final file = await asset.file;
      if (file == null) return 0;
      final input = InputImage.fromFile(file);
      final faces = await _faceDetector.processImage(input);
      return faces.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> close() async {
    await _detector?.close();
    _detector = null;
  }
}
