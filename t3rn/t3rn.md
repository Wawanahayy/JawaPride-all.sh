
# t3rn-executor.sh

install
```bash
wget -q https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/main/t3rn/t3rn-executor.sh -O t3rn-executor.sh
```

run .sh
```bash
bash t3rn-executor.sh
```
Menjalankan Node

```bash
sudo systemctl start executor.service
```
Jika Anda menjalankan node secara manual (misalnya dengan script), gunakan perintah yang sesuai untuk memulai node tersebut, seperti:
```bash
/root/executor/executor/bin/executor
```
Menghentikan Node

```bash
sudo systemctl stop executor.service
```

restart
```bash
sudo systemctl restart executor.service
sudo journalctl -u executor.service -f
```

Menghapus Service

```bash
sudo systemctl stop executor.service
sudo systemctl disable executor.service
sudo rm -f /etc/systemd/system/executor.service
sudo systemctl daemon-reload
```
Melihat Log Service
```bash
sudo journalctl -u executor.service -f
```

