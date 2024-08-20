import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:overlay_support/overlay_support.dart';
import 'quiz_provider.dart';
import 'api_service.dart';

void main() {
  runApp(
    OverlaySupport(
      child: ChangeNotifierProvider(
        create: (_) => QuizProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Quiz Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const QuizPage(),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleAnswer(String answer) async {
    if (_isLoading) return; // Prevent multiple button clicks

    setState(() {
      _isLoading = true;
    });

    try {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      await quizProvider.checkAnswer(answer);
      quizProvider.selectedAnswer = answer;

      print(quizProvider.isCorrect);
      if (quizProvider.isCorrect) {
        _confettiController.play();
        _audioPlayer.play(AssetSource('correct_answer.mp3'));
      } else {
        _audioPlayer.play(AssetSource('wrong_answer.mp3'));
      }

      // Show feedback dialog
      _showFeedbackDialog();
    } catch (e) {
      showErrorSnackbar('Failed to check answer. Please try again later.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showFeedbackDialog() {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: SvgPicture.asset(
            quizProvider.isCorrect ? 'assets/win.svg' : 'assets/wrong.svg',
            height: MediaQuery.of(context).size.height * 0.25,
            width: MediaQuery.of(context).size.width * 0.25,
            fit: BoxFit.contain,
          ),
          title: Text(
            quizProvider.isCorrect ? 'Congratulations!' : 'Wrong Answer!',
            style: TextStyle(
                color: quizProvider.isCorrect ? Colors.lightBlue : Colors.red,
                fontSize: 32),
          ),
        );
      },
    );

    // Automatically close the dialog after 3 seconds if it's still open
    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      quizProvider.reset();
    });
  }

  void showLoadingOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: Container(
                color: Colors.black
                    .withOpacity(0.5), // Semi-transparent background
                alignment: Alignment.center,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.height * 0.2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(
                        color: Colors.indigo,
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void hideLoadingOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Row(
            children: [
              // Yes button
              Expanded(
                child: InkWell(
                  onTap: () => _handleAnswer('A'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    color: quizProvider.hasAnswered &&
                            quizProvider.selectedAnswer == 'A'
                        ? quizProvider.isCorrect
                            ? Colors.lightGreen
                            : Colors.redAccent
                        : Colors.white,
                    child: Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          fontSize: 150,
                          color: quizProvider.hasAnswered &&
                                  quizProvider.selectedAnswer == 'A'
                              ? Colors.white
                              : Colors.lightBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // No button
              Expanded(
                child: InkWell(
                  onTap: () => _handleAnswer('B'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    color: quizProvider.hasAnswered &&
                            quizProvider.selectedAnswer == 'B'
                        ? quizProvider.isCorrect
                            ? Colors.lightGreen
                            : Colors.redAccent
                        : Colors.lightBlue,
                    child:  Center(
                      child: Text(
                        'B',
                        style: TextStyle(
                          fontSize: 150,
                          color: quizProvider.hasAnswered &&
                                  quizProvider.selectedAnswer == 'A'
                              ? Colors.white
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (quizProvider.isCorrect)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                maxBlastForce: 25,
                minBlastForce: 10,
                emissionFrequency: 0.50,
                numberOfParticles: 50,
              ),
            ),
        ],
      ),
    );
  }
}

// Update the QuizProvider class
class QuizProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool? _isCorrect;
  bool get isCorrect => _isCorrect ?? false;
  bool get hasAnswered => _isCorrect != null;

  String? _selectedAnswer;
  String? get selectedAnswer => _selectedAnswer;

  set selectedAnswer(String? value) {
    _selectedAnswer = value;
    notifyListeners();
  }

  Future<void> checkAnswer(String answer) async {
    _isCorrect = await _apiService.checkAnswer(answer);
    notifyListeners();
  }

  void reset() {
    _isCorrect = null;
    _selectedAnswer = null;
    notifyListeners();
  }
}
