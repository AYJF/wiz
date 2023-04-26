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
              divisions: 10,
              label: _currentSliderValue.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentSliderValue = value;
                });

                widget.wizLight.setBrightness(value.round());
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingActionButton(
                      heroTag: const Text('rgb'),
                      child: const Icon(Icons.color_lens),
                      onPressed: () {
                        widget.wizLight.setRgb([125, 0, 0]);
                      }),
                  FloatingActionButton(
                      heroTag: const Text('cw'),
                      child: const Icon(Icons.cloud_off),
                      onPressed: () {
                        widget.wizLight.setColdWhite(255);
                      }),
                  FloatingActionButton(
                      heroTag: const Text('ww'),
                      child: const Icon(Icons.brightness_1),
                      onPressed: () {
                        widget.wizLight.setWarmWhite(255);
                      })
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
