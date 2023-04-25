import 'package:flutter/material.dart';
import 'package:wiz/wiz.dart';

class LightControl extends StatefulWidget {
  const LightControl({Key? key, required this.wizLight}) : super(key: key);
  final WizLight wizLight;

  @override
  State<LightControl> createState() => _LightControlState();
}

class _LightControlState extends State<LightControl> {
  late double _currentSliderValue;

  @override
  void initState() {
    _currentSliderValue = widget.wizLight.brightness.toDouble();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Control View"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Brightness"),
            Slider(
              value: _currentSliderValue,
              max: 255,
              divisions: 255,
              label: _currentSliderValue.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentSliderValue = value;
                });

                widget.wizLight.setBrightness(value.round());
              },
            ),
          ],
        ),
      ),
    );
  }
}
