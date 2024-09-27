import ast
import json
import re

import requests
import random
import time
import datetime
import urllib3
from PIL import Image
import base64
from io import BytesIO
import ddddocr
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
from loguru import logger

URLKeepAlive = "https://www.aeropres.in/chromeapi/dawn/v1/userreward/keepalive"
URLGetPoint = "https://www.aeropres.in/api/atom/v1/userreferral/getpoint"
URLLogin = "https://www.aeropres.in//chromeapi/dawn/v1/user/login/v2"
URLPuzzleID = "https://www.aeropres.in/chromeapi/dawn/v1/puzzle/get-puzzle"

# Membuat sesi permintaan
session = requests.Session()

# Menetapkan header permintaan umum
header = {
    "Content-Type": "application/json",
    "Origin": "chrome-extension://fpdkjdnhkakefebpekbdhillbhonfjjp",
    "Accept": "*/*",
    "Accept-Language": "en-US,en;q=0.9",
    "Priority": "u=1, i",
    "Sec-Fetch-Dest": "empty",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Site": "cross-site",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36"
}


def AmbilPuzzleID():
    r = session.get(URLPuzzleID, headers=header, verify=False).json()
    puzzid = r['puzzle_id']
    return puzzid

# Memeriksa validitas ekspresi CAPTCHA
def ApakahEkspresiValid(expression):
    # Memeriksa apakah ekspresi terdiri dari 6 karakter alfanumerik
    pola = r'^[A-Za-z0-9]{6}$'
    if re.match(pola, expression):
        return True
    return False

# Pengenalan CAPTCHA
def PengenalanCaptcha(base64_image):
    # Meng-decode string Base64 menjadi data biner
    data_gambar = base64.b64decode(base64_image)
    # Menggunakan BytesIO untuk mengubah data biner menjadi objek file yang dapat dibaca
    gambar = Image.open(BytesIO(data_gambar))
    
    # Mengubah gambar menjadi mode RGB (jika belum)
    gambar = gambar.convert('RGB')
    # Membuat gambar baru (latar belakang putih)
    gambar_baru = Image.new('RGB', gambar.size, 'white')
    # Mendapatkan lebar dan tinggi gambar
    lebar, tinggi = gambar.size
    # Mengulangi semua piksel
    for x in range(lebar):
        for y in range(tinggi):
            piksel = gambar.getpixel((x, y))
            # Jika piksel berwarna hitam, pertahankan; jika tidak, ganti dengan putih
            if piksel == (48, 48, 48):  # Piksel hitam
                gambar_baru.putpixel((x, y), piksel)  # Mempertahankan warna asli hitam
            else:
                gambar_baru.putpixel((x, y), (255, 255, 255))  # Mengganti dengan putih

    # Membuat objek OCR
    ocr = ddddocr.DdddOcr(show_ad=False)
    ocr.set_ranges(0)
    hasil = ocr.classification(gambar_baru)
    logger.debug(f'[1] Hasil pengenalan CAPTCHA: {hasil}, apakah valid: {ApakahEkspresiValid(hasil)}')
    if ApakahEkspresiValid(hasil):
        return hasil


def login(USERNAME, PASSWORD):
    puzzid = AmbilPuzzleID()
    waktu_sekarang = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='milliseconds').replace("+00:00", "Z")
    data = {
        "username": USERNAME,
        "password": PASSWORD,
        "logindata": {
            "_v": "1.0.7",
            "datetime": waktu_sekarang
        },
        "puzzle_id": puzzid,
        "ans": "0"
    }
    # Bagian pengenalan CAPTCHA
    refresh_image = session.get(f'https://www.aeropres.in/chromeapi/dawn/v1/puzzle/get-puzzle-image?puzzle_id={puzzid}', headers=header, verify=False).json()
    kode = PengenalanCaptcha(refresh_image['imgBase64'])
    if kode:
        logger.success(f'[√] Berhasil mendapatkan hasil CAPTCHA: {kode}')
        data['ans'] = str(kode)
        data_login = json.dumps(data)
        logger.info(f'[2] Data login: {data_login}')
        try:
            r = session.post(URLLogin, data_login, headers=header, verify=False).json()
            logger.debug(r)
            token = r['data']['token']
            logger.success(f'[√] Berhasil mendapatkan AuthToken: {token}')
            return token
        except Exception as e:
            logger.error(f'[x] Kesalahan CAPTCHA, mencoba mendapatkan ulang...')

def KeepAlive(USERNAME, TOKEN):
    data = {"username": USERNAME, "extensionid": "fpdkjdnhkakefebpekbdhillbhonfjjp", "numberoftabs": 0, "_v": "1.0.7"}
    json_data = json.dumps(data)
    header['authorization'] = "Bearer " + str(TOKEN)
    r = session.post(URLKeepAlive, data=json_data, headers=header, verify=False).json()
    logger.info(f'[3] Menjaga koneksi... {r}')


def GetPoint(TOKEN):
    header['authorization'] = "Bearer " + str(TOKEN)
    r = session.get(URLGetPoint, headers=header, verify=False).json()
    logger.success(f'[√] Berhasil mendapatkan poin: {r}')


def main(USERNAME, PASSWORD):
    TOKEN = ''
    if TOKEN == '':
        while True:
            TOKEN = login(USERNAME, PASSWORD)
            if TOKEN:
                break
    # Inisialisasi penghitung
    count = 0
    max_count = 200  # Setiap 200 kali, token akan diambil ulang
    while True:
        try:
            # Melakukan operasi menjaga koneksi dan mendapatkan poin
            KeepAlive(USERNAME, TOKEN)
            GetPoint(TOKEN)
            # Memperbarui penghitung
            count += 1
            # Setelah mencapai max_count, ambil token ulang
            if count >= max_count:
                logger.debug(f'[√] Mengambil token ulang...')
                while True:
                    TOKEN = login(USERNAME, PASSWORD)
                    if TOKEN:
                        break
                count = 0  # Mengatur ulang penghitung
        except Exception as e:
            logger.error(e)


if __name__ == '__main__':
    with open('password.txt', 'r') as f:
        username, password = f.readline().strip().split(':')
    main(username, password)
