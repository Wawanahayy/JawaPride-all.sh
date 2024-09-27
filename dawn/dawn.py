import requests
import json
import datetime
import base64
from PIL import Image
from io import BytesIO
import re
import ddddocr
from loguru import logger

# URL Pengaturan
KeepAliveURL = "https://www.aeropres.in/chromeapi/dawn/v1/userreward/keepalive"
GetPointURL = "https://www.aeropres.in/api/atom/v1/userreferral/getpoint"
LoginURL = "https://www.aeropres.in//chromeapi/dawn/v1/user/login/v2"
PuzzleID = "https://www.aeropres.in/chromeapi/dawn/v1/puzzle/get-puzzle"
FastCaptchaURL = "https://thedataextractors.com/fast-captcha/api/solve/recaptcha"

# Membaca kunci API Fast Captcha dari file
def get_fast_captcha_api_key():
    with open('fast_captcha_api_key.txt', 'r') as file:
        return file.read().strip()

def GetPuzzleID():
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    try:
        r = requests.get(PuzzleID, headers=headers, verify=False)
        if r.status_code == 200:
            logger.debug(f"Respons Puzzle ID: {r.text}")
            return r.json().get('puzzle_id')
        else:
            logger.error(f"Permintaan untuk mendapatkan Puzzle ID gagal, status kode: {r.status_code}")
            return None
    except requests.exceptions.RequestException as e:
        logger.error(f"Gagal mendapatkan Puzzle ID: {e}")
        return None
    except json.JSONDecodeError as e:
        logger.error(f"Gagal mengurai JSON Puzzle ID: {e}")
        logger.debug(f"Respons konten: {r.text}")
        return None

def IsValidExpression(expression):
    # Memeriksa apakah ekspresi terdiri dari 6 karakter huruf dan angka
    pattern = r'^[A-Za-z0-9]{6}$'
    return bool(re.match(pattern, expression))

def solve_captcha(api_key, website_url, website_key):
    headers = {
        'apiSecretKey': api_key,
        'Content-Type': 'application/x-www-form-urlencoded'
    }
    payload = f'webUrl={website_url}&websiteKey={website_key}'
    try:
        response = requests.post(FastCaptchaURL, headers=headers, data=payload, verify=False)
        response.raise_for_status()
        return response.json().get('solution')
    except requests.exceptions.RequestException as e:
        logger.error(f"Gagal menyelesaikan CAPTCHA: {e}")
        return None

def RemixCaptacha(base64_image):
    # Mendekode string Base64 menjadi data biner
    image_data = base64.b64decode(base64_image)
    image = Image.open(BytesIO(image_data))

    # Pengolahan gambar
    image = image.convert('RGB')
    new_image = Image.new('RGB', image.size, 'white')
    width, height = image.size
    for x in range(width):
        for y in range(height):
            pixel = image.getpixel((x, y))
            if pixel == (48, 48, 48):  # Piksel hitam
                new_image.putpixel((x, y), pixel)  # Pertahankan hitam asli
            else:
                new_image.putpixel((x, y), (255, 255, 255))  # Ganti dengan putih

    # Menggunakan OCR untuk mengenali CAPTCHA
    ocr = ddddocr.DdddOcr(show_ad=False)
    ocr.set_ranges(0)
    result = ocr.classification(new_image)
    logger.debug(f'[1] Hasil pengenalan CAPTCHA: {result}，Apakah ekspresi dapat dihitung? {IsValidExpression(result)}')
    if IsValidExpression(result):
        return result

def login(USERNAME, PASSWORD):
    puzzid = GetPuzzleID()
    if not puzzid:
        logger.error("Gagal mendapatkan Puzzle ID, login dihentikan")
        return False

    current_time = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='milliseconds').replace("+00:00", "Z")
    data = {
        "username": USERNAME,
        "password": PASSWORD,
        "logindata": {
            "_v": "1.0.8",
            "datetime": current_time
        },
        "puzzle_id": puzzid,
        "ans": "0"
    }
    try:
        refresh_image = requests.get(f'https://www.aeropres.in/chromeapi/dawn/v1/puzzle/refresh-image/{puzzid}', verify=False).json()
        base64_image = refresh_image['image']
        captcha_solution = RemixCaptacha(base64_image)
        logger.debug(f'[2] Hasil pengenalan: {captcha_solution}')
        data['ans'] = captcha_solution
        
        headers = {
            "Content-Type": "application/json"
        }
        response = requests.post(LoginURL, json=data, headers=headers, verify=False)
        logger.debug(f'[3] Respons permintaan login: {response.text}')
        if response.status_code == 200:
            result = response.json()
            if result['result'] == 'success':
                logger.info('Login berhasil')
                return True
            else:
                logger.error(f'Login gagal: {result.get("msg")}')
                return False
        else:
            logger.error(f'Permintaan gagal: {response.status_code}')
            return False
    except requests.exceptions.RequestException as e:
        logger.error(f"Permintaan login gagal: {e}")
        return False

def keep_alive():
    headers = {
        "Content-Type": "application/json"
    }
    try:
        response = requests.post(KeepAliveURL, headers=headers, verify=False)
        if response.status_code == 200:
            logger.info('Permintaan untuk menjaga sesi tetap aktif berhasil')
        else:
            logger.error(f'Permintaan untuk menjaga sesi tetap aktif gagal: {response.status_code}')
    except requests.exceptions.RequestException as e:
        logger.error(f"Permintaan untuk menjaga sesi tetap aktif gagal: {e}")

def get_point():
    headers = {
        "Content-Type": "application/json"
    }
    try:
        response = requests.get(GetPointURL, headers=headers, verify=False)
        if response.status_code == 200:
            result = response.json()
            logger.info(f'Pengambilan poin berhasil: {result}')
        else:
            logger.error(f'Pengambilan poin gagal: {response.status_code}')
    except requests.exceptions.RequestException as e:
        logger.error(f"Pengambilan poin gagal: {e}")

if __name__ == "__main__":
    USERNAME = "your_username"  # Gantilah dengan nama pengguna yang sebenarnya
    PASSWORD = "your_password"  # Gantilah dengan kata sandi yang sebenarnya

    if login(USERNAME, PASSWORD):
        keep_alive()
        get_point()
