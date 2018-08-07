# Telegram-API

A gateway between [IRC](https://en.wikipedia.org/wiki/Internet_Relay_Chat) chat channels and [Telegram](https://telegram.org/) groups, supergroups and channels.

## Pre-requisites

This script requires `tcl`, `eggdrop`, `curl` and `jq`:
* [Tcl](https://www.tcl.tk/) - The language this script is programmed in
* [Eggdrop](https://www.eggheads.org/) - The IRC bot used for connecting to your favourite IRC channels
* [cURL](https://curl.haxx.se/) - Used for querying the Telegram servers
* [jq](https://stedolan.github.io/jq/) - Used for processing the JSON data

## Features

* Bi-directional chats between IRC and Telegram
* Support for Telegram groups, supergroups, channels and private messages
* 1-to-1, 1-to-many and many-to-many linking IRC channels to Telegram groups/supergroups/channels
* Seamless translation of Unicode emoji's to ASCII variants and vice-versa
* Support for Telegram Stickers
* Download Telegram attachments using DCC on your favourite IRC client (a PHP-script on your webserver is available as an alternative)
* Multi-language support (currently English, Dutch and German are available)
* Global and per-user settings for allowing/denying notifications for joins/leaves/kicks/bans etc.
* You can login/logout to your Eggdrop bot from your Telegram client
* Linking your Eggdrop user profile to your Telegram account
* Modular support for public and private Telegram bot commands

## Quick start guide

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
13. Add the Telegram-API.tcl script to your Eggdrop:
```tcl
source /path/to/your/scripts/Telegram-API.tcl
```
<br>
14. You're done! Enjoy!<br>

## Upgrading to the current branch

1. Rename the `Telegram-API` folder to `Telegram-API.bak` (ALWAYS create a backup!)
2. Install the new version with `git clone https://github.com/eelcohn/Telegram-API/`
3. Compare your backed-up custom `Telegram-API-config.tcl` file with the default `Telegram-API-config.tcl` file. Take note of any settings that have been added/changed/deleted, and edit your custom config file accordingly
4. Restore your `Telegram-API-config.tcl` file from your backup folder

## Config settings

User flags:
| Flag | Description |
|------|-------------|
|  c   | nick_change: If this flag is set, a nick changed message is sent to the Telegram group if the specified user changes it's nickname |
|  j   | join: If this flag is set, a join message is sent to the Telegram group if the specified user joins the IRC channel |
|  k   | kick: If this flag is set, a kick message is sent to the Telegram group if the specified user is kicked from the IRC channel |
|  l   | leave: If this flag is set, a leave message is sent to the Telegram group if the specified user leaves the IRC channel |
|  m   | mode_change: If this flag is set, a message is sent to the Telegram group if the IRC mode for the specified user is changed |
|  v   | voice: If this flag is set, messages by the specified user are sent to the Telegram group |

Channel flags:
| Flag | Description |
|------|-------------|
|  i   | invite: If this flag is set, a message with an invite link to the Telegram group will be sent to the IRC channel if an user joins the IRC channel |
|  m   | mode_change: If this flag is set, a message is sent to the Telegram group if the IRC mode of the IRC channel is changed |
|  p   | pinned: If this flag is set, pinned messages in the Telegram group will be sent to the IRC channel if an user joins the IRC channel |
|  s   | set_topic: If this flag is set, and the topic of the IRC channel is changed, the topic of the Telegram group is set to the new topic of the IRC channel |
|  t   | topic: If this flag is set, and the topic of the IRC channel is changed, a message will be sent to the Telegram group |
|  w   | welcome_pub: If this flag is set, a public message will be sent to the Telegram group if an user joins the Telegram group |
|  W   | welcome_prv: If this flag is set, a private message will be sent to the user if the user joins the Telegram group |

## File descriptions

| File | Description |
|------------------------------------------------------------------|---------|
| `Telegram-API-config.tcl` | All user configurable settings are set in this file. Rename to Telegram-API-config.tcl and edit according to your preferences before use. |
| `Telegram-API.tcl` | Main code. Include this file in your `eggdrop.conf` file. |
| `utftable.tcl` | Translation from UTF characters and emoticons to ASCII characters and emoticons. |
| `lang/Telegram-API.*.tcl` | All language dependant strings are defined here. For example, if you want to change the way Telegram messages are sent towards the IRC channel, you can define it here. |
| `lib/libjson.tcl` | Generic JSON library for Tcl. All generic JSON functions are defined here. |
| `lib/libtelegram.tcl` | Generic Telegram library for Tcl. All functions which call the Telegram API methods are defined here. See https://core.telegram.org/bots/api#available-methods for a list of all available Telegram API methods. |
| `lib/libunicode.tcl` | Generic Unicode library for Tcl. All generic functions for translating between UTF-8/UTF-16/Escaped Unicode/ASCII characters are defined here. |
| `modules/*.tcl` | All publically available Telegram bot commands are defined here. Optional, not needed for basic operation. |
| `web/tg.php` | PHP script which allow IRC users to download images, video's and other attachments posted in the Telegram group. |

## Feedback

Please let me know if you use this script, if you run into bugs or problems, and of course if you like it!
