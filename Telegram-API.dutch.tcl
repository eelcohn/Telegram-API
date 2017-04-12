# ---------------------------------------------------------------------------- #
# Telegram-API module for Eggdrop - Dutch language file                        #
#                                                                              #
# written by Eelco Huininga 2016                                               #
# ---------------------------------------------------------------------------- #

# Messages from IRC to Telegram
set MSG_IRC_MSGSENT			"<i>%1\$s@IRC:</i> %2\$s"
set MSG_IRC_NICKJOINED		"<i>%1\$s@IRC</i> is <a href=\"%2\$s\">%3\$s</a> binnengekomen."
set MSG_IRC_NICKLEFT		"<i>%1\$s@IRC</i> heeft <a href=\"%2\$s\">%3\$s</a> verlaten (%4\$s)."
set MSG_IRC_NICKACTION		"<i>%1\$s@IRC:</i> %2\$s %3\$s"
set MSG_IRC_NICKCHANGE		"<i>%1\$s@IRC</i> heet nu <i>%2\$s</i>"
set MSG_IRC_TOPICCHANGE		"<i>%1\$s@IRC</i> heeft het onderwerp op <a href=\"%2\$s\">%3\$s</a> veranderd naar <i>%4\$s</i>"
set MSG_IRC_KICK			"<i>%1\$s@IRC</i> heeft <i>%2\$s</i> weggeschopt van <i>%3\$s</i>: <b>%4\$s</b>"

# Messages from Telegram to IRC
set MSG_TG_MSGSENT			"\026%1\$s@Telegram:\026 %2\$s"
set MSG_TG_AUDIOSENT		"\026%1\$s@Telegram heeft een audiobestand verstuurd: %2\$s - %3\$s (%4\$s s). Gebruik \026/dccget %5\$s tgfile %6\$s \026om het bestand te downloaden."
set MSG_TG_DOCSENT			"\026%1\$s@Telegram heeft een document verstuurd: %2\$s (%3\$s bytes). Gebruik \026/dccget %4\$s tgfile %5\$s \026om het bestand te downloaden."
set MSG_TG_PHOTOSENT		"\026%1\$s@Telegram heeft een foto verstuurd%2\$s. Gebruik \026/dccget %3\$s tgfile %4\$s \026om het bestand te downloaden."
set MSG_TG_STICKERSENT		"\026%1\$s@Telegram heeft een sticker verstuurd (%2\$s).\026"
set MSG_TG_VIDEOSENT		"\026%1\$s@Telegram heeft een video verstuurd%2\$s (%3\$s s). Gebruik \026/dccget %4\$s tgfile %5\$s \026om het bestand te downloaden."
set MSG_TG_VOICESENT		"\026%1\$s@Telegram heeft een voicebestand verstuurd: %2\$s (%3\$s bytes). Gebruik \026/dccget %4\$s tgfile %5\$s \026om het bestand te downloaden."
set MSG_TG_CONTACTSENT		"\026%1\$s@Telegram heeft een contact verstuurd: %2\$s (%3\$s %4\$s).\026"
set MSG_TG_LOCATIONSENT		"\026%1\$s@Telegram heeft een locatie verstuurd (longitude=%2\$s latitude=%2\$s).\026"
set MSG_TG_VENUESENT		"\026%1\$s@Telegram heeft een venue verstuurd: location=%2\$s title=%3\$s address=%4\$s foursquare_id=%5\$s.\026"
set MSG_TG_USERADD			"\026%1\$s@Telegram heeft %2\$s aan de Telegram groep toegevoegd.\026"
set MSG_TG_USERLEFT			"\026%1\$s@Telegram heeft %2\$s uit de Telegram groep verwijderd.\026"
set MSG_TG_CHATTITLE		"\026%1\$s@Telegram heeft het onderwerp van de Telegram groep gewijzigd naar %2\$s.\026"
set MSG_TG_PICCHANGE		"\026%1\$s@Telegram heeft de afbeelding van de Telegram groep gewijzigd. Gebruik \026/dccget %2\$s tgfile %3\$s \026om het bestand te downloaden.\026"
set MSG_TG_PICDELETE		"\026%1\$s@Telegram heeft de afbeelding van de Telegram groep verwijderd."
set MSG_TG_UNKNOWNSTICKER	"Onbekende sticker."
set MSG_TG_UNIMPL			"Onbekend Telegram bericht ontvangen."
set TG_BOT_UNKNOWNCMD		"Onbekend ."

# Messages for user commands for your bot
set MSG_BOT_HELP			"Ik ben <i>%1\$s</i>, je persoonlijke barkeeper. Begin een commando met <b>/</b> en je krijgt een lijst van mogelijkheden te zien."
set MSG_BOT_HELP_IRCUSER	"Je hebt geen gebruikersnaam opgegeven. Type /ircuser <gebruikersnaam> om informatie over een IRC gebruiker te laten zien."
set MSG_BOT_TG_TOPIC		"Het onderwerp op <a href=\"%1\$s\">%2\$s</a> is: <i>%3\$s</i>"
#set MSG_BOT_IRC_TOPIC		"Het onderwerp op %1\$s is <i>%2\$s</i>"
set MSG_BOT_IRCUSERS		"Op <a href=\"%1\$s\">%2\$s\</a> zijn <i>%3\$s\</i> bekend."
set MSG_BOT_IRCUSER			"<i>%1\$s@IRC</i> is sinds %2\$s op <a href=\"%3\$s\">%4\$s</a> bekend als <i>%5\$s</i>"
set MSG_BOT_TG_UNKNOWNUSER	"<i>%1\$s@IRC</i> is niet bekend op <a href=\"%2\$s\">%3\$s</a>"
set MSG_BOT_UNKNOWNCMD		"Dat snap ik niet. Type /help om een overzicht van alle commando's te bekijken."

# Messages for admins controlling your bot
set MSG_BOT_CONNECTED		"Chat group %s (%s) is now connected to %s."
set MSG_BOT_DISCONNECTED	"Chat group %s (%s) is now disconnected from %s."
set MSG_BOT_UNAUTHORIZED	"Je bent niet geauthoriseerd om dat te doen."

# Messages for the Quote-module
set MSG_QUOTE_NOTEXIST		"Quote nummer %s bestaat niet."
set MSG_QUOTE_NOTFOUND		"Geen quotes met %s gevonden."
set MSG_QUOTE_QUOTEADDED	"Quote is toegevoegd aan de quote-lijst."
set MSG_QUOTE_HELP			"Gebruik <i>/addquote</i> om een quote toe te voegen."

# Messages for the PSN-module
set MSG_PSN_RESULT			"Speler: %s\%0ANiveau: %s\%0ARecent gespeelde spellen:\%0A1. %s\%0A2. %s\%0a3. %s"
set MSG_PSN_NOTFOUND		"Geen gegevens gevonden. Deze gebruiker heeft mogelijk een privé-profiel."
