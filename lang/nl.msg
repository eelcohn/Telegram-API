# ---------------------------------------------------------------------------- #
# Telegram-API module for Eggdrop - Dutch language file v20180210              #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

# Messages from IRC to Telegram
::msgcat::mcset nl MSG_IRC_MSGSENT		"<i>%1\$s@IRC:</i> %2\$s"
::msgcat::mcset nl MSG_IRC_NICKJOINED		"<i>%1\$s@IRC</i> is <a href=\"%2\$s\">%3\$s</a> binnengekomen."
::msgcat::mcset nl MSG_IRC_NICKLEFT		"<i>%1\$s@IRC</i> heeft <a href=\"%2\$s\">%3\$s</a> verlaten (%4\$s)."
::msgcat::mcset nl MSG_IRC_NICKACTION		"<i>%1\$s@IRC:</i> %2\$s %3\$s"
::msgcat::mcset nl MSG_IRC_NICKCHANGE		"<i>%1\$s@IRC</i> heet nu <i>%2\$s</i>"
::msgcat::mcset nl MSG_IRC_TOPICCHANGE		"<i>%1\$s@IRC</i> heeft het onderwerp op <a href=\"%2\$s\">%3\$s</a> veranderd naar <i>%4\$s</i>"
::msgcat::mcset nl MSG_IRC_KICK		"<i>%1\$s@IRC</i> heeft <i>%2\$s</i> weggeschopt van <i>%3\$s</i>: <b>%4\$s</b>"
::msgcat::mcset nl MSG_IRC_MODECHANGE "<i>%1\$s@IRC</i> zet de modus %3\$s op %2\$s"

# IRC service messages
::msgcat::mcset nl MSG_IRC_INVITELINK "Je kunt de Telegram groep %1\$s hier vinden %2\$s"
::msgcat::mcset nl MSG_IRC_DCCSENDFAILED  "Kan het bestand niet verzenden. Vraag de beheerder om naar de logbestanden te kijken."
::msgcat::mcset nl MSG_IRC_DCCSENDFILE  "DCC overdracht van %1\$s wordt gestart."
::msgcat::mcset nl MSG_IRC_DCCSENDFULL  "Kan %1\$s niet verzenden (te veel connecties). Probeer het later opnieuw."
::msgcat::mcset nl MSG_IRC_DCCSOCKET  "Kan geen socket openen voor het versturen van %1\$s."
::msgcat::mcset nl MSG_IRC_DCCNOTFOUND  "Bestand %1\$s niet gevonden."
::msgcat::mcset nl MSG_IRC_DCCQUEUED  "Bestand %1\$s is in de wachtrij gezet om te verzenden."

# Messages from Telegram to IRC
::msgcat::mcset nl MSG_TG_MSGSENT		"%1\$s@Telegram: %2\$s"
::msgcat::mcset nl MSG_TG_MSGREPLYTOSENT "%1\$s (antwoord op %2\$s@Telegram: %3\$s)"
::msgcat::mcset nl MSG_TG_MSGFORWARDED "%1\$s (doorgestuurd van %2\$s)"
::msgcat::mcset nl MSG_TG_PINNEDMESSAGE "%1\$s@Telegram: %2\$s (vastgezet op %3\$s)"
::msgcat::mcset nl MSG_TG_AUDIOSENT		"%1\$s@Telegram heeft een audiobestand verstuurd: %2\$s - %3\$s (%4\$s s). Gebruik !tgfile %5\$s om het bestand te downloaden."
::msgcat::mcset nl MSG_TG_DOCSENT		"%1\$s@Telegram heeft een document verstuurd%2\$s: %3\$s (%4\$s bytes). Gebruik !tgfile %5\$s om het bestand te downloaden."
::msgcat::mcset nl MSG_TG_PHOTOSENT		"%1\$s@Telegram heeft een foto verstuurd%2\$s (%3\$s bytes). Gebruik !tgfile %4\$s om het bestand te downloaden."
::msgcat::mcset nl MSG_TG_STICKERSENT		"%1\$s@Telegram heeft een sticker uit de %2\$s serie verstuurd (%3\$s)."
::msgcat::mcset nl MSG_TG_VIDEOSENT		"%1\$s@Telegram heeft een video verstuurd%2\$s (%3\$s s). Gebruik !tgfile %4\$s om het bestand te downloaden."
::msgcat::mcset nl MSG_TG_VOICESENT		"%1\$s@Telegram heeft een voicebestand verstuurd: %2\$s (%3\$s bytes). Gebruik !tgfile %4\$s om het bestand te downloaden."
::msgcat::mcset nl MSG_TG_CONTACTSENT		"%1\$s@Telegram heeft een contact verstuurd: %2\$s (%3\$s %4\$s)."
::msgcat::mcset nl MSG_TG_LOCATIONSENT		"%1\$s@Telegram heeft een locatie verstuurd: https://www.openstreetmap.org/#map=19/%3\$s/%2\$s"
::msgcat::mcset nl MSG_TG_VENUESENT		"%1\$s@Telegram heeft een venue verstuurd: location=%2\$s title=%3\$s address=%4\$s foursquare_id=%5\$s."
::msgcat::mcset nl MSG_TG_USERJOINED		"%1\$s@Telegram is nu lid van de Telegram groep."
::msgcat::mcset nl MSG_TG_USERADD		"%1\$s@Telegram heeft %2\$s aan de Telegram groep toegevoegd."
::msgcat::mcset nl MSG_TG_USERLEFT		"%1\$s@Telegram heeft de Telegram groep verlaten."
::msgcat::mcset nl MSG_TG_USERREMOVED		"%1\$s@Telegram heeft %2\$s uit de Telegram groep verwijderd."
::msgcat::mcset nl MSG_TG_CHATTITLE		"%1\$s@Telegram heeft het onderwerp van de Telegram groep gewijzigd naar %2\$s."
::msgcat::mcset nl MSG_TG_PICCHANGE		"%1\$s@Telegram heeft de afbeelding van de Telegram groep gewijzigd. Gebruik !tgfile %2\$s om het bestand te downloaden."
::msgcat::mcset nl MSG_TG_PICDELETE		"%1\$s@Telegram heeft de afbeelding van de Telegram groep verwijderd."
::msgcat::mcset nl MSG_TG_GROUPMIGRATED  "%1$\s@Telegram heeft de Telegram groep gemigreerd naar een supergroep."
::msgcat::mcset nl MSG_TG_UNKNOWNSTICKER	"Onbekende sticker."
::msgcat::mcset nl MSG_TG_UNIMPL		"Onbekend Telegram bericht ontvangen: %1\$s"

