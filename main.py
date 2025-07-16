import os
import time
import requests
import configparser
from flask import Flask, jsonify, request
from PIL import ImageGrab, Image
import pytesseract
import cv2
import numpy as np
import tensorflow as tf
import pyautogui

app = Flask(__name__)

# Load config
config = configparser.ConfigParser()
config.read('config.ini')

# Load the trained model
model = tf.keras.models.load_model('captcha_model.h5')

def get_config_coords(key):
    return tuple(map(int, config['Coordinates'][key].split(', ')))

def get_config_setting(key):
    return config['Settings'][key]

def send_webhook(message, filename=None):
    url = get_config_setting('webhook_url')
    if url:
        data = {"content": message}
        if filename:
            with open(filename, 'rb') as f:
                files = {'file': (filename, f)}
                requests.post(url, data=data, files=files)
        else:
            requests.post(url, json=data)

@app.route('/get_day', methods=['GET'])
def get_day():
    try:
        day_tl = get_config_coords('day_top_left')
        day_br = get_config_coords('day_bottom_right')
        img = ImageGrab.grab(bbox=(*day_tl, *day_br))
        text = pytesseract.image_to_string(img, config='--psm 6').strip()
        return jsonify({'day': text})
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/get_lives', methods=['GET'])
def get_lives():
    try:
        lives_tl = get_config_coords('lives_top_left')
        lives_br = get_config_coords('lives_bottom_right')
        img = ImageGrab.grab(bbox=(*lives_tl, *lives_br))
        text = pytesseract.image_to_string(img, config='--psm 6').strip()
        return jsonify({'lives': text})
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/gacha_action', methods=['POST'])
def gacha_action():
    try:
        # Click on the specified color
        pixel = pyautogui.locateCenterOnScreen('pixel.png', confidence=0.8) # replace with a screenshot of the pixel
        if pixel:
            pyautogui.click(pixel)
        else:
            return jsonify({'error': 'Pixel not found'})

        time.sleep(5)

        # Call solve_captcha
        response = requests.post('http://127.0.0.1:5000/solve_captcha')
        return response.json()
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/solve_captcha', methods=['POST'])
def solve_captcha():
    try:
        captcha_tl = get_config_coords('captcha_entity_top_left')
        captcha_br = get_config_coords('captcha_entity_bottom_right')

        # Grab captcha image
        img = ImageGrab.grab(bbox=(*captcha_tl, *captcha_br))
        img = img.resize((150, 150))
        img_array = np.array(img) / 255.0
        img_array = np.expand_dims(img_array, axis=0)

        # Predict
        prediction = model.predict(img_array)
        class_index = np.argmax(prediction)

        # Get class names from folder structure
        class_names = sorted(os.listdir('images/captcha'))
        captcha_name = class_names[class_index]

        # Get option text and click location
        options = []
        for i in range(1, 6):
            option_tl = get_config_coords(f'option{i}_top_left')
            option_br = get_config_coords(f'option{i}_bottom_right')
            option_img = ImageGrab.grab(bbox=(*option_tl, *option_br))
            text = pytesseract.image_to_string(option_img, config='--psm 6').strip()
            options.append(text)

        # Match and click
        for i, option_text in enumerate(options):
            if captcha_name.lower() in option_text.lower():
                click_coords = get_config_coords(f'option{i+1}_click')
                pyautogui.click(*click_coords)
                time.sleep(2)
                pyautogui.click(1156, 856)
                time.sleep(1)
                pyautogui.click(1156, 856)

                # Scan hotbar
                hotbar_tl = (841, 950)
                hotbar_br = (1714, 1028)
                hotbar_img = ImageGrab.grab(bbox=(*hotbar_tl, *hotbar_br))
                hotbar_text = pytesseract.image_to_string(hotbar_img).lower()

                scrolls = {
                    "Scroll of Snarvindur": "snarvindur",
                    "Scroll of Hoppa": "hoppa",
                    "Scroll of Percutiens": "percutiens"
                }

                for scroll_name, scroll_key in scrolls.items():
                    if scroll_key in hotbar_text:
                        # Check if scroll is enabled in config
                        enabled_scrolls = get_config_setting('enabled_scrolls').split(',')
                        if scroll_key in enabled_scrolls:
                            send_webhook(f"@everyone Found {scroll_name}!", "hotbar.png")
                            # os.system("taskkill /im RobloxPlayerBeta.exe /f")
                            return jsonify({'status': 'success', 'found_scroll': scroll_name})

                return jsonify({'status': 'success', 'clicked': option_text})

        return jsonify({'status': 'error', 'message': 'Could not find a matching option.'})
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/', methods=['GET'])
def index():
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(debug=True)
