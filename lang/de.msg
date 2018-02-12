# ---------------------------------------------------------------------------- #
# Telegram-API module for Eggdrop - German language file v20180212             #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

# Messages from IRC to Telegram
::msgcat::mcset de MSG_IRC_MSGSENT		"<i>%1\$s@IRC:</i> %2\$s"
::msgcat::mcset de MSG_IRC_NICKJOINED		"<i>%1\$s@IRC</i> ist <a href=\"%2\$s\">%3\$s</a> hereingekommen."
::msgcat::mcset de MSG_IRC_NICKLEFT		"<i>%1\$s@IRC</i> hat <a href=\"%2\$s\">%3\$s</a> (%4\$s) verlassen."
::msgcat::mcset de MSG_IRC_NICKACTION		"<i>%1\$s@IRC:</i> %2\$s %3\$s"
::msgcat::mcset de MSG_IRC_NICKCHANGE		"<i>%1\$s@IRC</i> ist jetzt bekannt als <i>%2\$s</i>"
::msgcat::mcset de MSG_IRC_TOPICCHANGE		"<i>%1\$s@IRC</i> hat das Thema auf <a href=\"%2\$s\">%3\$s</a> in <i>%4\$s</i> geändert."
::msgcat::mcset de MSG_IRC_KICK			"<i>%1\$s@IRC</i> hat <i>%2\$s</i> von <i>%3\$s</i> getreten: <b>%4\$s</b>"
::msgcat::mcset de MSG_IRC_MODECHANGE		"<i>%1\$s@IRC</i> setzt den Modus auf %2\$s auf %3\$s"

# IRC service messages
::msgcat::mcset de MSG_IRC_INVITELINK		"Schließe dich der Telegrammgruppe %1\$s hier %2\$s an."
::msgcat::mcset de MSG_IRC_DCCSENDFAILED	"Datei konnte nicht gesendet werden. Kontakt den Administrator, sich die Protokolldatei anzusehen."
::msgcat::mcset de MSG_IRC_DCCSENDFILE		"Start DCC Übertragung %1\$s."
::msgcat::mcset de MSG_IRC_DCCSENDFULL		"Kann %1\$s nicht senden (zu viele DCC Verbindungen). Bitte versuche es später noch einmal."
::msgcat::mcset de MSG_IRC_DCCSOCKET		"Kann keinen Socket für die Übertragung von %1\$s öffnen."
::msgcat::mcset de MSG_IRC_DCCNOTFOUND		"Datei %1\$s nicht gefunden."
::msgcat::mcset de MSG_IRC_DCCQUEUED		"Die Datei %1\$s wird zur Übertragung in die Warteschlange gestellt.

