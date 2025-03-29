import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'task_provider.dart';

enum Phase { focus, shortBreak, longBreak }

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with TickerProviderStateMixin {
  Timer? timer;
  int remainingSeconds = 1500;
  bool isTimerRunning = false;
  int sessionCount = 0;
  DateTime? startTime;
  DateTime? endTime;
  int totalFocusTime = 1500;

  // Timer options
  final Map<String, int> timerOptions = {
    'Pomodoro (25m)': 1500,
    'Focus Hour (1h)': 3600,
    'Quick Focus (15m)': 900,
    'Deep Work (90m)': 5400,
  };
  String selectedTimerOption = 'Pomodoro (25m)';

  late AnimationController _progressController;
  late AnimationController _buttonScaleController;
  late AnimationController _phaseTransitionController;
  late Animation<double> _buttonScaleAnimation;
  Animation<Color?>? _phaseColorAnimation;

  Phase currentPhase = Phase.focus;
  int completedSessions = 0;
  final int sessionsBeforeLongBreak = 4;
  final int shortBreakDuration = 300;
  final int longBreakDuration = 900;

  // Phase colors
  final Color focusColor = const Color(0xFF4A6FA5);
  final Color shortBreakColor = const Color(0xFF4CAF50);
  final Color longBreakColor = const Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _phaseTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _buttonScaleController,
        curve: Curves.easeInOut,
      ),
    );

    _phaseColorAnimation = ColorTween(
      begin: focusColor,
      end: focusColor,
    ).animate(_phaseTransitionController);

    // Start progress animation
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _progressController.dispose();
    _buttonScaleController.dispose();
    _phaseTransitionController.dispose();
    super.dispose();
  }

  // Timer control methods
  void _startTimer() {
    if (!isTimerRunning) {
      _buttonScaleController
          .forward()
          .then((_) => _buttonScaleController.reverse());

      if (remainingSeconds == currentPhaseDuration) {
        setState(() {
          startTime = DateTime.now();
          endTime = null;
          if (currentPhase == Phase.focus) {
            sessionCount++;
          }
        });
      } else {
        setState(() {
          startTime = DateTime.now();
          endTime = null;
        });
      }

      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          if (remainingSeconds > 0) {
            remainingSeconds--;
          } else {
            timer?.cancel();
            DateTime now = DateTime.now();
            setState(() {
              isTimerRunning = false;
              endTime = now;
              if (currentPhase == Phase.focus) {
                completedSessions++;
              }
            });

            _handlePhaseTransition();
          }
        });
      });

      setState(() => isTimerRunning = true);
    }
  }

  void _handlePhaseTransition() {
    Phase nextPhase;
    int nextRemainingSeconds;
    Color nextColor;

    if (currentPhase == Phase.focus) {
      if (completedSessions % sessionsBeforeLongBreak == 0) {
        nextPhase = Phase.longBreak;
        nextRemainingSeconds = longBreakDuration;
        nextColor = longBreakColor;
      } else {
        nextPhase = Phase.shortBreak;
        nextRemainingSeconds = shortBreakDuration;
        nextColor = shortBreakColor;
      }
    } else {
      nextPhase = Phase.focus;
      nextRemainingSeconds = totalFocusTime;
      nextColor = focusColor;
    }

    _phaseTransitionController.reset();
    _phaseColorAnimation = ColorTween(
      begin: _getPhaseColor(currentPhase),
      end: nextColor,
    ).animate(_phaseTransitionController);

    _phaseTransitionController.forward().then((_) {
      setState(() {
        currentPhase = nextPhase;
        remainingSeconds = nextRemainingSeconds;
        _phaseColorAnimation = ColorTween(
          begin: nextColor,
          end: nextColor,
        ).animate(_phaseTransitionController);
      });
      _startTimer();
    });
  }

  void _pauseTimer() {
    _buttonScaleController
        .forward()
        .then((_) => _buttonScaleController.reverse());
    timer?.cancel();
    setState(() => isTimerRunning = false);
  }

  void _stopTimer() {
    _buttonScaleController
        .forward()
        .then((_) => _buttonScaleController.reverse());
    timer?.cancel();
    setState(() {
      isTimerRunning = false;
      currentPhase = Phase.focus;
      remainingSeconds = totalFocusTime;
      endTime = DateTime.now();
      _phaseColorAnimation = ColorTween(
        begin: focusColor,
        end: focusColor,
      ).animate(_phaseTransitionController);
    });
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      isTimerRunning = false;
      remainingSeconds = totalFocusTime;
      currentPhase = Phase.focus;
    });
  }

  void changeTimerOption(String option) {
    setState(() {
      selectedTimerOption = option;
      totalFocusTime = timerOptions[option]!;
      resetTimer();
    });
  }

  Color _getPhaseColor(Phase phase) {
    switch (phase) {
      case Phase.focus:
        return focusColor;
      case Phase.shortBreak:
        return shortBreakColor;
      case Phase.longBreak:
        return longBreakColor;
    }
  }

  String _getPhaseName(Phase phase) {
    switch (phase) {
      case Phase.focus:
        return 'Focus Session';
      case Phase.shortBreak:
        return 'Short Break';
      case Phase.longBreak:
        return 'Long Break';
    }
  }

  String _formatTime(int seconds) {
    int minutes = (seconds ~/ 60);
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flow State Tracker',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _phaseTransitionController,
          _progressController,
        ]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (_phaseColorAnimation?.value ?? focusColor).withOpacity(0.08),
                  Colors.white,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 14),
                          _buildTimerSection(),
                          const SizedBox(height: 30),
                          _buildPriorityTasks(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimerSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildTimerDropdown(),
            const SizedBox(height: 20),
            Text('Session $sessionCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                )),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: _phaseTransitionController,
              builder: (context, child) {
                return Text(
                  '${_formatTime(currentPhaseDuration)} - ${_getPhaseName(currentPhase)}',
                  style: TextStyle(
                    color: focusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: CircularProgressIndicator(
                            value: _progressController.value *
                                ((currentPhaseDuration - remainingSeconds) /
                                    currentPhaseDuration),
                            strokeWidth: 14,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _phaseColorAnimation?.value ?? focusColor),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Text(
                        _formatTime(remainingSeconds),
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: _getPhaseColor(currentPhase),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildControlButtons(),
            const SizedBox(height: 20),
            _buildSessionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: selectedTimerOption,
        isExpanded: true,
        underline: Container(),
        icon: Icon(Icons.arrow_drop_down, color: _phaseColorAnimation?.value),
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        items: timerOptions.keys.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            changeTimerOption(newValue);
          }
        },
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAnimatedButton(
          label: 'Start',
          icon: Icons.play_arrow,
          onPressed: _startTimer,
          isEnabled: !isTimerRunning,
          color: _phaseColorAnimation?.value ?? focusColor,
        ),
        const SizedBox(width: 20),
        _buildAnimatedButton(
          label: 'Pause',
          icon: Icons.pause,
          onPressed: _pauseTimer,
          isEnabled: isTimerRunning,
          color: Colors.orange,
        ),
        const SizedBox(width: 20),
        _buildAnimatedButton(
          label: 'Stop',
          icon: Icons.stop,
          onPressed: _stopTimer,
          isEnabled: isTimerRunning,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildAnimatedButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isEnabled,
    required Color color,
  }) {
    return ScaleTransition(
      scale: _buttonScaleAnimation,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: label,
            onPressed: isEnabled ? onPressed : null,
            backgroundColor: isEnabled ? color : color.withOpacity(0.3),
            elevation: 4,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isEnabled ? color : color.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle_outline,
                  color: _phaseColorAnimation?.value ?? focusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                startTime != null
                    ? DateFormat('HH:mm a').format(startTime!)
                    : '--:--',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Container(
            height: 24,
            width: 1,
            color: Colors.grey.shade300,
          ),
          Row(
            children: [
              const Icon(Icons.stop_circle_outlined,
                  color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                endTime != null
                    ? DateFormat('HH:mm a').format(endTime!)
                    : '--:--',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityTasks(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text('Priority Tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              )),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: taskProvider.tasks.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  taskProvider.tasks[index],
                  style: const TextStyle(fontSize: 16),
                ),
                value: false,
                onChanged: (value) {},
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _phaseColorAnimation?.value ?? focusColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
