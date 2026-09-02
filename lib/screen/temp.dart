import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TempPage extends StatefulWidget {
  const TempPage({Key? key}) : super(key: key);

  @override
  State<TempPage> createState() => _TempPageState();
}

class _TempPageState extends State<TempPage> {
  double airTemp = 0.0;
  double desiredTemp = 0.0;
  bool isFogOn = false;
  bool isManualMode = true;
  final TextEditingController _desiredTempController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listenAirTemp();
    _listenFogStatus();
    _listenModeStatusFromFirebase();
    _listenDesiredTemp();
  }

  void triggerFirebaseButton() async {
    final ref = FirebaseDatabase.instance.ref('Fib_Buttons/Fib_Button4');

    await ref.set(64); // ส่งค่า 1
  }

  void _listenAirTemp() {
    FirebaseDatabase.instance.ref('Temp').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is num) {
        setState(() {
          airTemp = data.toDouble();
        });
      }
    });
  }

  void _listenFogStatus() {
    FirebaseDatabase.instance
        .ref('Fib_Buttons/ON_OFF_Temp')
        .onValue
        .listen((event) {
      final fog = event.snapshot.value;
      if (fog != null && (fog is int || fog is double)) {
        setState(() {
          isFogOn = fog == 1;
        });
      }
    });
  }

  void _listenModeStatusFromFirebase() {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref('Fib_Buttons/AuTo_Temp');

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

  void _listenDesiredTemp() {
    FirebaseDatabase.instance.ref('FibTemp').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is num) {
        setState(() {
          desiredTemp = data.toDouble();
        });
      }
    });
  }

  void _sendFogStatus(bool isOn) {
    FirebaseDatabase.instance.ref('Fib_Buttons/ON_OFF_Temp').set(isOn ? 1 : 0);
    setState(() {
      isFogOn = isOn;
    });
  }

  void _toggleMode(bool manualMode) async {
    final modeValue = manualMode ? 1 : 0;

    // อัปเดตโหมดใน Firebase
    await FirebaseDatabase.instance.ref('Fib_Buttons/AuTo_Temp').set(modeValue);

    // ถ้าเปลี่ยนจาก Manual → Auto ให้ปิดพ่นหมอก
    if (!manualMode) {
      await FirebaseDatabase.instance.ref('Fib_Buttons/ON_OFF_Temp').set(0);

      setState(() {
        isFogOn = false; // อัปเดต UI ทันที
      });
    }

    // อัปเดตสถานะโหมด
    setState(() {
      isManualMode = manualMode;
    });

    _saveMode(manualMode);
  }

  void _saveMode(bool manualMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isManualModetemp', manualMode);
  }

  Widget _buildTemperatureCircle(
      {required String label, required double value}) {
    const maxValue = 40.0;
    final progress = (value / maxValue).clamp(0.0, 1.0);

    Color tempColor;
    if (value < 18) {
      tempColor = Colors.blue;
    } else if (value < 30) {
      tempColor = Colors.green;
    } else {
      tempColor = Colors.red;
    }

    return Column(
      children: [
        // วงกลมอุณหภูมิ
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 16,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(tempColor),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                      fontSize: 42, fontWeight: FontWeight.bold),
                ),
                const Text(
                  '°C',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
  void dispose() {
    _desiredTempController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Color(0xFF66BB6A),
        title: Text('อุณหภูมิ'),
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
                      'อุณหภูมิ (°C)', // หัวข้อใหม่
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // วงกลมแสดงความชื้นดินเท่านั้น
                    _buildTemperatureCircle(label: 'อุณหภูมิ', value: airTemp),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // แสดงสถานะพ่นหมอก
            SizedBox(height: 20),
            if (isManualMode)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('ควบคุมระบบน้ำ',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => _sendFogStatus(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('เปิดพ่นหมอก'),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => _sendFogStatus(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('ปิดพ่นหมอก'),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        isFogOn ? 'สถานะ: กำลังพ่นหมอก' : 'สถานะ: ปิดหมอก',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isFogOn ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 20),

            // ตั้งค่าอุณหภูมิเป้าหมาย
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('ตั้งค่าอุณหภูมิเป้าหมาย',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextField(
                      controller: _desiredTempController,
                      textAlign: TextAlign.center,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'กรอกอุณหภูมิที่ต้องการ (°C)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'อุณหภูมิที่ตั้งไว้: ${desiredTemp.toStringAsFixed(0)}°C',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
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
                double? enteredTemp =
                    double.tryParse(_desiredTempController.text);
                if (enteredTemp != null) {
                  FirebaseDatabase.instance.ref('FibTemp').set(enteredTemp);
                  triggerFirebaseButton(); // เรียกฟังก์ชันกดปุ่ม Firebase
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('บันทึกค่าอุณหภูมิเรียบร้อยแล้ว'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