# Messages from Telegram to IRC
::msgcat::mcset de MSG_TG_MSGSENT		"%2\$s@Telegram: %2\$s"
::msgcat::mcset de MSG_TG_MSGREPLYTOSENT	"%1\$s (als Antwort auf %2\$s@Telegram: %3\$s)"
::msgcat::mcset de MSG_TG_MSGFORWARDED		"%1\$s (weitergeleitet von %2\$s)"
::msgcat::mcset de MSG_TG_PINNEDMESSAGE		"%1\$s@Telegram: %2\$s (festgesteckt auf %3\$s)"
::msgcat::mcset de MSG_TG_AUDIOSENT		"%1\$s@Telegram hat eine Audiodatei gesendet: %2\$s - %3\$s (%4\$s s). Du kannst es mit !tgfile %5\$s herunterladen."
::msgcat::mcset de MSG_TG_DOCSENT		"%1\$s@Telegram hat ein Dokument gesendet%2\$s: %3\$s (%4\$s bytes). Du kannst es mit !tgfile %5\$s herunterladen."
::msgcat::mcset de MSG_TG_PHOTOSENT		"%1\$s@Telegram hat ein Foto gesendet%2\$s (%3\$s bytes). Du kannst es mit !tgfile %4\$s herunterladen."
::msgcat::mcset de MSG_TG_STICKERSENT		"%1\$s@Telegram hat einen Aufkleber aus dem Set %2\$s geschickt (%3\$s)."
::msgcat::mcset de MSG_TG_VIDEOSENT		"%1\$s@Telegram hat ein Video gesendet%2\$s (%3\$s s). Du kannst es mit !tgfile %4\$s herunterladen."
::msgcat::mcset de MSG_TG_VOICESENT		"%1\$s@Telegram hat eine Sprachdatei gesendet: %2\$s (%3\$s bytes). Sie können es mit !tgfile %4\$s herunterladen."
::msgcat::mcset de MSG_TG_CONTACTSENT		"%1\$s@Telegram hat einen Kontakt gesendet: %2\$s (%3\$s %4\$s)."
::msgcat::mcset de MSG_TG_LOCATIONSENT		"%1\$s@Telegram hat einen Standort gesendet: https://www.openstreetmap.org/#map=19/%3\$s/%2\$s"
::msgcat::mcset de MSG_TG_VENUESENT		"%1\$s@Telegram hat einen Veranstaltungsort geschickt: Standort=%2\$s Titel=%3\$s Adresse=%4\$s foursquare_id=%5\$s."
::msgcat::mcset de MSG_TG_USERJOINED		"%1\$s@Telegram hat sich der Telegram-Gruppe angeschlossen."
::msgcat::mcset de MSG_TG_USERADD		"%1\$s@Telegram hat %2\$s zur Telegrammgruppe hinzugefügt."
::msgcat::mcset de MSG_TG_USERLEFT		"%1\$s@Telegram hat die Telegrammgruppe verlassen."
::msgcat::mcset de MSG_TG_USERREMOVED		"%1\$s@Telegram hat %2\$s aus der Telegrammgruppe entfernt."
::msgcat::mcset de MSG_TG_CHATTITLE		"%1\$s@Telegram hat das Thema auf die Telegramgruppe in %2\$s geändert."
::msgcat::mcset de MSG_TG_PICCHANGE		"%1\$s@Telegram hat das Telegramm Gruppenbild geändert. Du kannst es mit !tgfile %2\$s herunterladen."
::msgcat::mcset de MSG_TG_PICDELETE		"%1\$s@Telegram has removed the Telegram group picture."
::msgcat::mcset de MSG_TG_GROUPMIGRATED		"%1$\s@Telegram hat das Telegramm Gruppenbild entfernt."
::msgcat::mcset de MSG_TG_UNKNOWNSTICKER	"Unbekannter Aufkleber."
::msgcat::mcset de MSG_TG_UNIMPL		"Unbekannte Telegrammnachricht empfangen: %1\$s"

