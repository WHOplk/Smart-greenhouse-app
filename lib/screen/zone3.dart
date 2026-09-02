import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Zone3Page extends StatefulWidget {
  final double humidity;

  Zone3Page({required this.humidity});

  @override
  _Zone3PageState createState() => _Zone3PageState();
}

class _Zone3PageState extends State<Zone3Page> {
  bool isWaterOn = false;
  double targetHumidity = 0.0;
  double humidity = 0.0; // ประกาศตัวแปร humidity
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _openWaterController = TextEditingController();
  final TextEditingController _closeWaterController = TextEditingController();
  String setHumidityMessage = '';
  bool isManualMode = true;

  @override
  void initState() {
    super.initState();
    _loadTargetHumidity();
    _loadWaterStatus();
    _loadFibTimestartZ3();
    _loadFibTimestopZ3();
    _loadMode();
    _loadCurrentHumidityFromFirebase();
    _loadTargetHumidityFromFirebase();
    _listenWaterStatusFromFirebase();
    _listenModeStatusFromFirebase();
  }

  void triggerFirebaseButton() async {
    final ref = FirebaseDatabase.instance.ref('Fib_Buttons/Fib_Button3');

    await ref.set(64); // ส่งค่า 1
  }

  void _loadFibTimestartZ3() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('FibTimestartZ3');

    try {
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value is String) {
        setState(() {
          _openWaterController.text = snapshot.value as String;
        });
      }
    } catch (error) {
      print("Error loading FibTimestartZ1: $error");
    }
  }

  void _loadFibTimestopZ3() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('FibTimestopZ3');

    try {
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value is String) {
        setState(() {
          _closeWaterController.text = snapshot.value as String;
        });
      }
    } catch (error) {
      print("Error loading FibTimestopZ1: $error");
    }
  }

  void _listenModeStatusFromFirebase() {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref('Fib_Buttons/AuTo_Z3');

    ref.onValue.listen((event) {
      final modeValue = event.snapshot.value;
      if (modeValue != null) {
        setState(() {
          isManualMode = modeValue.toString() == '1'; // 1 = Manual, 0 = Auto
        });
      } else {
        print("Mode data is null");
      }
    });
  }

  void _listenWaterStatusFromFirebase() {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref('Fib_Buttons/ON_OFF_Z3');

    ref.onValue.listen((event) {
      final status = event.snapshot.value;
      if (status != null) {
        setState(() {
          isWaterOn = status.toString() == '1';
        });
      }
    });
  }

  void _loadCurrentHumidityFromFirebase() async {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref('Soil_Cs'); // ใช้ path ที่ถูกต้อง

    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is num) {
        setState(() {
          humidity = data.toDouble(); // อัปเดตค่าความชื้นจาก Firebase
        });
      } else {
        // ถ้าค่าเป็น null หรือไม่ใช่ตัวเลข
        print("Invalid data or data is null");
      }
    });
  }

  void _loadTargetHumidityFromFirebase() {
    DatabaseReference ref = FirebaseDatabase.instance.ref('FibSoilZ3');

    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is num) {
        setState(() {
          targetHumidity = data.toDouble();
          _controller.text =
              _controller.text = targetHumidity.toInt().toString();
          setHumidityMessage =
              'ค่าความชื้นที่ตั้งไว้: ${targetHumidity.toStringAsFixed(0)}%';
        });
      }
    });
  }

  // ✅ บันทึกโหมด Manual / Auto ลง SharedPreferences
  void _saveMode(bool manualMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isManualModeZone3', manualMode);
  }

