import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const PasswordGameApp());
}

// --- 1. THEME CONSTANTS ---
// Your specific color: Color.fromARGB(255, 53, 115, 134)
const Color kPrimaryColor = Color(0xFF357386); 

// A very light cool-grey/blue that matches the primary teal perfectly
const Color kBackgroundColor = Color(0xFFF4F8F9); 

const Color kSurfaceColor = Colors.white;
const Color kErrorColor = Color(0xFFD32F2F);
const Color kSuccessColor = Color(0xFF2E7D32);

// --- 2. Enums for Pet Growth ---
enum PetStage { egg, chick, chicken, dead }

class PasswordGameApp extends StatelessWidget {
  const PasswordGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Password Game',
      theme: ThemeData(
        // Generates a nice color scheme based on your Teal
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
          surface: kSurfaceColor,
          error: kErrorColor,
          background: kBackgroundColor,
        ),
        scaffoldBackgroundColor: kBackgroundColor,
        useMaterial3: true,
        // Improving text theme for engagement
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF2C3E50)), // Dark blue-grey text
        ),
      ),
      home: const PasswordGamePage(),
      debugShowCheckedModeBanner: false,
    );
    
  }
}

// --- 3. Model: Rule ---
typedef RuleValidator = bool Function(String password, GameState state);

class Rule {
  int number; 
  final String description;
  final RuleValidator validator;
  bool isSatisfied;
  bool isVisible;

  Rule({
    this.number = 0,
    required this.description,
    required this.validator,
    this.isSatisfied = false,
    this.isVisible = false,
  });
}

// --- 4. GameState ---
class GameState {
  final int minLength;
  final int digitSumTarget;
  final int romanTarget;
  final int primeTarget;
  final String randomRequiredLetter;
  final String randomRequiredDay;
  final String randomRequiredPlanet;

  bool eggEverPresent = false;
  bool eggAlive = true;
  PetStage currentStage = PetStage.egg;

  final Set<String> months = const {
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
  };

  final Set<String> planets = const {
    'mercury', 'venus', 'earth', 'mars', 'jupiter', 'saturn', 'uranus', 'neptune'
  };

  final Set<String> elementSymbols = const {
    'H', 'He', 'Li', 'Be', 'B', 'C', 'N', 'O', 'F', 'Ne',
    'Na', 'Mg', 'Al', 'Si', 'P', 'S', 'Cl', 'Ar', 'K', 'Ca',
    'Fe', 'Cu', 'Zn', 'Ag', 'Au', 'Hg', 'Pb', 'U'
  };

  GameState._({
    required this.minLength,
    required this.digitSumTarget,
    required this.romanTarget,
    required this.primeTarget,
    required this.randomRequiredLetter,
    required this.randomRequiredDay,
    required this.randomRequiredPlanet,
  });

  factory GameState.generate() {
    final rng = Random();
    
    final minLen = 8 + rng.nextInt(5); 
    final digitSum = 15 + rng.nextInt(15); 
    final romanVal = [5, 10, 50, 100][rng.nextInt(4)];
    final primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29];
    
    final daysList = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final planetsList = ['Mercury', 'Venus', 'Mars', 'Jupiter', 'Saturn'];

    return GameState._(
      minLength: minLen,
      digitSumTarget: digitSum,
      romanTarget: romanVal,
      primeTarget: primes[rng.nextInt(primes.length)],
      randomRequiredLetter: String.fromCharCode(rng.nextInt(26) + 65),
      randomRequiredDay: daysList[rng.nextInt(daysList.length)],
      randomRequiredPlanet: planetsList[rng.nextInt(planetsList.length)],
    );
  }

  void updatePetState(String password) {
    final lower = password.toLowerCase();
    final hasEgg = lower.contains('egg');
    final hasHatch = lower.contains('hatch');
    final hasWorm = lower.contains('worm');

    if (hasEgg) {
      eggEverPresent = true;
    } else {
      if (eggEverPresent && eggAlive) {
        eggAlive = false;
        currentStage = PetStage.dead;
      }
    }

    if (!eggAlive) {
      currentStage = PetStage.dead;
      return;
    }

    if (hasEgg && hasHatch && hasWorm) {
      currentStage = PetStage.chicken;
    } else if (hasEgg && hasHatch) {
      currentStage = PetStage.chick;
    } else if (hasEgg) {
      currentStage = PetStage.egg;
    }
  }
}

