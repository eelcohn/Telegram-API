# ---------------------------------------------------------------------------- #
# Telegram-API module for Eggdrop - Dutch language file v20171216              #
#                                                                              #
# written by Eelco Huininga 2016-2017                                          #
# ---------------------------------------------------------------------------- #

# Messages from IRC to Telegram
set MSG_IRC_MSGSENT		"<i>%1\$s@IRC:</i> %2\$s"
set MSG_IRC_NICKJOINED		"<i>%1\$s@IRC</i> is <a href=\"%2\$s\">%3\$s</a> binnengekomen."
set MSG_IRC_NICKLEFT		"<i>%1\$s@IRC</i> heeft <a href=\"%2\$s\">%3\$s</a> verlaten (%4\$s)."
set MSG_IRC_NICKACTION		"<i>%1\$s@IRC:</i> %2\$s %3\$s"
set MSG_IRC_NICKCHANGE		"<i>%1\$s@IRC</i> heet nu <i>%2\$s</i>"
set MSG_IRC_TOPICCHANGE		"<i>%1\$s@IRC</i> heeft het onderwerp op <a href=\"%2\$s\">%3\$s</a> veranderd naar <i>%4\$s</i>"
set MSG_IRC_KICK		"<i>%1\$s@IRC</i> heeft <i>%2\$s</i> weggeschopt van <i>%3\$s</i>: <b>%4\$s</b>"
set MSG_IRC_MODECHANGE		"<i>%1\$s@IRC</i> zet de modus %3\$s op %2\$s"

# Messages from Telegram to IRC
set MSG_TG_MSGSENT		"%1\$s@Telegram: %2\$s"
set MSG_TG_AUDIOSENT		"%1\$s@Telegram heeft een audiobestand verstuurd: %2\$s - %3\$s (%4\$s s). Gebruik /ctcp %5\$s tgfile %6\$s om het bestand te downloaden."
set MSG_TG_DOCSENT		"%1\$s@Telegram heeft een document verstuurd: %2\$s (%3\$s bytes). Gebruik /ctcp %4\$s tgfile %5\$s om het bestand te downloaden."
set MSG_TG_PHOTOSENT		"%1\$s@Telegram heeft een foto verstuurd%2\$s. Gebruik /ctcp %3\$s tgfile %4\$s om het bestand te downloaden."
set MSG_TG_STICKERSENT		"%1\$s@Telegram heeft een sticker verstuurd (%2\$s)."
set MSG_TG_VIDEOSENT		"%1\$s@Telegram heeft een video verstuurd%2\$s (%3\$s s). Gebruik /ctcp %4\$s tgfile %5\$s om het bestand te downloaden."
set MSG_TG_VOICESENT		"%1\$s@Telegram heeft een voicebestand verstuurd: %2\$s (%3\$s bytes). Gebruik /ctcp %4\$s tgfile %5\$s om het bestand te downloaden."
set MSG_TG_CONTACTSENT		"%1\$s@Telegram heeft een contact verstuurd: %2\$s (%3\$s %4\$s)."
set MSG_TG_LOCATIONSENT		"%1\$s@Telegram heeft een locatie verstuurd: https://www.openstreetmap.org/#map=19/%3\$s/%2\$s"
set MSG_TG_VENUESENT		"%1\$s@Telegram heeft een venue verstuurd: location=%2\$s title=%3\$s address=%4\$s foursquare_id=%5\$s."
set MSG_TG_USERADD		"%1\$s@Telegram heeft %2\$s aan de Telegram groep toegevoegd."
set MSG_TG_USERLEFT		"%1\$s@Telegram heeft %2\$s uit de Telegram groep verwijderd."
set MSG_TG_CHATTITLE		"%1\$s@Telegram heeft het onderwerp van de Telegram groep gewijzigd naar %2\$s."
set MSG_TG_PICCHANGE		"%1\$s@Telegram heeft de afbeelding van de Telegram groep gewijzigd. Gebruik /ctcp %2\$s tgfile %3\$s om het bestand te downloaden."
set MSG_TG_PICDELETE		"%1\$s@Telegram heeft de afbeelding van de Telegram groep verwijderd."
set MSG_TG_UNKNOWNSTICKER	"Onbekende sticker."
set MSG_TG_UNIMPL		"Onbekend Telegram bericht ontvangen."