# Messages for user commands for your bot
::msgcat::mcset de MSG_BOT_PUBHELP		"Ich bin <i>%1\$s</i>, dein persönlicher Barkeeper. Verfügbare Befehle sind:\n"
::msgcat::mcset de MSG_BOT_PRVHELP		"Ich bin <i>%1\$s</i>, dein persönlicher Barkeeper. Verfügbare Befehle sind:\n"
::msgcat::mcset de MSG_BOT_HELP_IRCUSER		"Sie haben keinen Benutzernamen eingegeben. Type /ircuser <username> to look up information on an IRC user."
::msgcat::mcset de MSG_BOT_IRCTOPIC		"Das Thema auf die Telegramgruppe <a href=\"%1\$s\">%2\$s</a> ist: <i>%3\$s</i>"
::msgcat::mcset de MSG_BOT_IRCTOPIC_HELP	": Zeigen Sie das Thema für die IRC-Kanäle an, die mit dieser Telegrammgruppe verbunden sind."
::msgcat::mcset de MSG_BOT_IRCUSERS		"Die folgenden Benutzer sind auf <a href=\"%1\$s\">%2\$s\</a> bekannt:\n\n%3\$s"
::msgcat::mcset de MSG_BOT_IRCUSER_HELP		": Zeigen Sie alle Benutzer auf den IRC-Kanälen an, die mit dieser Telegrammgruppe verbunden sind."
::msgcat::mcset de MSG_BOT_IRCUSER		"<i>%1\$s@IRC</i> ist seit dem %2\$s auf <a href=\"%3\$s\">%4\$s</a> als <i>%5\$s</i> bekannt."
::msgcat::mcset de MSG_BOT_IRCUSERUNKNOWN	"<i>%1\$s@IRC</i> ist nicht bekannt auf <a href=\"%2\$s\">%3\$s</a>"
::msgcat::mcset de MSG_BOT_IRCUSER_HELP		" <Spitzname>: Zeigen Sie detaillierte Informationen zu einem IRC-Benutzer an."
::msgcat::mcset de MSG_IRCKICKUSER		"Sie wurden von einem Telegram-Benutzer aus diesem Kanal geworfen."
::msgcat::mcset de MSG_IRCBANUSER		"Du wurdest von einem Telegram-Benutzer von diesem Kanal ausgeschlossen."
::msgcat::mcset de MSG_BOT_IRCKICK_HELP		" <Spitzname>: Tritt ein IRC-Benutzer aus dem IRC-Kanal."
::msgcat::mcset de MSG_BOT_IRCBAN_HELP		" <Spitzname>: Verbanne einen IRC-Benutzer vom IRC-Kanal."
::msgcat::mcset de MSG_BOT_IRCUNBAN_HELP	" <Spitzname>: Entarre einen IRC-Benutzer vom IRC-Kanal."
::msgcat::mcset de MSG_BOT_USERINFO		"Telegram ID %1\$s ist ein %2\$s, hast einen Namen von %3\$s, hast einen Spitsname von %4\$s und hat der status %5\$s."
::msgcat::mcset de MSG_BOT_USERNOTVALID		"Informationen zu Telegram ID %1\$s auf diesem Kanal können nicht abgerufen werden."
::msgcat::mcset de MSG_BOT_UNKNOWNCMD		"Ich verstehe das nicht. Geben Sie /help ein, um eine Liste aller Befehle anzuzeigen."
::msgcat::mcset de MSG_BOT_GOTNOPRIVS "%1\$s ist dazu nicht berechtigt."

# Messages for admins controlling your bot
::msgcat::mcset de MSG_BOT_PASSWORDSET		"Willkommen bei %1\$s! Ihr Passwort wurde festgelegt."
::msgcat::mcset de MSG_BOT_USERLOGIN		"Willkommen bei %1\$s! Sie sind jetzt als %2\$s eingeloggt."
::msgcat::mcset de MSG_BOT_USERLOGOUT		"Sie sind jetzt als %1\$s ausgeloggt."
::msgcat::mcset de MSG_BOT_FIRSTLOGIN		"Dies ist deine erste Anmeldung bei %1\$s."
::msgcat::mcset de MSG_BOT_LASTLOGIN		"Das letzte Mal, als du dich bei %1\$s eingeloggt hast, war am %2\$s."
::msgcat::mcset de MSG_BOT_USERPASSWRONG	"Diese Kombination aus Benutzername und Passwort ist mir unbekannt."
::msgcat::mcset de MSG_BOT_USERLOGGEDINAS	"Du bist als %1\$s eingeloggt."
::msgcat::mcset de MSG_BOT_USERINFO		"Dein Benutzername ist %1\$s\nDein Telegram-ID ist %2\$s\nDein letzter Telegram-Login war am %3\$s\nYour last Telegram-logout was at %4\$s\nDein letzter Telegram-login ID war %5\$s\nDein Telegram-account war am %6\$s erstellt\nDein IRC-account war am %7\$s erstellt\nDein letzter IRC-login war am %8\$s\nDein IRC-hostnames sind %9\$s\nDein IRC info ist %10\$s"
::msgcat::mcset de MSG_BOT_NOTLOGGEDIN		"Du bist nicht eingeloggt."
::msgcat::mcset de MSG_BOT_UNAUTHORIZED		"Du bist nicht dazu berechtigt."
