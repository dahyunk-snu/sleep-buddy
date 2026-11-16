class AccelerometerData {
  final double x, y, z;
  AccelerometerData({required this.x, required this.y, required this.z});

  // 디버깅을 위한 toString() 메소드
  @override
  String toString() =>
      'AccelerometerData(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, z: ${z.toStringAsFixed(2)})';
}
