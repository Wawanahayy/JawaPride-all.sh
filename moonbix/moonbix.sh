import os
import requests
import time
import crayons
import json
import threading

def display_colored_text():
    print("Menampilkan teks berwarna")
    print("=========================================================")
    print("=========================================================")
    print("======================  monbix  =========================")
    print("============== create all by JAWA-PRIDE  ================")
    print("=========== https://t.me/AirdropJP_JawaPride ============")
    print("=========================================================")
    print("=========================================================")

def print_banner():
    display_colored_text()

def log(message, level="INFO"):
    levels = {
        "INFO": crayons.cyan,
        "ERROR": crayons.red,
        "SUCCESS": crayons.green,
        "WARNING": crayons.yellow
    }
    print(f"{levels.get(level, crayons.cyan)(level)} | {message}")


if __name__ == '__main__':
    os.system('cls' if os.name == 'nt' else 'clear')
    print_banner()


class MoonBix:
    def __init__(self, token, proxy=None):
        self.session = requests.session()
        self.session.headers.update({
            'authority': 'www.binance.info',
            'accept': '*/*',
            'accept-language': 'en-EG,en;q=0.9,ar-EG;q=0.8,ar;q=0.7,en-GB;q=0.6,en-US;q=0.5',
            'clienttype': 'web',
            'content-type': 'application/json',
            'lang': 'en',
            'origin': 'https://www.binance.info',
            'referer': 'https://www.binance.info/en/game/tg/moon-bix',
            'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
        })
        
        if proxy:
            self.session.proxies.update({'http': proxy, 'https': proxy})

        self.token = token
        self.game_response = None

    def login(self):
        try:
            response = self.session.post(
                'https://www.binance.info/bapi/growth/v1/friendly/growth-paas/third-party/access/accessToken',
                json={'queryString': self.token, 'socialType': 'telegram'},
            )
            if response.status_code == 200:
                self.session.headers['x-growth-token'] = response.json()['data']['accessToken']
                log("Login berhasil!!", level="SUCCESS")
                return True
            else:
                log("Gagal login", level="ERROR")
                return False
        except Exception as e:
            log(f"Error during login: {e}", level="ERROR")

    def user_info(self):
        try:
            response = self.session.post(
                'https://www.binance.info/bapi/growth/v1/friendly/growth-paas/mini-app-activity/third-party/user/user-info',
                json={'resourceId': 2056},
            )
            return response.json()
        
        except Exception as e:
            log(f"Error during get info: {e}", level="ERROR")

    def game_data(self):
        try:
            while True:
                responses = requests.post('https://app.winsnip.xyz/play', json=self.game_response).text
                try:
                    response = json.loads(responses)
                except json.JSONDecodeError:
                    continue
                if response['message'] == 'success' and response['game']['log'] >= 100:
                    self.game = response['game']
                    return True
        except Exception as e:
            log(f"Error getting game data: {e}", level="ERROR")

    def complete_game(self):
        try:
            response = self.session.post(
                'https://www.binance.info/bapi/growth/v1/friendly/growth-paas/mini-app-activity/third-party/game/complete',
                json={'resourceId': 2056, 'payload': self.game['payload'], 'log': self.game['log']},
            )
            if response.json()['success']:
                log(f"Game selesai! Mendapatkan + {self.game['log']}", level="SUCCESS")
            return response.json()['success']
        except Exception as e:
            log(f"Error during complete game: {e}", level="ERROR")

    def start_game(self):
        try:
            while True:
                response = self.session.post(
                    'https://www.binance.info/bapi/growth/v1/friendly/growth-paas/mini-app-activity/third-party/game/start',
                    json={'resourceId': 2056},
                )
                self.game_response = response.json()
                if self.game_response['code'] == '000000':
                    log("Game berhasil dimulai!!", level="INFO")
                    return True
                elif self.game_response['code'] == '116002':
                    log('Percobaan tidak cukup! Beralih ke akun berikutnya.', level="WARNING")
                    return False
                log("ERROR! Tidak dapat memulai game.", level="ERROR")
                return False
        except Exception as e:
            log(f"Error during start game: {e}", level="ERROR")

    def start(self):
        if not self.login():
            log("Login gagal.", level="ERROR")
            return
        if not self.user_info():
            log("Gagal mengambil data pengguna.", level="ERROR")
            return
    
       
        while True:
            if self.start_game():
                if not self.game_data():
                    log("Gagal membuat data game!", level="ERROR")
                    return
                sleep(45)  
                if not self.complete_game():
                    log("Gagal menyelesaikan game", level="ERROR")
                log("Game selesai, menunggu 3 jam untuk memulai ulang.", level="INFO")
                sleep(10800)  
            else:
                log("Gagal memulai game, menunggu 1 menit untuk mencoba lagi.", level="WARNING")
                sleep(60)  

def sleep(seconds):
    while seconds > 0:
        time_str = time.strftime('%H:%M:%S', time.gmtime(seconds))
        time.sleep(1)
        seconds -= 1
        print(f'\rMenunggu {time_str}', end='', flush=True)
    print()

def run_account(index, token, proxy=None):
    log(f"Memulai Akun {index} dengan Token", level="INFO")
    x = MoonBix(token, proxy)
    x.start()
    log(f"Akun {index} selesai |", level="SUCCESS")
    sleep(15)

if __name__ == '__main__':
    os.system('cls' if os.name == 'nt' else 'clear')
    print_banner()
    
    proxies = [line.strip() for line in open('proxy.txt') if line.strip()]
    tokens = [line.strip() for line in open('data.txt')]

    threads = []
    
    log("Memulai", level="INFO")

    for index, token in enumerate(tokens, start=1):
        proxy = proxies[(index - 1) % len(proxies)] if proxies else None
        t = threading.Thread(target=run_account, args=(index, token, proxy))
        threads.append(t)
        t.start()  

    for thread in threads:
        thread.join()  
