require("dotenv").config();
const request = require('request');
const fs = require('fs');

async function callAPI(keyName, params) {

    // API Flash
    if (keyName === 'APIFLASH') {
        const API_key = process.env.APIFLASH_KEY;

        const URL = params['URL'];
        const image_name = params['image_name'];

        request({
            url: "https://api.apiflash.com/v1/urltoimage",
            encoding: "binary",
            qs: {
                access_key: API_key,
                url: URL,
                fresh: 'true',
                full_page: 'true',
                quality: '100',
                crop: '420,0,1080,1080',
                time_zone: Intl.DateTimeFormat().resolvedOptions().timeZone
            }
        }, (error, response, body) => {
            if (error) {
                console.log(error);
            } else {
                fs.writeFile("metadata_files/" + image_name + ".png", body, "binary", error => {
                    console.log(error);
                });
            }
        });
    } else

    // Discord
    if (keyName === 'DISCORD') {
        const API_key = process.env.DISCORD_BOT_TOKEN;
        
        const recipient_discord_ID = params['recipient_discord_ID'];
        var channel_discord_ID = params['channel_discord_ID'];
        const message = params['message'];
        
        // Direct Messages
        if (recipient_discord_ID) {
            request({
              method: 'POST',
              url: `https://discord.com/api/v9/users/@me/channels`,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bot ${API_key}`
              },
              body: JSON.stringify({recipient_id: recipient_discord_ID})
            }, (error, response, body) => {
              if (error) {
                console.log(error);
              } else {
                console.log(JSON.parse(body));
                channel_discord_ID = JSON.parse(body).id;
                console.log('Generated DM Channel ID: ', channel_discord_ID);
                request({
                  method: 'POST',
                  url: `https://discord.com/api/v9/channels/${channel_discord_ID}/messages`,
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bot ${API_key}`
                  },
                  body: JSON.stringify({content: message})
                }, (error, response, body) => {
                  if (error) {
                    console.log(error);
                  } else {
                    console.log(body);
                  }
                });
              }
            });
        
        // Channel Messages
        } else if (channel_discord_ID) {
          request({
            method: 'POST',
            url: `https://discord.com/api/v9/channels/${channel_discord_ID}/messages`,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bot ${API_key}`
            },
            body: JSON.stringify({content: message})
          }, (error, response, body) => {
            if (error) {
              console.log(error);
            } else {
              console.log(body);
            }
          });
        }
    }
}

//callAPI('APIFLASH', 'https://gateway.pinata.cloud/ipfs/QmfCnfBaphqpuWuLBtnEeu5hFUJix8WrqTREP7dgTujYGg', 'clock');
callAPI('DISCORD', {'recipient_discord_ID': '', 'channel_discord_ID': '941953657585414186', 'message': 'sup2s'});


/*API Flash
fetch('https://hcti.io/v1/image/2c3fad1f-8534-4d7f-8786-f55fa4ee42c8/url=https://gateway.pinata.cloud/ipfs/QmRsTsqY4vV4pUn2Sm8WcR453gvfciNmzRikT8GtaAtWvp/')
                .then(response => {
                    console.log(response);
                    return response;
                })
                .then(response => {
                    console.log(response.url);
                });
*/

/*HTML/CSS to Image API
`use strict`;
const json = {
  url: "https://gateway.pinata.cloud/ipfs/QmQciZBr92K7DEoiw4CrDHtvFY3wqLCftKrftwh2MDNkwt/",
  css: "pre { font-family: 'Courier Prime'; }",
  google_fonts: "Courier Prime"
};

const username = "8e171ec6-bc04-4951-9dbf-33e7689184ab";
const password = "2c3fad1f-8534-4d7f-8786-f55fa4ee42c8";

const options = {
  method: 'POST',
  body: JSON.stringify(json),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Basic ' + btoa(username + ":" + password)
  }
}

fetch('https://hcti.io/v1/image', options)
  .then(res => {
    if (res.ok) {
      return res.json();
    } else {
      return Promise.reject(res.status);
    }
  })
  .then(data => {
    // Image URL is available here
    console.log(data.url)
  })
  .catch(err => console.error(err));
*/