// --- 5. UI Page ---

class PasswordGamePage extends StatefulWidget {
  const PasswordGamePage({super.key});

  @override
  State<PasswordGamePage> createState() => _PasswordGamePageState();
}

class _PasswordGamePageState extends State<PasswordGamePage> with TickerProviderStateMixin {
  late GameState game;
  late List<Rule> rules;
  final TextEditingController controller = TextEditingController();
  
  GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  
  bool _showList = true;
  bool _hasShownGameOver = false; 
  
  final List<Rule> visibleRules = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    game = GameState.generate();
    rules = _generateRandomizedRules(game);
    
    visibleRules.clear();
    rules[0].isVisible = true;
    visibleRules.add(rules[0]);
    
    controller.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Guide 📜'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _guideSection('How to Play', 
                'Type in the text box to satisfy the rules. As you solve one rule, a new one will appear below it. Swap down to see new rules.'),
              _guideSection('🥚 The Pet', 
                'Rule #5 gives you an "egg". This is a REAL pet! \n\n• If you delete the word "egg" at any point, the pet dies and you LOSE.\n• Later rules will ask you to care for it.'),
              _guideSection('🧮 Math Rules', 
                '• Sum of Digits: All numbers in your text (e.g.,"2", "4" = 2+4 = 6) must add up exactly to the target.\n• Roman Numerals: I=1, V=5, X=10, L=50, C=100.\n• Prime number = a whole number greater than 1 that cannot be exactly divided by any whole number other than itself and 1 (e.g. 2, 3, 5, 7, 11).'),
              _guideSection('🗓️ Date & Time', 
                'If a rule asks for a month or day, spelling matters! (e.g., "January", "Monday").'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kPrimaryColor),
            onPressed: () => Navigator.pop(context), 
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _guideSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)),
        ],
      ),
    );
  }

  void _resetGame() async {
    controller.removeListener(_onPasswordChanged);

    // Hide list and clear text
    setState(() {
      _showList = false;
      _hasShownGameOver = false; // Reset Game Over flag
      controller.clear();
    });
    // Wait for rebuild
    await Future.delayed(const Duration(milliseconds: 50));

    // Generate NEW game data
    setState(() {
      game = GameState.generate();
      rules = _generateRandomizedRules(game);
      visibleRules.clear();
      rules[0].isVisible = true;
      visibleRules.add(rules[0]);
      _showList = true;
    });
    // RESUME LISTENING for the new game
    controller.addListener(_onPasswordChanged);
  }

  List<Rule> _generateRandomizedRules(GameState s) {
    final List<Rule> fixedStartRules = [];
    final List<Rule> poolOfRules = [];

    final upperReg = RegExp(r'[A-Z]');
    final digitReg = RegExp(r'\d');

    bool containsRomanWithValue(String text, int value) {
      final romanMap = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100};
      int romanToInt(String rn) {
        int sum = 0;
        for (int i = 0; i < rn.length; i++) {
          final cur = romanMap[rn[i]] ?? 0;
          final next = i + 1 < rn.length ? (romanMap[rn[i + 1]] ?? 0) : 0;
          if (cur < next) sum -= cur; else sum += cur;
        }
        return sum;
      }
      final matches = RegExp(r'[IVXLC]+').allMatches(text.toUpperCase());
      for (final m in matches) {
        if (romanToInt(m.group(0)!) == value) return true;
      }
      return false;
    }

    int sumDigits(String text) {
      int sum = 0;
      for (final ch in text.runes) {
        final s = String.fromCharCode(ch);
        if (RegExp(r'\d').hasMatch(s)) sum += int.parse(s);
      }
      return sum;
    }

    fixedStartRules.addAll([
      Rule(description: 'Password must be at least ${s.minLength} characters.', validator: (p, _) => p.length >= s.minLength),
      Rule(description: 'Include at least one uppercase letter.', validator: (p, _) => upperReg.hasMatch(p)),
      Rule(description: 'Include at least one number.', validator: (p, _) => digitReg.hasMatch(p)),
      Rule(description: 'Digits must sum to exactly ${s.digitSumTarget}.', validator: (p, _) => sumDigits(p) == s.digitSumTarget),
    ]);

    fixedStartRules.add(
      Rule(description: 'Include "egg". This is your pet. Do not lose it.', validator: (p, state) {
        state.updatePetState(p);
        return state.eggAlive && p.toLowerCase().contains('egg');
      }),
    );

    poolOfRules.addAll([
      Rule(description: 'Include a month of the year.', validator: (p, _) => s.months.any((m) => p.toLowerCase().contains(m))),
      Rule(description: 'Include the Roman numeral for ${s.romanTarget}.', validator: (p, _) {
           // We define the logic inline here to ensure it uses the non-strict regex
           final romanMap = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100};
           int romanToInt(String rn) {
             int sum = 0;
             for (int i = 0; i < rn.length; i++) {
               final cur = romanMap[rn[i]] ?? 0;
               final next = i + 1 < rn.length ? (romanMap[rn[i + 1]] ?? 0) : 0;
               if (cur < next) sum -= cur; else sum += cur;
             }
             return sum;
           }
           // Use simple Regex without \b (word boundary)
           final matches = RegExp(r'[IVXLC]+').allMatches(p.toUpperCase());
           for (final m in matches) {
             if (romanToInt(m.group(0)!) == s.romanTarget) return true;
           }
           return false;
        }
      ),
      Rule(description: 'Include a periodic table element symbol (e.g. He, Fe).', validator: (p, _) => s.elementSymbols.any((e) => p.contains(e))),
      Rule(description: 'Include the specific day: "${s.randomRequiredDay}".', validator: (p, _) => p.toLowerCase().contains(s.randomRequiredDay.toLowerCase())),
      Rule(description: 'Include the letter "${s.randomRequiredLetter}".', validator: (p, _) => p.contains(s.randomRequiredLetter)),
      Rule(description: 'Include a planet name (e.g. Mars).', validator: (p, _) => s.planets.any((planet) => p.toLowerCase().contains(planet))),
      Rule(description: 'Include the prime number ${s.primeTarget}.', validator: (p, _) => p.contains(s.primeTarget.toString())),
      Rule(description: 'Must be a secure URL ("https://" at the beginning).', validator: (p, _) => p.startsWith('https://')),
      Rule(description: 'Must contain an "@" sign.', validator: (p, _) => p.contains('@')),
      Rule(description: 'Cannot contain spaces.', validator: (p, _) => !p.contains(' ')),
    ]);

    poolOfRules.shuffle();
    final selectedPool = poolOfRules.take(6).toList(); 

    final growthRules = [
      Rule(
        description: 'Your egg is shaking! Include "hatch" to help it out.',
        validator: (p, state) {
          state.updatePetState(p); 
          return p.toLowerCase().contains('hatch');
        }
      ),
      Rule(
        description: 'Your chick is hungry! Include "worm" to feed it.',
        validator: (p, state) {
          state.updatePetState(p); 
          return p.toLowerCase().contains('worm');
        }
      ),
    ];

    final finalRules = [...fixedStartRules, ...selectedPool, ...growthRules];

    for (int i = 0; i < finalRules.length; i++) {
      finalRules[i].number = i + 1;
    }

    return finalRules;
  }

  void _onPasswordChanged() {
    final password = controller.text;
    
    // 1. Update Pet State immediately
    game.updatePetState(password);

    // 2. Check Game Over
    if (game.currentStage == PetStage.dead && !_hasShownGameOver) {
      _hasShownGameOver = true; 
      _showGameOverDialog();
    }

    // 3. Recursive Rule Validation Loop
    // We loop to ensure that if satisfying Rule A immediately satisfies Rule B,
    // Rule B appears and gets checked instantly (handling pastes or pre-typed words).
    bool newlyRevealed = false;

    while (true) {
      bool allVisibleSatisfied = true;

      // Check all currently visible rules
      for (final rule in rules) {
        if (!rule.isVisible) break;
        
        final satisfied = rule.validator(password, game);
        rule.isSatisfied = satisfied;

        if (!satisfied) allVisibleSatisfied = false;
      }

      // If all visible are satisfied, try to reveal the next one
      if (allVisibleSatisfied) {
        final nextIndex = rules.indexWhere((r) => !r.isVisible);
        if (nextIndex != -1) {
          // Reveal the next rule
          rules[nextIndex].isVisible = true;
          visibleRules.add(rules[nextIndex]);
          listKey.currentState?.insertItem(visibleRules.length - 1);
          newlyRevealed = true;
          
          // IMPORTANT: Continue the while loop to immediately check 
          // this newly revealed rule against the existing password.
          continue; 
        } else {
          _checkWinCondition();
        }
      }
      
      // If we didn't reveal anything new, or have an unsatisfied rule, stop.
      break; 
    }

    // 4. Handle Auto-Scroll
    if (newlyRevealed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
              _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent, 
                  duration: const Duration(milliseconds: 300), 
                  curve: Curves.easeOut
              );
          }
      });
    }

    setState(() {});
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('``Game Over``'),
        content: const Text(
          'Your pet has died! You removed the egg or let it starve.\n\n'
          'You cannot win with a dead pet. Please restart.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('I understand')
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kPrimaryColor),
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('Restart Now'),
          )
        ],
      ),
    );
  }

  void _checkWinCondition() {
    // Only show if all rules are satisfied
    if (rules.every((r) => r.isSatisfied)) {
      final finalPassword = controller.text;

      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Chicken Farmer!'),
            // Use Column with minAxisSize to wrap content tightly
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('You raised a healthy chicken and satisfied all rules!'),
                const SizedBox(height: 20),
                const Text(
                  'Your Final Password:', 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)
                ),
                const SizedBox(height: 8),
                
                // Password Display Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        // SelectableText allows manual highlighting too
                        child: SelectableText(
                          finalPassword,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            color: Colors.black87
                          ),
                        ),
                      ),
                      // Copy Button
                      IconButton(
                        icon: const Icon(Icons.copy, color: kPrimaryColor),
                        tooltip: "Copy to Clipboard",
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: finalPassword));
                          // Show a small popup confirming the copy
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password copied to clipboard!'),
                              duration: Duration(seconds: 2),
                              backgroundColor: kSuccessColor,
                            )
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kPrimaryColor),
                onPressed: () {
                  Navigator.pop(context);
                  _resetGame();
                }, 
                child: const Text('New Game')
              )
            ],
          ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- UPDATED ENGAGING HEADER ---
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
              decoration: const BoxDecoration(
                color: kPrimaryColor, // Bold Teal Background
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // White text for contrast against Teal
                      const Text(
                        'Password Game',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      // BUTTONS ROW
                      Row(
                        children: [
                          // --- GUIDE BUTTON ---
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.help_outline, color: Colors.white), 
                              onPressed: _showGuideDialog,
                              tooltip: "Game Guide",
                            ),
                          ),
                          
                          const SizedBox(width: 10), // Spacing between buttons

                          // --- RESTART BUTTON ---
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white), 
                              onPressed: _resetGame,
                              tooltip: "New Game",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Pet Status embedded in Header
                  _buildPetStatusBadge(),
                ],
              ),
            ),
            
            // --- Targets Section ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                   _targetChip('Sum: ${game.digitSumTarget}', Icons.functions),
                   _targetChip('Roman: ${game.romanTarget}', Icons.history_edu),
                   if(rules.any((r) => r.description.contains('prime'))) 
                      _targetChip('Prime: ${game.primeTarget}', Icons.looks_one),
                   if(rules.any((r) => r.description.contains(game.randomRequiredDay)))
                      _targetChip(game.randomRequiredDay, Icons.calendar_today),
                ],
              ),
            ),
            
            // --- Input Field ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'Type to satisfy rules...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy, color: kPrimaryColor), 
                      onPressed: () => Clipboard.setData(ClipboardData(text: controller.text))
                    ),
                  ),
                  onChanged: (_) => setState((){}),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // --- Rules List ---
            Expanded(
              child: _showList 
                ? AnimatedList(
                    key: listKey,
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    initialItemCount: visibleRules.length,
                    itemBuilder: (context, index, animation) {
                      return _buildRuleTile(visibleRules[index], animation);
                    },
                  )
                : const SizedBox(),
            ),

            // --- FOOTER (Placed Correctly HERE) ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              color: kBackgroundColor, 
              alignment: Alignment.center,
              child: Column(
                children: [
                  Divider(height: 1, color: Colors.grey.withOpacity(0.2)), 
                  const SizedBox(height: 10),
                  Text(
                    "© ${DateTime.now().year} CSF3233-SecurityCyber \n       Password Game Project",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "v1.0.0 • Built with Flutter and caffeine",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetStatusBadge() {
      String text;
      Color color;
      Color textColor;
      String icon;

      // Status badge logic
      switch (game.currentStage) {
        case PetStage.egg:
          text = "Keep the Egg safe!"; color = Colors.white; textColor = kPrimaryColor; icon = "🥚"; break;
        case PetStage.chick:
          text = "It hatched! Feed it!"; color = const Color(0xFFFFE082); textColor = Colors.black87; icon = "🐥"; break;
        case PetStage.chicken:
          text = "Healthy Chicken!"; color = kSuccessColor; textColor = Colors.white; icon = "🐔"; break;
        case PetStage.dead:
          text = "Pet Died"; color = kErrorColor; textColor = Colors.white; icon = "🍳"; break;
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
          ],
        ),
      );
  }

  Widget _targetChip(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: kPrimaryColor),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kPrimaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleTile(Rule rule, Animation<double> animation) {
    final isOk = rule.isSatisfied;
    // Using simple colors for rules to not distract from the header
    final bgColor = isOk ? const Color(0xFFE8F5E9) : Colors.white;
    final borderColor = isOk ? Colors.transparent : Colors.red.shade100;
    
    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
             if(!isOk) BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))
          ]
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(
               color: isOk ? kSuccessColor : Colors.grey.shade100,
               shape: BoxShape.circle,
             ),
             child: Text(
               '${rule.number}', 
               style: TextStyle(fontWeight: FontWeight.bold, color: isOk ? Colors.white : Colors.grey.shade700)
             ),
          ),
          title: Text(
            rule.description, 
            style: TextStyle(
              fontSize: 15,
              fontWeight: isOk ? FontWeight.normal : FontWeight.w500,
              decoration: isOk ? TextDecoration.lineThrough : null,
              color: isOk ? Colors.grey.shade500 : const Color(0xFF2C3E50), // Dark text for readability
            )
          ),
          trailing: isOk 
            ? const Icon(Icons.check_circle, color: kSuccessColor) 
            : Icon(Icons.error_outline, color: Colors.red.shade300),
        ),
      ),
    );
  }
}