// ✅ โหลดโหมด Manual / Auto ที่บันทึกไว้
  void _loadMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isManualMode = prefs.getBool('isManualModeZone3') ?? true;
    });
  }

  void _saveTargetHumidity(double humidity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('targetHumidityZone3', humidity);
    prefs.setString('setHumidityMessageZone3',
        'ค่าความชื้นที่ตั้งไว้: ${humidity.toStringAsFixed(1)}%');

    FirebaseDatabase.instance.ref('FibSoilZ3').set(humidity);

    setState(() {
      setHumidityMessage =
          'ค่าความชื้นที่ตั้งไว้: ${humidity.toStringAsFixed(1)}%';
    });
    triggerFirebaseButton();
  }

  void _loadTargetHumidity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? savedHumidity = prefs.getDouble('targetHumidityZone3');
    String? savedMessage = prefs.getString('setHumidityMessageZone3');

    if (savedHumidity != null && savedMessage != null) {
      setState(() {
        targetHumidity = savedHumidity;
        setHumidityMessage = savedMessage;
        _controller.text = savedHumidity.toString();
      });
    }
  }

  void _saveWaterStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isWaterOnZone3', status);
  }

  void _loadWaterStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? savedWaterStatus = prefs.getBool('isWaterOnZone3');
    if (savedWaterStatus != null) {
      setState(() {
        isWaterOn = savedWaterStatus;
      });
    }
  }

  void sendWaterStatus(bool turnOn) {
    FirebaseDatabase.instance
        .ref('Fib_Buttons/ON_OFF_Z3')
        .set(turnOn ? 1 : 0); // 1 = เปิดน้ำ, 0 = ปิดน้ำ

    setState(() {
      isWaterOn = turnOn;
    });
  }

  void _toggleMode(bool manualMode) {
    final modeValue = manualMode ? 1 : 0;

    FirebaseDatabase.instance.ref('Fib_Buttons/AuTo_Z3').set(modeValue);

    setState(() {
      isManualMode = manualMode;
    });

    _saveMode(manualMode);

    // ✅ ปิดน้ำทันทีเมื่อเปลี่ยนจาก Manual → Auto
    if (!manualMode) {
      sendWaterStatus(false);
      _saveWaterStatus(false);
    }
  }

  void _saveFibTimestartZ3() async {
    String time = _openWaterController.text;
    if (time.contains(":")) {
      FirebaseDatabase.instance.ref('FibTimestartZ3').set(time);
    }
  }

  void _saveFibTimestopZ3() async {
    String time = _closeWaterController.text;
    if (time.contains(":")) {
      FirebaseDatabase.instance.ref('FibTimestopZ3').set(time);
    }
  }

  void _saveWaterTimer() {
    _saveFibTimestartZ3();
    _saveFibTimestopZ3();
    triggerFirebaseButton();
  }

  Color _humidityColor(double value) {
    if (value < 30) return Colors.red;
    if (value < 60) return Colors.orange;
    return Colors.green;
  }

  Widget _buildHumidityCircle({
    required String label,
    required double value,
    String unit = '%',
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: CircularProgressIndicator(
                value: (value / 100).clamp(0.0, 1.0), // 0–1
                strokeWidth: 14,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(_humidityColor(value)),
              ),
            ),
            Column(
              children: [
                Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.bold),
                ),
                Text(
                  unit,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Color(0xFF66BB6A),
        title: Text('Zone 3'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _toggleMode(!isManualMode);
            },
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              isManualMode ? 'Manual' : 'Auto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'ความชื้นในดิน (%)', // หัวข้อใหม่
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // วงกลมแสดงความชื้นดินเท่านั้น
                    _buildHumidityCircle(label: 'ดิน', value: humidity),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            if (isManualMode)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('ควบคุมระบบน้ำ',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.water_drop),
                            label: Text('เปิดน้ำ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              sendWaterStatus(true);
                              _saveWaterStatus(true);
                            },
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.block),
                            label: Text('ปิดน้ำ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              sendWaterStatus(false);
                              _saveWaterStatus(false);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        isWaterOn ? 'WATER : ON' : 'WATER : OFF',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isWaterOn ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('ตั้งค่าความชื้นเป้าหมาย',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'ความชื้นที่ต้องการ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    if (setHumidityMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          setHumidityMessage,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('ตั้งเวลาเปิด/ปิดน้ำ',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextField(
                      controller: _openWaterController,
                      keyboardType: TextInputType.datetime,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'กรุณากรอกเวลาเปิด (HH:mm)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _closeWaterController,
                      keyboardType: TextInputType.datetime,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'กรุณากรอกเวลาปิด (HH:mm)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text('ยืนยันการตั้งค่า'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // 1. บันทึกค่าความชื้น
                double enteredHumidity =
                    double.tryParse(_controller.text) ?? 0.0;
                setState(() {
                  targetHumidity = enteredHumidity;
                  setHumidityMessage =
                      'ค่าความชื้นที่ตั้งไว้: ${enteredHumidity.toStringAsFixed(0)}%';
                });
                _saveTargetHumidity(enteredHumidity);

                // 2. บันทึกเวลาเปิด/ปิดน้ำ
                _saveWaterTimer();

                // 3. แสดง SnackBar หรือข้อความยืนยัน
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('บันทึกค่าความชื้นและเวลาเรียบร้อยแล้ว'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
