import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'temp.dart';
import 'zone1.dart';
import 'zone2.dart';
import 'zone3.dart';

class Information extends StatefulWidget {
  @override
  _InformationState createState() => _InformationState();
}

class _InformationState extends State<Information> {
  double temperature = 25.0;
  double humidityZone1 = 45.0;

  double humidityZone2 = 50.0;
  double humidityZone3 = 60.0;
  double air_humidity = 0.0;
  bool isManualModeTemp = false;

  bool isFogOnZone1 = false;
  bool isWaterOnZone1 = false;
  bool isManualModeZone1 = true;
  double targetHumidityZone1 = 0.0;
  double desiredTemp = 0.0;
  String humidityMessageZone1 = "กำลังโหลด...";
  String openTimeZone1 = "--:--";
  String closeTimeZone1 = "--:--";

  bool isWaterOnZone2 = false;
  bool isManualModeZone2 = true;
  double targetHumidityZone2 = 0.0;
  String humidityMessageZone2 = "กำลังโหลด...";
  String openTimeZone2 = "--:--";
  String closeTimeZone2 = "--:--";

  bool isWaterOnZone3 = false;
  bool isManualModeZone3 = true;
  double targetHumidityZone3 = 0.0;
  String humidityMessageZone3 = "กำลังโหลด...";
  String openTimeZone3 = "--:--";
  String closeTimeZone3 = "--:--";
  int isFogOn = 1;

  late DatabaseReference respond1Ref;
  late DatabaseReference respond2Ref;
  Timer? _responseTimer;
  bool _waitingForResponse = false;

