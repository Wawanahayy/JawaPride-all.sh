import { SuiMaster } from 'suidouble';
import config from './config.js';
import Miner from './includes/Miner.js';
import FomoMiner from './includes/fomo/FomoMiner.js';
import axios from 'axios';  // For Telegram notifications

const TELEGRAM_BOT_TOKEN = 'TOKENBOTTELEGRAM';  // Replace with your bot token
const TELEGRAM_CHAT_ID = 'CHATIDTELEGRAM';  // Replace with your chat ID

// Function to send a Telegram message
const sendTelegramMessage = async (message) => {
    const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
    try {
        await axios.post(url, {
            chat_id: TELEGRAM_CHAT_ID,
            text: message,
        });
    } catch (error) {
        console.error("Failed to send Telegram message:", error);
    }
};

const run = async () => {
    const phrase = config.phrase;
    const chain = config.chain;

    if (!config.phrase || !config.chain) {
        throw new Error('phrase and chain parameters are required');
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

    console.log('suiMaster connected as ', suiMaster.address);

    const miners = {};

    // Meta mining with parallel mining support and Telegram notifications
    const doMineMeta = async (metaMinerInstance) => {
        let retryCount = 0;
        const maxRetries = 5;
        let baseDelay = 200;  // Starting delay
        const maxDelay = 5000;  // Max delay after exponential backoff

        while (true) {
            console.log("META | Attempting to mine META token...");

            try {
                const metaHashChanged = await metaMinerInstance.mine();
                if (metaHashChanged) {
                    console.log("META | Block hash changed detected for META, mining attempt successful.");
                    retryCount = 0;  // Reset retries on success
                    baseDelay = 200;  // Reset delay on success

                    // Fetch balance and notify
                    const balance = await suiMaster.getBalance();  // Assuming getBalance fetches current balance
                    await sendTelegramMessage(`META mined successfully! New balance: ${balance}`);
                } else {
                    console.log("META | Block hash unchanged for META, retrying...");
                    retryCount++;
                    if (retryCount >= maxRetries) {
                        console.log(`META | Maximum retries (${maxRetries}) reached. Increasing delay.`);
                        baseDelay = Math.min(baseDelay * 2, maxDelay);  // Exponential backoff with cap
                        retryCount = 0;
                    }
                }
            } catch (error) {
                console.error("META | Mining attempt failed:", error);
                baseDelay = Math.min(baseDelay * 2, maxDelay);  // Increase delay on failure
            }

            // Delay between mining attempts
            await new Promise((res) => setTimeout(res, baseDelay));
        }
    };

    // FOMO mining with parallel mining support and Telegram notifications
    const doMineFomo = async (fomoMinerInstance) => {
        let retryCount = 0;
        const maxRetries = 5;
        let baseDelay = 150;  // Starting delay
        const maxDelay = 5000;  // Max delay after exponential backoff

        while (true) {
            console.log("FOMO | Attempting to mine FOMO token...");

            try {
                const fomoHashChanged = await fomoMinerInstance.mine();
                if (fomoHashChanged) {
                    console.log("FOMO | Block hash changed detected for FOMO, mining attempt successful.");
                    retryCount = 0;  // Reset retries on success
                    baseDelay = 150;  // Reset delay on success

                    // Fetch balance and notify
                    const balance = await suiMaster.getBalance();  // Assuming getBalance fetches current balance
                    await sendTelegramMessage(`FOMO mined successfully! New balance: ${balance}`);
                } else {
                    console.log("FOMO | Block hash unchanged for FOMO, retrying...");
                    retryCount++;
                    if (retryCount >= maxRetries) {
                        console.log(`FOMO | Maximum retries (${maxRetries}) reached. Increasing delay.`);
                        baseDelay = Math.min(baseDelay * 2, maxDelay);  // Exponential backoff with cap
                        retryCount = 0;
                    }
                }
            } catch (error) {
                console.error("FOMO | Mining attempt failed:", error);
                baseDelay = Math.min(baseDelay * 2, maxDelay);  // Increase delay on failure
            }

            // Delay between mining attempts
            await new Promise((res) => setTimeout(res, baseDelay));
        }
    };

    // Start META Mining if config is set to doMeta
    if (config.do.meta) {
        const metaMiner = new Miner({
            suiMaster,
            packageId: config.packageId,
            blockStoreId: config.blockStoreId,
            treasuryId: config.treasuryId,
        });
        miners.meta = metaMiner;
        // Run META mining in parallel
        doMineMeta(miners.meta);
    }

    // Start FOMO Mining if config is set to doFomo
    if (config.do.fomo) {
        const fomoMiner = new FomoMiner({
            suiMaster,
            packageId: config.fomo.packageId,
            configId: config.fomo.configId,
            buses: config.fomo.buses,
        });
        miners.fomo = fomoMiner;
        // Run FOMO mining in parallel
        doMineFomo(miners.fomo);
    }

    console.log('Mining started...');
};

run().catch(console.error);
