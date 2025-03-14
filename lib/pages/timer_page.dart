// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

enum Phase { focus, shortBreak, longBreak }

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Timer? timer;
  int remainingSeconds = 1500; // 25 minutes
  bool isTimerRunning = false;
  int sessionCount = 0;
  DateTime? startTime;
  DateTime? endTime;
  final int totalFocusTime = 1500;

  Phase currentPhase = Phase.focus;
  int completedSessions = 0;
  final int sessionsBeforeLongBreak = 4;
  final int shortBreakDuration = 300; // 5 minutes
  final int longBreakDuration = 900; // 15 minutes

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  int get currentPhaseDuration {
    switch (currentPhase) {
      case Phase.focus:
        return totalFocusTime;
      case Phase.shortBreak:
        return shortBreakDuration;
      case Phase.longBreak:
        return longBreakDuration;
    }
  }

  String _getPhaseName(Phase phase) {
    switch (phase) {
      case Phase.focus:
        return 'Focus';
      case Phase.shortBreak:
        return 'Short Break';
      case Phase.longBreak:
        return 'Long Break';
    }
  }

  void _startTimer() {
    if (!isTimerRunning) {
      if (remainingSeconds == currentPhaseDuration) {
        setState(() {
          startTime = DateTime.now();
          endTime = null;
          if (currentPhase == Phase.focus) {
            sessionCount++;
          }
        });
      }

      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingSeconds > 0) {
          setState(() {
            remainingSeconds--;
          });
        } else {
          timer.cancel();
          DateTime now = DateTime.now();
          setState(() {
            isTimerRunning = false;
            endTime = now;
            if (currentPhase == Phase.focus) {
              completedSessions++;
            }
          });

          Phase nextPhase;
          int nextRemainingSeconds;

          if (currentPhase == Phase.focus) {
            if (completedSessions % sessionsBeforeLongBreak == 0) {
              nextPhase = Phase.longBreak;
              nextRemainingSeconds = longBreakDuration;
            } else {
              nextPhase = Phase.shortBreak;
              nextRemainingSeconds = shortBreakDuration;
            }
          } else {
            nextPhase = Phase.focus;
            nextRemainingSeconds = totalFocusTime;
          }

          setState(() {
            currentPhase = nextPhase;
            remainingSeconds = nextRemainingSeconds;
          });

          _startTimer();
        }
      });

      setState(() {
        isTimerRunning = true;
      });
    }
  }

  void _pauseTimer() {
    timer?.cancel();
    setState(() {
      isTimerRunning = false;
    });
  }

  void _stopTimer() {
    timer?.cancel();
    setState(() {
      isTimerRunning = false;
      currentPhase = Phase.focus;
      remainingSeconds = totalFocusTime;
      endTime = DateTime.now();
    });
  }

  String _formatTime(int seconds) {
    int minutes = (seconds ~/ 60);
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Flow State Tracker',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTimerSection(),
          const SizedBox(height: 30),
          _buildPriorityTasks(),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Session $sessionCount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Text(
                '${_formatTime(currentPhaseDuration)} - ${_getPhaseName(currentPhase)}',
                style: TextStyle(color: Colors.blue)),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: (currentPhaseDuration - remainingSeconds) /
                        currentPhaseDuration,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  Text(
                    _formatTime(remainingSeconds),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  'Start',
                  Icons.play_arrow,
                  Colors.blue,
                  onPressed: _startTimer,
                  isEnabled: !isTimerRunning,
                ),
                _buildControlButton(
                  'Pause',
                  Icons.pause,
                  Colors.orange,
                  onPressed: _pauseTimer,
                  isEnabled: isTimerRunning,
                ),
                _buildControlButton(
                  'Stop',
                  Icons.stop,
                  Colors.red,
                  onPressed: _stopTimer,
                  isEnabled: true,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Start Time: ${startTime != null ? DateFormat('h:mm:ss a').format(startTime!) : '--'}'),
                Text(
                    'End Time: ${endTime != null ? DateFormat('h:mm:ss a').format(endTime!) : '--'}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(
    String text,
    IconData icon,
    Color color, {
    required VoidCallback onPressed,
    bool isEnabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          IconButton(
            icon: Icon(icon),
            color: isEnabled ? color : color.withOpacity(0.5),
            onPressed: isEnabled ? onPressed : null,
          ),
          Text(text,
              style:
                  TextStyle(color: isEnabled ? color : color.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildPriorityTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Priority Tasks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) => CheckboxListTile(
            title: Text('Task ${index + 1}'),
            value: false,
            onChanged: (value) {},
          ),
        ),
      ],
    );
  }
}
