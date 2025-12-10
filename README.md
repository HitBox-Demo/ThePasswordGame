# ThePasswordGame(Flutter Edition)
A clean, mobile-optimized implementation of the viral Password Game, built entirely with Flutter.This project challenges users to create a password that satisfies an increasingly absurd list of rules. It starts simple (uppercase letters, numbers) and quickly escalates to mathematical puzzles, roman numerals, and keeping a digital pet alive inside the text field.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

##  FeaturesProgressive Disclosure Engine: Rules are revealed one by one as the user satisfies the previous conditions.
### Tamagotchi Pet Mechanic:
Users must protect an "egg" 🥚 in their text.If the egg is deleted, the game ends immediately.Includes growth stages: Egg -> Hatch -> Chick -> Chicken.
### Complex Validation Logic:
- Recursive Verification: Ensures rules don't "disappear" when pasting text or typing quickly.
- Math Targets: Digit summation, Prime number detection, and Roman Numeral values.
### Polished UI:
- Dynamic "Teal" theme with reactive status headers.
- Smooth animations (AnimatedList, SizeTransition) for new rules.
- Built-in Game Guide and Copy-to-Clipboard functionality.

## Tech Stack

* **Framework:** Flutter (Dart)
* **State Management:** `setState` (Clean, single-page architecture)
* **Logic:** Custom Regex patterns and recursive loop validation.
* **Design:** Material 3 with a custom color scheme (`#357386`).

## How to Run

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/yourusername/password-game-flutter.git](https://github.com/yourusername/password-game-flutter.git)
    cd password-game-flutter
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```
  
## Inspiration & Thanks

Huge respect to **Neal Agarwal**, the original creator of *The Password Game*. This project is a tribute to his creativity.
* **Original Website:** [neal.fun](https://neal.fun/)
* **Twitter/X:** [@nealagarwal](https://x.com/nealagarwal)

### 👨‍💻 Developers
* **HitBox-Demo** - [GitHub Profile](https://github.com/HitBox-Demo)
* 


## Contributing
Feel free to fork this project and add new, crazier rules! Open a PR if you have a rule idea (e.g., "Password must contain the current phase of the moon").
1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingRule`)
3.  Commit your Changes (`git commit -m 'Add some AmazingRule'`)
4.  Push to the Branch (`git push origin feature/AmazingRule`)
5.  Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.