# Messages for user commands for your bot
set MSG_BOT_HELP		"Ik ben <i>%1\$s</i>, je persoonlijke barkeeper. Begin een commando met <b>/</b> en je krijgt een lijst van mogelijkheden te zien."
set MSG_BOT_HELP_IRCUSER	"Je hebt geen gebruikersnaam opgegeven. Type /ircuser <gebruikersnaam> om informatie over een IRC gebruiker te laten zien."
set MSG_BOT_TG_TOPIC		"Het onderwerp op <a href=\"%s\">%s</a> is: <i>%s</i>"
#set MSG_BOT_IRC_TOPIC		"Het onderwerp op %s is <i>%s</i>"
set MSG_BOT_IRCUSERS		"Op <a href=\"%s\">%s\</a> zijn <i>%s\</i> bekend."
set MSG_BOT_IRCUSER		"<i>%s@IRC</i> is sinds %s op <a href=\"%s\">%s</a> bekend als <i>%s</i>"
set MSG_BOT_TG_UNKNOWNUSER	"<i>%s@IRC</i> is niet bekend op <a href=\"%s\">%s</a>"
set MSG_BOT_UNKNOWNCMD		"Dat snap ik niet. Type /help om een overzicht van alle commando's te bekijken."

# Messages for admins controlling your bot
set MSG_BOT_PASSWORDSET	"Welkom op %s! Je wachtwoord is nu ingesteld."
set MSG_BOT_USERLOGIN		"Welkom op %s! Je bent nu ingelogd als %s."
set MSG_BOT_USERLOGOUT		"Je bent nu uitgelogd als %s."
set MSG_BOT_FIRSTLOGIN	"Dit is de eerste keer dat je via Telegram inlogt op %s."
set MSG_BOT_LASTLOGIN	"De laatste keer dat je via Telegram hebt ingelogd op %s was op %s."
set MSG_BOT_USERPASSWRONG	"De combinatie van die gebruikersnaam en wachtwoord is onbekend."
set MSG_BOT_USERLOGGEDINAS		"Je bent ingelogd als %s."
set MSG_BOT_USERINFO	"Je gebruikersnaam is %s\nJe Telegram-ID is %s\nJe laatste login was om %s\nJe laatste logout was om %s\nJe vorige login was met Telegram-ID %s\nJe Telegram-account is op %s aangemaakt\nJe IRC-account is op %s aangemaakt\nJe laatste login op IRC was om %s\nJe hostnamen op IRC zijn %s\nJe IRC info is %s"
set MSG_BOT_NOTLOGGEDIN	"Je bent niet ingelogd."
set MSG_BOT_UNAUTHORIZED	"Je bent niet geauthoriseerd om dat te doen."

# Messages for the Quote-module
set MSG_QUOTE_NOTEXIST		"Quote nummer %s bestaat niet."
set MSG_QUOTE_NOTFOUND		"Geen quotes met %s gevonden."
set MSG_QUOTE_QUOTEADDED	"Quote is toegevoegd aan de quote-lijst."
set MSG_QUOTE_HELP		"Gebruik <i>/quote</i> om een quote uit de legendarische quote database te zien."
set MSG_QUOTE_ADDHELP		"Gebruik <i>/addquote</i> om een quote toe te voegen."

# Messages for the PSN-module
set MSG_PSN_RESULT		"Speler: %s\%0ANiveau: %s\%0ARecent gespeelde spellen:\%0A1. %s\%0A2. %s\%0a3. %s"
set MSG_PSN_NOTFOUND		"Geen gegevens gevonden. Deze gebruiker heeft mogelijk een privé-profiel."