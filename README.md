# MICROPROCESSORS-CSE341-Project
# 🐍 Snake Game in Assembly

This is a classic **Snake Game** written in **x86 Assembly (8086)**, designed to run in **DOS** environments or emulators like **DOSBox**, **EMU8086**. It's a fun project demonstrating low-level game logic, user input handling, and real-time rendering using text-mode graphics.

🧠 Features
Real-time input without blocking the game loop

Dynamic speed increase based on score

Collision detection (walls and self)

Food spawning and snake growth

Score tracking

## 📜 Welcome Screen

======= SNAKE GAME =======
Instructions:

Use W, A, S, D or Arrow Keys to move the snake

Eat food to grow longer and earn points

Avoid hitting walls or yourself

Press ESC at any time to exit the game

Game speed increases as you score points

Press any key to start...

Assembly Snake Game v1.0
By Ullahel Mahi

---

## 🎮 Controls

| Key          | Action                |
|--------------|------------------------|
| W / ↑        | Move Up               |
| A / ←        | Move Left             |
| S / ↓        | Move Down             |
| D / →        | Move Right            |
| ESC          | Exit the game         |

---

## 🛠 How to Run

You can run this game using an x86 emulator like **DOSBox**.

### Steps (using DOSBox):
1. Download and install [DOSBox](https://www.dosbox.com/).
2. Mount your project directory:
   ```dos
   MOUNT C C:\path\to\snake-game
   C:

Compile using TASM/MASM and link:
tasm snake.asm
tlink snake.obj

Run the game:
snake.exe

👨‍💻 Author
Ullahel Mahi
GitHub: github.com/ullahelmahi