# Messages for user commands for your bot
::msgcat::mcset nl MSG_BOT_PUBHELP		"Ik ben <i>%1\$s</i>, je persoonlijke barkeeper. Begin een commando met <b>/</b> en je krijgt een lijst van mogelijkheden te zien."
::msgcat::mcset nl MSG_BOT_PRVHELP			"Ik ben <i>%1\$s</i>, je persoonlijke barkeeper. De beschikbare commando's zijn:\n"
::msgcat::mcset nl MSG_BOT_HELP_IRCUSER	"Je hebt geen gebruikersnaam opgegeven. Type /ircuser <gebruikersnaam> om informatie over een IRC gebruiker te laten zien."
::msgcat::mcset nl MSG_BOT_TG_TOPIC		"Het onderwerp op <a href=\"%s\">%s</a> is: <i>%s</i>"
::msgcat::mcset nl MSG_BOT_IRC_TOPIC		"Het onderwerp op %s is <i>%s</i>"
::msgcat::mcset nl MSG_BOT_IRCUSERS		"Op <a href=\"%s\">%s\</a> zijn <i>%s\</i> bekend."
::msgcat::mcset nl MSG_BOT_IRCUSER		"<i>%s@IRC</i> is sinds %s op <a href=\"%s\">%s</a> bekend als <i>%s</i>"
::msgcat::mcset nl MSG_BOT_TG_UNKNOWNUSER	"<i>%s@IRC</i> is niet bekend op <a href=\"%s\">%s</a>"
::msgcat::mcset nl MSG_BOT_UNKNOWNCMD		"Dat snap ik niet. Type /help om een overzicht van alle commando's te bekijken."

# Messages for admins controlling your bot
::msgcat::mcset nl MSG_BOT_PASSWORDSET	"Welkom op %s! Je wachtwoord is nu ingesteld."
::msgcat::mcset nl MSG_BOT_USERLOGIN		"Welkom op %s! Je bent nu ingelogd als %s."
::msgcat::mcset nl MSG_BOT_USERLOGOUT		"Je bent nu uitgelogd als %s."
::msgcat::mcset nl MSG_BOT_FIRSTLOGIN	"Dit is de eerste keer dat je via Telegram inlogt op %s."
::msgcat::mcset nl MSG_BOT_LASTLOGIN	"De laatste keer dat je via Telegram hebt ingelogd op %s was op %s."
::msgcat::mcset nl MSG_BOT_USERPASSWRONG	"De combinatie van die gebruikersnaam en wachtwoord is onbekend."
::msgcat::mcset nl MSG_BOT_USERLOGGEDINAS		"Je bent ingelogd als %s."
::msgcat::mcset nl MSG_BOT_USERINFO	"Je gebruikersnaam is %s\nJe Telegram-ID is %s\nJe laatste login was om %s\nJe laatste logout was om %s\nJe vorige login was met Telegram-ID %s\nJe Telegram-account is op %s aangemaakt\nJe IRC-account is op %s aangemaakt\nJe laatste login op IRC was om %s\nJe hostnamen op IRC zijn %s\nJe IRC info is %s"
::msgcat::mcset nl MSG_BOT_NOTLOGGEDIN	"Je bent niet ingelogd."
::msgcat::mcset nl MSG_BOT_UNAUTHORIZED	"Je bent niet geauthoriseerd om dat te doen."