  double currentTemperature = 0.0;
  @override
  void initState() {
    super.initState();
    _loadZone1Data();
    _loadZone2Data();
    _loadZone3Data();
    _loadFogStatus();
    _loadTemperatureFromFirebase();
    _listenToTempMode();
    _listenDesiredTemp();

    respond1Ref = FirebaseDatabase.instance.ref('respond1');
    respond2Ref = FirebaseDatabase.instance.ref('respond2');
    respond2Ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == 1) {
        if (_waitingForResponse) {
          _waitingForResponse = false;
          _responseTimer?.cancel();
          _showStatusPopup('ออนไลน์', Colors.green);

          respond1Ref.set(0);
        }
        respond2Ref.set(0);
      }
    });
  }

  void _sendCheckStatus() {
    FirebaseDatabase.instance.ref('respond1').set(1);

    _waitingForResponse = true;
    _responseTimer?.cancel();
    _responseTimer = Timer(const Duration(seconds: 5), () {
      if (_waitingForResponse) {
        _waitingForResponse = false;
        _showStatusPopup('ออฟไลน์', Colors.red);
        respond1Ref.set(0);
      }
    });
  }

  void _showStatusPopup(String msg, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('สถานะ'),
        content: Text(
          msg,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _responseTimer?.cancel();
    super.dispose();
  }

  void _listenDesiredTemp() {
    FirebaseDatabase.instance.ref('FibTemp').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is num) {
        setState(() {
          desiredTemp = data.toDouble();
          print('ค่าอุณหภูมิที่ดึงจาก Firebase: $desiredTemp');
        });
      } else {
        print('ข้อมูลอุณหภูมิไม่ถูกต้องหรือไม่พบใน Firebase');
      }
    });
  }

  void _listenToTempMode() {
    final DatabaseReference modeRef =
        FirebaseDatabase.instance.ref('Fib_Buttons/AuTo_Temp');

    modeRef.onValue.listen((event) {
      final value = event.snapshot.value;
      print("DEBUG: AuTo_Temp = $value (${value.runtimeType})");

      if (value != null) {
        bool newMode = value == 1;
        if (newMode != isManualModeTemp) {
          print("DEBUG: Mode Changed: $newMode");
          setState(() {
            isManualModeTemp = newMode;
          });
        }
      } else {
        print("ERROR: No value received");
      }
    });
  }

  void _loadFogStatus() {
    DatabaseReference fogRef =
        FirebaseDatabase.instance.ref('Fib_Buttons/ON_OFF_Temp');
    fogRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is int) {
        setState(() {
          isFogOn = data == 1 ? 1 : 0;
        });
      }
    });

    DatabaseReference autoFogRef = FirebaseDatabase.instance.ref('AutoFogy');
    autoFogRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is int) {
        setState(() {
          isFogOn = data == 1 ? 1 : 0;
        });
      }
    });
  }

  void _loadTemperatureFromFirebase() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('Temp');

    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is num) {
        setState(() {
          currentTemperature = data.toDouble();
        });
      }
    });
  }

  void _loadZone1Data() {
    DatabaseReference refTargetHumidity =
        FirebaseDatabase.instance.ref('FibSoilZ1');
    refTargetHumidity.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is num) {
        setState(() {
          targetHumidityZone1 = data.toInt().toDouble();
        });
      }
    });

    DatabaseReference refWaterStatus =
        FirebaseDatabase.instance.ref('Fib_Buttons/ON_OFF_Z1');
    refWaterStatus.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && (data is int || data is double)) {
        setState(() {
          isWaterOnZone1 = data == 1;
        });
      }
    });

    DatabaseReference refAutoWater =
        FirebaseDatabase.instance.ref('AutoWaterZ1');
    refAutoWater.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && (data is int || data is double)) {
        setState(() {
          isWaterOnZone1 = data == 1;
        });
      }
    });

    DatabaseReference zone1AirRef = FirebaseDatabase.instance.ref('Hum');

    zone1AirRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        setState(() {
          air_humidity = double.tryParse(data.toString()) ?? 0;
        });
      }
    });

    DatabaseReference ref = FirebaseDatabase.instance.ref();
    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          openTimeZone1 = data['FibTimestartZ1'] ?? "--:--";
          closeTimeZone1 = data['FibTimestopZ1'] ?? "--:--";
        });
      }
    });

    final DatabaseReference modeRef =
        FirebaseDatabase.instance.ref('Fib_Buttons');

    modeRef.onValue.listen((event) {
      final data = event.snapshot.value;
      print("DEBUG: data = $data");

      if (data != null && data is Map) {
        final autoZ1 = data['AuTo_Z1'];
        print("DEBUG: AuTo_Z1 = $autoZ1");

        setState(() {
          isManualModeZone1 = autoZ1 == 1;
        });
      }
    });

    DatabaseReference refHumidityDisplay =
        FirebaseDatabase.instance.ref('Soil_As');
    refHumidityDisplay.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is num) {
        setState(() {
        
          humidityZone1 = data.toInt().toDouble();
        });
      }
    });
  }

  void _loadZone2Data() {
    DatabaseReference refTargetHumidity =
        FirebaseDatabase.instance.ref('FibSoilZ2');
    refTargetHumidity.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is num) {
        setState(() {
          targetHumidityZone2 = data.toDouble();
        });
      }
    });

    DatabaseReference refWaterStatus =
        FirebaseDatabase.instance.ref('Fib_Buttons/ON_OFF_Z2');
    refWaterStatus.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && (data is int || data is double)) {
        setState(() {
          isWaterOnZone2 = data == 1;
        });
      }
    });

    DatabaseReference refAutoWater =
        FirebaseDatabase.instance.ref('AutoWaterZ2');
    refAutoWater.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && (data is int || data is double)) {
        setState(() {
          isWaterOnZone2 = data == 1;
        });
      }
    });

    DatabaseReference ref = FirebaseDatabase.instance.ref();
    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          openTimeZone2 = data['FibTimestartZ2'] ?? "--:--";
          closeTimeZone2 = data['FibTimestopZ2'] ?? "--:--";
        });
      }
    });

    final DatabaseReference modeRef =
        FirebaseDatabase.instance.ref('Fib_Buttons');

    modeRef.onValue.listen((event) {
      final data = event.snapshot.value;
      print("DEBUG: data = $data");

      if (data != null && data is Map) {
        final autoZ2 = data['AuTo_Z2'];
        print("DEBUG: AuTo_Z2 = $autoZ2");

        setState(() {
          isManualModeZone2 = autoZ2 == 1;
        });
      }
    });

    DatabaseReference refHumidityDisplay =
        FirebaseDatabase.instance.ref('Soil_Bs');
    refHumidityDisplay.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is num) {
        setState(() {
          humidityZone2 = data.toDouble();
        });
      }
    });
  }

  void _loadZone3Data() {
    DatabaseReference refTargetHumidity =
        FirebaseDatabase.instance.ref('FibSoilZ3');
    refTargetHumidity.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is num) {
        setState(() {
          targetHumidityZone3 = data.toDouble();
        });
      }
    });

    DatabaseReference refWaterStatus =
        FirebaseDatabase.instance.ref('Fib_Buttons/ON_OFF_Z3');
    refWaterStatus.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && (data is int || data is double)) {
        setState(() {
          isWaterOnZone3 = data == 1;
        });
      }
    });
    DatabaseReference refAutoWater =
        FirebaseDatabase.instance.ref('AutoWaterZ3');
    refAutoWater.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && (data is int || data is double)) {
        setState(() {
          isWaterOnZone3 = data == 1;
        });
      }
    });

    DatabaseReference ref = FirebaseDatabase.instance.ref();
    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          openTimeZone3 = data['FibTimestartZ3'] ?? "--:--";
          closeTimeZone3 = data['FibTimestopZ3'] ?? "--:--";
        });
      }
    });

    final DatabaseReference modeRef =
        FirebaseDatabase.instance.ref('Fib_Buttons');

    modeRef.onValue.listen((event) {
      final data = event.snapshot.value;
      print("DEBUG: data = $data");

      if (data != null && data is Map) {
        final autoZ3 = data['AuTo_Z3'];
        print("DEBUG: AuTo_Z3 = $autoZ3");

        setState(() {
          isManualModeZone3 = autoZ3 == 1;
        });
      }
    });

    DatabaseReference refHumidityDisplay =
        FirebaseDatabase.instance.ref('Soil_Cs');
    refHumidityDisplay.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is num) {
        setState(() {
          humidityZone3 = data.toDouble();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลโรงเรือน'),
        backgroundColor: Colors.green.shade700,
        actions: [
          TextButton(
            onPressed: _sendCheckStatus,
            child: const Text(
              'เช็คสถานะ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TempPage()),
                  );
                },
                child: Card(
                  elevation: 5,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'อุณหภูมิในโรงเรือน',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 500),
                                child: Text(
                                  '${currentTemperature.toStringAsFixed(0)}°C',
                                  key: ValueKey(currentTemperature),
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    isFogOn == 1
                                        ? Icons.cloud_done_rounded
                                        : Icons.cloud_off_rounded,
                                    color: isFogOn == 1
                                        ? Colors.green
                                        : Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "สถานะพ่นหมอก: ${isFogOn == 1 ? 'ON' : 'OFF'}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: isFogOn == 1
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'อุณหภูมิที่ตั้ง: ${desiredTemp.toInt()}°C',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    isManualModeTemp
                                        ? Icons.fingerprint
                                        : Icons.settings_suggest,
                                    size: 20,
                                    color: isManualModeTemp
                                        ? Colors.orange
                                        : Colors.blue,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "โหมด: ${isManualModeTemp ? 'Manual' : 'Auto'}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: isManualModeTemp
                                          ? Colors.orange
                                          : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),
             
              GestureDetector(
                onTap: () async {
                  bool? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Zone1Page(humidity: humidityZone1),
                    ),
                  );
                  if (result == true) {
                    _loadZone1Data();
                  }
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ZONE 1",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "ความชื้นดิน: ${humidityZone1.toInt()}%",
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          "ความชื้นอากาศ: ${air_humidity.toInt()}%",
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: humidityZone1 / 100,
                          minHeight: 14,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            humidityZone1 < 30
                                ? Colors.red
                                : humidityZone1 < 60
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "ความชื้นที่กำหนด: ${targetHumidityZone1.toInt()}%",
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 12),
                        Divider(),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isWaterOnZone1 ? "WATER: ON" : "WATER: OFF",
                              style: TextStyle(
                                fontSize: 18,
                                color:
                                    isWaterOnZone1 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isManualModeZone1 ? 'โหมด: Manual' : 'โหมด: Auto',
                              style: TextStyle(
                                fontSize: 16,
                                color: isManualModeZone1
                                    ? Colors.orange
                                    : Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          "เวลาเปิดน้ำ: $openTimeZone1",
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          "เวลาปิดน้ำ: $closeTimeZone1",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              GestureDetector(
                onTap: () async {
                  bool? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Zone2Page(humidity: humidityZone2),
                    ),
                  );
                  if (result == true) {
                    _loadZone2Data();
                  }
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ZONE 2",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "ความชื้นดิน: ${humidityZone2.toInt()}%",
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: humidityZone2 / 100,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            humidityZone2 < 30
                                ? Colors.red
                                : humidityZone2 < 60
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "ความชื้นที่กำหนด: ${targetHumidityZone2.toInt()}%",
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        Divider(),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isWaterOnZone2 ? "WATER: ON" : "WATER : OFF",
                              style: TextStyle(
                                fontSize: 18,
                                color:
                                    isWaterOnZone2 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 20),
                            Text(
                              "โหมด: ${isManualModeZone2 ? 'Manual' : 'Auto'}",
                              style: TextStyle(
                                fontSize: 16,
                                color: isManualModeZone2
                                    ? Colors.orange
                                    : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          "เวลาเปิดน้ำ: $openTimeZone2",
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          "เวลาปิดน้ำ: $closeTimeZone2",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              GestureDetector(
                onTap: () async {
                  bool? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Zone3Page(humidity: humidityZone3),
                    ),
                  );
                  if (result == true) {
                    _loadZone3Data();
                  }
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ZONE 3",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "ความชื้นดิน: ${humidityZone3.toInt()}%",
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: humidityZone3 / 100,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            humidityZone3 < 30
                                ? Colors.red
                                : humidityZone3 < 60
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "ความชื้นที่กำหนด: ${targetHumidityZone3.toInt()}%",
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        Divider(),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isWaterOnZone3 ? "WATER: ON" : "WATER : OFF",
                              style: TextStyle(
                                fontSize: 18,
                                color:
                                    isWaterOnZone3 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 20),
                            Text(
                              "โหมด: ${isManualModeZone3 ? 'Manual' : 'Auto'}",
                              style: TextStyle(
                                fontSize: 16,
                                color: isManualModeZone3
                                    ? Colors.orange
                                    : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          "เวลาเปิดน้ำ: $openTimeZone3",
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          "เวลาปิดน้ำ: $closeTimeZone3",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TemperatureCircle extends StatelessWidget {
  final double temperature;
  TemperatureCircle({required this.temperature});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: 250,
      child: Center(
        child: CustomPaint(
          size: Size(300, 300),
          painter: TemperaturePainter(temperature),
        ),
      ),
    );
  }
}

class ZoneContainer extends StatelessWidget {
  final String zoneName;
  final double humidity;
  final double? airHumidity;
  final String? waterStatus;
  final String? humidityMessage;
  final String? openWaterTime;
  final String? closeWaterTime;
  final bool? isManualMode;
  final String? fogStatus;

  ZoneContainer({
    required this.zoneName,
    required this.humidity,
    this.airHumidity,
    this.waterStatus,
    this.humidityMessage,
    this.openWaterTime,
    this.closeWaterTime,
    this.isManualMode,
    this.fogStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
        border: Border.all(color: Colors.blueAccent, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zoneName,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent)),
                if (fogStatus != null)
                  Text(
                    fogStatus!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: fogStatus?.contains("ON") == true
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                if (waterStatus != null)
                  Text(
                    waterStatus!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: waterStatus == "WATER: ON"
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                if (humidityMessage != null)
                  Text(
                    humidityMessage?.replaceAll(RegExp(r'\.\d+'), '') ?? "",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                if (openWaterTime != null)
                  Text(openWaterTime!,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                if (closeWaterTime != null)
                  Text(closeWaterTime!,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                if (isManualMode != null)
                  Text(
                    isManualMode! ? "โหมด: Manual" : "โหมด: Auto",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (zoneName == "ZONE 1")
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.5),
                  ),
                  child: Center(
                    child: Text(
                      '${airHumidity?.toStringAsFixed(0) ?? '0'}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
              if (zoneName == "ZONE 1") const SizedBox(height: 10),
              if (zoneName == "ZONE 1")
                const Text(
                  'ค่าความชื้นในอากาศ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              const SizedBox(height: 18), 
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.5),
                ),
                child: Center(
                  child: Text(
                    '${humidity.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'ค่าความชื้นในดิน',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TemperaturePainter extends CustomPainter {
  final double temperature;
  TemperaturePainter(this.temperature);

  @override
  void paint(Canvas canvas, Size size) {
    Paint circlePaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
