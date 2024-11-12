```
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
```

loading
```
loading_step() {
    echo "Mengunduh dan menjalankan skrip display..."
    curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash
    echo
}
```
jika tanpa warna
```
import requests
import os

def loading_step():
    print("Mengunduh dan menjalankan skrip display...")
    

    url = "https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Memastikan tidak ada error dalam pengunduhan
        script_content = response.text
        
        # Menyimpan skrip yang diunduh ke file sementara
        with open("display.sh", "w") as file:
            file.write(script_content)
        
   
        os.system("bash display.sh")
        
    except requests.exceptions.RequestException as e:
        print(f"Error saat mengunduh skrip: {e}")


loading_step()
```
