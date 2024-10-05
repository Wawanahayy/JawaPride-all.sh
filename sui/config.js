// const argv = require('minimist')(process.argv.slice(2));

import minimist from 'minimist';
const argv = minimist(process.argv.slice(2));

let selectedChain = argv.chain || 'local';

const settings = {
    "local": {
        "phrase": "coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin",
        "packageId": "",
        "firstVPackageId": "",
        "packagePath": "./move",
    },
    "mainnet": {
        "phrase": "", // set it as cli parameter
        "packageId": "0x3c680197c3d3c3437f78a962f4be294596c5ebea6cea6764284319d5e832e8e4",
        "blockStoreId": "0x57035b093ecefd396cd4ccf1a4bf685622b58353566b2f29b271afded2cb4390",
        "treasuryId": "0xeefe819f6f1b219f9460bfc78bfbac6568e2aec78cf808d2005ff2367e1de528",

        "fomo": {
            "packageId": '0xa340e3db1332c21f20f5c08bef0fa459e733575f9a7e2f5faca64f72cd5a54f2',
            "configId": '0x684de611aafbc5fbb6aa4288b4050281219dd5efc5764de22ba0f30b2bb2dd15',
            "buses": [
                '0x1aa2497f14d27b2d7c2ebd9dd607cda0279dc4d54a57e3a8476a1236474b6567',
                '0x367fdbde371d96018a572e354a6af4f74b69f412c0817eabff52bb166da6df0c',
                '0x5e42608bc32e6ff4bd024ce3928832ebfa27efe557ba4763084222226e3413c0',
                '0x98b9610b1b61cb02cae304d8b8a4fbd4e5cb018d24adf59f728ff886b597e9dc',
                '0xaae095f1fd39d20418efd6ded79303fe8b53751907a17d2723594480655785f0',
                '0xc941f30b0714306d256a8efa56d9b1fb9e63ebd94de14d6a4b5d9c52ece98bc5',
                '0xcc18677841febd80ad34a4535c88ec402a968d24a824c00af29d1b5737e528d0',
                '0xea11f05cb06456755a0b1b52bbd1b4a9e186ec89495f6ba02094ed84a075248a',
            ],
        },
    }, 
    "testnet": {
        "phrase": "coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin",
        "packageId": "0x1d4a80381ecca0ea3ea458bf9f0d633323f7226070b85d2de45c091938cfc0fa",
        "blockStoreId": "0xe48cc5da84c7cc60f2c3f50dce9badede4489684bf634cccbdebcc65948f3182",
        "treasuryId": "0xd9b75c90f8ed1b018d04607ab23dc134195046b861001c927ecca370e6b4fb1b",
    },
};


settings[selectedChain].chain = selectedChain;
if (argv.phrase) {
    settings[selectedChain].phrase = argv.phrase;
}

settings[selectedChain].do = {meta: true};
if (argv.fomo) {
    settings[selectedChain].do.fomo = true;
    if (!argv.meta) {
        settings[selectedChain].do.meta = false;
    }
}

export default  settings[selectedChain];
