import requests
import json
import datetime
import base64
import re
from PIL import Image
from io import BytesIO
import ddddocr
from loguru import logger
import time

# URL Pengaturan
KeepAliveURL = "https://www.aeropres.in/chromeapi/dawn/v1/userreward/keepalive"
GetPointURL = "https://www.aeropres.in/api/atom/v1/userreferral/getpoint"
LoginURL = "https://www.aeropres.in//chromeapi/dawn/v1/user/login/v2"
PuzzleID = "https://www.aeropres.in/chromeapi/dawn/v1/puzzle/get-puzzle"

# 2Captcha API Key
API_KEY_2CAPTCHA = "YOUR_2CAPTCHA_API_KEY"  # Ganti dengan API key Anda

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
    pattern = r'^[A-Za-z0-9]{6}$'
    return bool(re.match(pattern, expression))

def solve_captcha(api_key, website_url, website_key):
    # Mengirim permintaan ke 2Captcha
    url = "http://2captcha.com/in.php"
    data = {
        "clientKey": api_key,
        "task": {
            "type": "HCaptchaTaskProxyless",
            "websiteURL": website_url,
            "websiteKey": website_key
        }
    }
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            result = response.json()
            if result['status'] == 1:
                task_id = result['request']
                return task_id
            else:
                logger.error(f"Gagal membuat tugas CAPTCHA: {result['request']}")
                return None
        else:
            logger.error(f"Permintaan gagal: {response.status_code}")
            return None
    except requests.exceptions.RequestException as e:
        logger.error(f"Gagal mengirim permintaan ke 2Captcha: {e}")
        return None

def get_captcha_solution(api_key, task_id):
    url = "http://2captcha.com/res.php"
    data = {
        "clientKey": api_key,
        "taskId": task_id,
        "action": "get"
    }
    
    while True:
        try:
            response = requests.post(url, data=data)
            if response.status_code == 200:
                result = response.json()
                if result['status'] == 1:
                    return result['request']  # Solusi CAPTCHA
                elif result['request'] == 'CAPTCHA_NOT_READY':
                    logger.debug("Menunggu solusi CAPTCHA...")
                    time.sleep(5)  # Tunggu sebelum mencoba lagi
                else:
                    logger.error(f"Gagal mendapatkan solusi: {result['request']}")
                    break
            else:
                logger.error(f"Permintaan gagal: {response.status_code}")
                break
        except requests.exceptions.RequestException as e:
            logger.error(f"Gagal mengirim permintaan: {e}")
            break

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

    # Mendapatkan gambar CAPTCHA
    try:
        refresh_image = requests.get(f'https://www.aeropres.in/chromeapi/dawn/v1/puzzle/refresh-image/{puzzid}', verify=False).json()
        base64_image = refresh_image['image']
        logger.debug(f'[2] Gambar CAPTCHA diambil.')

        # Memecahkan CAPTCHA menggunakan 2Captcha
        website_url = "https://www.aeropres.in"  # URL situs web yang memerlukan CAPTCHA
        website_key = "f7de0da3-3303-44e8-ab48-fa32ff8ccc7b"  # Kunci situs web (hCaptcha)
        
        task_id = solve_captcha(API_KEY_2CAPTCHA, website_url, website_key)
        if task_id:
            captcha_solution = get_captcha_solution(API_KEY_2CAPTCHA, task_id)
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
        else:
            logger.error("Gagal mendapatkan solusi CAPTCHA.")
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
