# Python AHK Automation Bot

This is a Python and AutoHotkey automation bot that can perform various tasks in a game.

## Requirements

- Python 3
- AutoHotkey
- Tesseract OCR

## Installation

1. Clone this repository.
2. Install the required Python libraries:
   ```
   pip install -r requirements.txt
   ```
3. Install Tesseract OCR from the official website: https://github.com/tesseract-ocr/tesseract
4. Open the `config.ini` file and set the `tesseract_path` variable to the path of your Tesseract executable. For example, on Windows, this might be `C:\Program Files\Tesseract-OCR\tesseract.exe`.
5. Place your training images for the captcha in the `images/captcha` directory, with each captcha type in its own folder.
6. Run the `train_model.py` script to train the captcha recognition model:
   ```
   python train_model.py
   ```
7. Run the `main.ahk` script to start the bot.

## Usage

- The bot can be started and stopped using the buttons in the GUI or the hotkeys defined in the settings.
- The settings can be configured in the settings menu, which can be accessed by clicking the gear icon in the main GUI.
- The bot will perform the following actions:
    - Click the "Menu" and "Play" buttons at a set interval.
    - Detect the current day and lives, and take actions when they change.
    - Perform a "gacha" action when the day changes.
    - Solve a captcha when it appears.
    - Detect the player's silver value and stop the script if it falls below a certain threshold.
- The bot can send webhook notifications for various events, which can be configured in the settings.
