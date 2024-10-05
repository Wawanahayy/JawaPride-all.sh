import { SuiMaster } from 'suidouble';
import config from './config.js';
import Miner from './includes/Miner.js';
import FomoMiner from './includes/fomo/FomoMiner.js';
import axios from 'axios';
import readline from 'readline';  

const TELEGRAM_BOT_TOKEN = '7700684221:AAGnfTFzPAne433oWAFtHSlQ4ztcPsPMJDg'; 

// Konfigurasi readline untuk mengambil input dari pengguna
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

// Fungsi untuk mendapatkan input ID obrolan Telegram
const getTelegramChatId = () => {
    return new Promise((resolve) => {
        rl.question('Masukkan Telegram Chat ID Anda: ', (chatId) => {
            resolve(chatId);
            rl.close(); // Tutup interface readline setelah mendapatkan input
        });
    });
};

const sendTelegramMessage = async (message, chatId) => {
    const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
    try {
        await axios.post(url, {
            chat_id: chatId,
            text: message,
        });
    } catch (error) {
        console.error("Gagal mengirim pesan Telegram:", error);
    }
};

const run = async () => {
    const phrase = config.phrase;
    const chain = config.chain;

    // Ambil Telegram Chat ID dari pengguna
    const TELEGRAM_CHAT_ID = await getTelegramChatId();

    if (!config.phrase || !config.chain) {
        throw new Error('phrase dan chain parameter diperlukan');
    }

    const suiMasterParams = {
        client: chain,
        debug: !!config.debug,
    };
    if (phrase.indexOf('suiprivkey') === 0) {
        suiMasterParams.privateKey = phrase;
    } else {
        suiMasterParams.phrase = phrase;
    }
    const suiMaster = new SuiMaster(suiMasterParams);
    await suiMaster.initialize();

    console.log('suiMaster terhubung sebagai ', suiMaster.address);

    const miners = {};

    // Meta mining dengan dukungan mining paralel dan notifikasi Telegram
    const doMineMeta = async (metaMinerInstance) => {
        let retryCount = 0;
        const maxRetries = 5;
        let baseDelay = 200;  // Delay awal
        const maxDelay = 5000;  // Max delay setelah exponential backoff

        while (true) {
            console.log("META | Mencoba menambang token META...");

            try {
                const metaHashChanged = await metaMinerInstance.mine();
                if (metaHashChanged) {
                    console.log("META | Perubahan hash blok terdeteksi untuk META, upaya penambangan berhasil.");
                    retryCount = 0;  // Reset retries pada keberhasilan
                    baseDelay = 200;  // Reset delay pada keberhasilan

                    // Ambil saldo dan beri tahu
                    const balance = await suiMaster.getBalance();  // Asumsi getBalance mengambil saldo saat ini
                    await sendTelegramMessage(`WALLET 1 $META saldo: ${balance}`, TELEGRAM_CHAT_ID);
                } else {
                    console.log("META | Hash blok tidak berubah untuk META, mencoba lagi...");
                    retryCount++;
                    if (retryCount >= maxRetries) {
                        console.log(`META | Jumlah maksimum percobaan (${maxRetries}) tercapai. Meningkatkan delay.`);
                        baseDelay = Math.min(baseDelay * 2, maxDelay);  // Exponential backoff dengan batas
                        retryCount = 0;
                    }
                }
            } catch (error) {
                console.error("META | Upaya penambangan gagal:", error);
                baseDelay = Math.min(baseDelay * 2, maxDelay);  // Tingkatkan delay pada kegagalan
            }

            // Delay antara upaya penambangan
            await new Promise((res) => setTimeout(res, baseDelay));
        }
    };

    // FOMO mining dengan dukungan mining paralel dan notifikasi Telegram
    const doMineFomo = async (fomoMinerInstance) => {
        let retryCount = 0;
        const maxRetries = 5;
        let baseDelay = 150;  // Delay awal
        const maxDelay = 5000;  // Max delay setelah exponential backoff

        while (true) {
            console.log("FOMO | Mencoba menambang token FOMO...");

            try {
                const fomoHashChanged = await fomoMinerInstance.mine();
                if (fomoHashChanged) {
                    console.log("FOMO | Perubahan hash blok terdeteksi untuk FOMO, upaya penambangan berhasil.");
                    retryCount = 0;  // Reset retries pada keberhasilan
                    baseDelay = 150;  // Reset delay pada keberhasilan

                    // Ambil saldo dan beri tahu
                    const balance = await suiMaster.getBalance();  // Asumsi getBalance mengambil saldo saat ini
                    await sendTelegramMessage(`WALLET 1 $FOMO saldo: ${balance}`, TELEGRAM_CHAT_ID);
                } else {
                    console.log("FOMO | Hash blok tidak berubah untuk FOMO, mencoba lagi...");
                    retryCount++;
                    if (retryCount >= maxRetries) {
                        console.log(`FOMO | Jumlah maksimum percobaan (${maxRetries}) tercapai. Meningkatkan delay.`);
                        baseDelay = Math.min(baseDelay * 2, maxDelay);  // Exponential backoff dengan batas
                        retryCount = 0;
                    }
                }
            } catch (error) {
                console.error("FOMO | Upaya penambangan gagal:", error);
                baseDelay = Math.min(baseDelay * 2, maxDelay);  // Tingkatkan delay pada kegagalan
            }

            // Delay antara upaya penambangan
            await new Promise((res) => setTimeout(res, baseDelay));
        }
    };

    // Mulai Penambangan META jika config diset untuk doMeta
    if (config.do.meta) {
        const metaMiner = new Miner({
            suiMaster,
            packageId: config.packageId,
            blockStoreId: config.blockStoreId,
            treasuryId: config.treasuryId,
        });
        miners.meta = metaMiner;
        // Jalankan penambangan META secara paralel
        doMineMeta(miners.meta);
    }

    // Mulai Penambangan FOMO jika config diset untuk doFomo
    if (config.do.fomo) {
        const fomoMiner = new FomoMiner({
            suiMaster,
            packageId: config.fomo.packageId,
            configId: config.fomo.configId,
            buses: config.fomo.buses,
        });
        miners.fomo = fomoMiner;
        // Jalankan penambangan FOMO secara paralel
        doMineFomo(miners.fomo);
    }

    console.log('Penambangan dimulai...');
};

run().catch(console.error);
