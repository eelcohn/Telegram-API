# Telegram-API
A gateway between IRC chat channels and Telegram groups

How do I setup this IRC-Telegram gateway?<br>
1. First get an eggdrop bot up and running<br>
2. On your Telegram client, send a message to @BotFather: `/start`<br>
3. Send `/newbot` to @BotFather
4. Enter the nickname of the bot you want to create
5. Enter the username of the bot you want to create
6. You'll see confirmation message like this:<br>
```
Done! Congratulations on your new bot. You will find it at telegram.me/<BOTBNAME>. You can now add a description, about section and profile picture for your bot, see /help for a list of commands. By the way, when you.ve finished creating your cool bot, ping out Bot Support if you want a better username for it. Just make sure the bot is fully operational before you do this.

Use this token to access the HTTP API:
123456789:AABCD-EfGhIj_KlMn_OpQrStUvWxYz12345

For a description of the Bot API, see this page: https://core.telegram.org/bots/api
```
7. Copy the `123456789` part into the Telegram-API.tcl script at tg_bot_id
8. Copy the `AABCD-EfGhIj_KlMn_OpQrStUvWxYz12345` part into the Telegram-API.tcl script at tg_bot_token
9. Done!
