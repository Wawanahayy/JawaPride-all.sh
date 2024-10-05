import { SuiMaster } from 'suidouble';
import config from './config.js';
import Miner from './includes/Miner.js';
import FomoMiner from './includes/fomo/FomoMiner.js';
import axios from 'axios';
import readline from 'readline';

const TELEGRAM_BOT_TOKEN = '7700684221:AAGnfTFzPAne433oWAFtHSlQ4ztcPsPMJDg';

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

const getTelegramChatId = () => {
    return new Promise((resolve) => {
        rl.question('Masukkan Telegram Chat ID Anda: ', (chatId) => {
            resolve(chatId);
        });
    });
};


const getWalletName = () => {
    return new Promise((resolve) => {
        rl.question('Masukkan nama wallet Anda: ', (walletName) => {
            resolve(walletName);
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


    const TELEGRAM_CHAT_ID = await getTelegramChatId();
    const WALLET_NAME = await getWalletName();

 
    rl.close();

    if (!phrase || !chain) {
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


    const doMineMeta = async (metaMinerInstance) => {
        let retryCount = 0;
        const maxRetries = 5;
        let baseDelay = 200;  
        const maxDelay = 5000;  

        while (true) {
            console.log("META | Mencoba menambang token META...");

            try {
                const metaHashChanged = await metaMinerInstance.mine();
                if (metaHashChanged) {
                    console.log("META | Perubahan hash blok terdeteksi untuk META, upaya penambangan berhasil.");
                    retryCount = 0;  
                    baseDelay = 200;  

                    // Ambil saldo dan beri tahu
                    const balance = await suiMaster.getBalance(); 
                    await sendTelegramMessage(`WALLET ${WALLET_NAME} $META BALANCE: ${balance}`, TELEGRAM_CHAT_ID);
                } else {
                    console.log("META | Hash blok tidak berubah untuk META, mencoba lagi...");
                    retryCount++;
                    if (retryCount >= maxRetries) {
                        console.log(`META | Jumlah maksimum percobaan (${maxRetries}) tercapai. Meningkatkan delay.`);
                        baseDelay = Math.min(baseDelay * 2, maxDelay);  
                        retryCount = 0;
                    }
                }
            } catch (error) {
                console.error("META | Upaya penambangan gagal:", error);
                baseDelay = Math.min(baseDelay * 2, maxDelay); 
            }


            await new Promise((res) => setTimeout(res, baseDelay));
        }
    };


    const doMineFomo = async (fomoMinerInstance) => {
        let retryCount = 0;
        const maxRetries = 5;
        let baseDelay = 150;  
        const maxDelay = 5000; 

        while (true) {
            console.log("FOMO | Mencoba menambang token FOMO...");

            try {
                const fomoHashChanged = await fomoMinerInstance.mine();
                if (fomoHashChanged) {
                    console.log("FOMO | Perubahan hash blok terdeteksi untuk FOMO, upaya penambangan berhasil.");
                    retryCount = 0;  
                    baseDelay = 150;  


                    const balance = await suiMaster.getBalance();  
                    await sendTelegramMessage(`WALLET ${WALLET_NAME} $FOMO BALANCE: ${balance}`, TELEGRAM_CHAT_ID);
                } else {
                    console.log("FOMO | Hash blok tidak berubah untuk FOMO, mencoba lagi...");
                    retryCount++;
                    if (retryCount >= maxRetries) {
                        console.log(`FOMO | Jumlah maksimum percobaan (${maxRetries}) tercapai. Meningkatkan delay.`);
                        baseDelay = Math.min(baseDelay * 2, maxDelay);  
                        retryCount = 0;
                    }
                }
            } catch (error) {
                console.error("FOMO | Upaya penambangan gagal:", error);
                baseDelay = Math.min(baseDelay * 2, maxDelay);  
            }

            // Delay antara upaya penambangan
            await new Promise((res) => setTimeout(res, baseDelay));
        }
    };

    if (config.do.meta) {
        console.log('Menyiapkan penambangan META...');
        const metaMiner = new Miner({
            suiMaster,
            packageId: config.packageId,
            blockStoreId: config.blockStoreId,
            treasuryId: config.treasuryId,
        });
        miners.meta = metaMiner;
        console.log('Memulai penambangan META...');
        // Jalankan penambangan META secara paralel
        doMineMeta(miners.meta);
    }

    if (config.do.fomo) {
        console.log('Menyiapkan penambangan FOMO...');
        const fomoMiner = new FomoMiner({
            suiMaster,
            packageId: config.fomo.packageId,
            configId: config.fomo.configId,
            buses: config.fomo.buses,
        });
        miners.fomo = fomoMiner;
        console.log('Memulai penambangan FOMO...');

        doMineFomo(miners.fomo);
    }

    console.log('Penambangan dimulai...');
};

run().catch(console.error);
