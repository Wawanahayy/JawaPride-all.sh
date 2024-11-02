function deploy_node() {
    echo "Sedang memperbarui sistem..."
    sudo apt update -y && sudo apt upgrade -y

    BLOCKMESH_DIR="$HOME/blockmesh"
    LOG_FILE="$BLOCKMESH_DIR/blockmesh.log"

    if [ -d "$BLOCKMESH_DIR" ]; then
        echo "Direktori $BLOCKMESH_DIR sudah ada, sedang menghapusnya..."
        rm -rf "$BLOCKMESH_DIR"
    fi

    mkdir -p "$BLOCKMESH_DIR"
    echo "Direktori dibuat: $BLOCKMESH_DIR"

    echo "Mengunduh blockmesh-cli..."
    curl -L "https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.326/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz" -o "$BLOCKMESH_DIR/blockmesh-cli.tar.gz"

    # Periksa apakah unduhan berhasil
    if [ ! -f "$BLOCKMESH_DIR/blockmesh-cli.tar.gz" ]; then
        echo "Error: file blockmesh-cli tidak ditemukan, periksa URL."
        exit 1
    fi

    echo "Ekstraksi blockmesh-cli..."
    tar -xzf "$BLOCKMESH_DIR/blockmesh-cli.tar.gz" -C "$BLOCKMESH_DIR"
    
    # Periksa apakah file hasil ekstraksi ada
    if [ ! -f "$BLOCKMESH_DIR/blockmesh-cli" ]; then
        echo "Error: file blockmesh-cli tidak ditemukan setelah ekstraksi."
        exit 1
    fi

    rm "$BLOCKMESH_DIR/blockmesh-cli.tar.gz"
    echo "Unduhan dan ekstraksi blockmesh-cli selesai."

    BLOCKMESH_CLI_PATH="$BLOCKMESH_DIR/blockmesh-cli"
    echo "Path blockmesh-cli: $BLOCKMESH_CLI_PATH"

    read -p "Masukkan email BlockMesh Anda: " BLOCKMESH_EMAIL
    read -sp "Masukkan kata sandi BlockMesh Anda: " BLOCKMESH_PASSWORD
    echo

    export BLOCKMESH_EMAIL
    export BLOCKMESH_PASSWORD

    chmod +x "$BLOCKMESH_CLI_PATH"

    echo "Berpindah direktori dan menjalankan ./blockmesh-cli..."
    cd "$BLOCKMESH_DIR" || exit

    echo "Memulai blockmesh-cli..."
    ./blockmesh-cli --email "$BLOCKMESH_EMAIL" --password "$BLOCKMESH_PASSWORD" > "$LOG_FILE" 2>&1 &
    echo "Eksekusi skrip selesai."

    read -p "Tekan sembarang tombol untuk kembali ke menu utama / click any tombol or ENTER..."
}
