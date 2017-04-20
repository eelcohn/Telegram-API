# Telegram-API
A gateway between IRC chat channels and Telegram groups

This script requires `curl` and `jq`.

How do I setup this IRC-Telegram gateway?<br>
1. First get an eggdrop bot up and running<br>
2. On your Telegram client, send `/start` to @BotFather<br>
3. Send `/newbot` to @BotFather<br>
4. Enter the nickname of the bot you want to create<br>
5. Enter the username of the bot you want to create<br>
6. You'll see confirmation message like this:<br>
```
Done! Congratulations on your new bot. You will find it at telegram.me/<BOTBNAME>. You can now add a description, about section and profile picture for your bot, see /help for a list of commands. By the way, when you.ve finished creating your cool bot, ping out Bot Support if you want a better username for it. Just make sure the bot is fully operational before you do this.

Use this token to access the HTTP API:
123456789:AABCD-EfGhIj_KlMn_OpQrStUvWxYz12345

For a description of the Bot API, see this page: https://core.telegram.org/bots/api
```

<br>

7. Copy the `123456789` part into the Telegram-API-config.tcl script at `tg_bot_id`<br>
8. Copy the `AABCD-EfGhIj_KlMn_OpQrStUvWxYz12345` part into the Telegram-API-config.tcl script at `tg_bot_token`<br>
9. Add the bot to your Telegram group (don't forget the @ sign before the nickname of your bot)<br>
10. Send a message to the group<br>
11. Open the `https://api.telegram.org/bot123456789:AABCD-EfGhIj_KlMn_OpQrStUvWxYz12345/getUpdates` link in your webbrowser, where 123456789 is your bot id, and the AABCD-...12345 is your bottoken<br>
12. Look up the chat_id of your chat group, and add it to the tg_channels array in Telegram-API-config.tcl script, along with the name of your IRC chat group<br>
13. Add the Telegram-API.tcl script to your Eggdrop: `source /path/to/your/scripts/Telegram-API.tcl`<br>
14. You're done! Enjoy!<br>
