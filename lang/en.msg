# ---------------------------------------------------------------------------- #
# Telegram-API module for Eggdrop - English language file v20180207            #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

# Messages from IRC to Telegram
::msgcat::mcset en MSG_IRC_MSGSENT		"<i>%s@IRC:</i> %s"
::msgcat::mcset en MSG_IRC_NICKJOINED		"<i>%s@IRC</i> has entered <a href=\"%s\">%s</a>."
::msgcat::mcset en MSG_IRC_NICKLEFT		"<i>%s@IRC</i> has left <a href=\"%s\">%s</a> (%s)."
::msgcat::mcset en MSG_IRC_NICKACTION		"<i>%s@IRC:</i> %s %s"
::msgcat::mcset en MSG_IRC_NICKCHANGE		"<i>%s@IRC</i> is now known as <i>%s</i>"
::msgcat::mcset en MSG_IRC_TOPICCHANGE		"<i>%s@IRC</i> has changed the topic on <a href=\"%s\">%s</a> to <i>%s</i>"
::msgcat::mcset en MSG_IRC_KICK		"<i>%s@IRC</i> has kicked <i>%s</i> from <i>%s</i>: <b>%s</b>"
::msgcat::mcset en MSG_IRC_MODECHANGE		"<i>%1\$s@IRC</i> zet de modus %3\$s op %2\$s"

# Messages from Telegram to IRC
::msgcat::mcset en MSG_TG_MSGSENT			"%s@Telegram: %s"
::msgcat::mcset en MSG_TG_MSGREPLYTOSENT "%1\$s (in reply to %2\$s@Telegram: %3\$s)"
::msgcat::mcset en MSG_TG_MSGFORWARDED "%1\$s (forwarded from %2\$s)"
::msgcat::mcset en MSG_TG_PINNEDMESSAGE "%1\$s@Telegram: %2\$s (pinned by %3\$s on %4\$s)"
::msgcat::mcset en MSG_TG_AUDIOSENT		"%s@Telegram has sent an audiofile: %s - %s (%s s). Use !tgfile %s to download the file."
::msgcat::mcset en MSG_TG_DOCSENT			"%s@Telegram has sent a document: %s (%s bytes).  Use !tgfile %s to download the file."
::msgcat::mcset en MSG_TG_PHOTOSENT		"%s@Telegram has sent a photo%s. Use !tgfile %s to download the file."
::msgcat::mcset en MSG_TG_STICKERSENT		"%s@Telegram has sent a sticker from the %s set (%s)."
::msgcat::mcset en MSG_TG_VIDEOSENT		"%s@Telegram has sent a video%s (%s s). Use !tgfile %s to download the file."
::msgcat::mcset en MSG_TG_VOICESENT		"%s@Telegram has sent a voice file: %s (%s bytes). Use !tgfile %s to download the file."
::msgcat::mcset en MSG_TG_CONTACTSENT		"%s@Telegram has sent a contact: %s (%s %s)."
::msgcat::mcset en MSG_TG_LOCATIONSENT		"%s@Telegram has sent a location: https://www.openstreetmap.org/#map=19/%3\$s/%2\$s"
::msgcat::mcset en MSG_TG_VENUESENT		"%s@Telegram has sent a venue: location=%s title=%s address=%s foursquare_id=%s."
::msgcat::mcset en MSG_TG_USERJOINED			"%s@Telegram has joined the Telegram group."
::msgcat::mcset en MSG_TG_USERADD			"%s@Telegram has added %s to the Telegram group."
::msgcat::mcset en MSG_TG_USERLEFT			"%s@Telegram has left the Telegram group."
::msgcat::mcset en MSG_TG_USERREMOVED		"%s@Telegram has removed %s from the Telegram group."
::msgcat::mcset en MSG_TG_CHATTITLE		"%s@Telegram has changed the topic of the Telegram group to %s."
::msgcat::mcset en MSG_TG_PICCHANGE		"%s@Telegram has changed the Telegram group picture. Use !tgfile %s to download the file."
::msgcat::mcset en MSG_TG_PICDELETE		"%s@Telegram has removed the Telegram group picture."
::msgcat::mcset en MSG_TG_GROUPMIGRATED  "%1$\s@Telegram has migrated the Telegram group to a supergroup."
::msgcat::mcset en MSG_TG_UNKNOWNSTICKER	"Unknown sticker."
::msgcat::mcset en MSG_TG_UNIMPL			"Unknown Telegram message received: %1\$s"

# Messages for user commands for your bot
::msgcat::mcset en MSG_BOT_HELP			"I'm <i>%s</i>, your personal bartender. Start a command with <b>/</b> and I'll show you a list of commands."
::msgcat::mcset en MSG_BOT_HELP_IRCUSER	"You haven't entered an username. Type /ircuser <username> to look up information on an IRC user."
::msgcat::mcset en MSG_BOT_TG_TOPIC		"The topic on <a href=\"%s\">%s</a> is: <i>%s</i>"
::msgcat::mcset en MSG_BOT_IRC_TOPIC		"Het onderwerp op %s is <i>%s</i>"
::msgcat::mcset en MSG_BOT_IRCUSERS		"On <a href=\"%s\">%s\</a> are <i>%s\</i> known."
::msgcat::mcset en MSG_BOT_IRCUSER			"<i>%s@IRC</i> is since %s on <a href=\"%s\">%s</a> known as <i>%s</i>"
::msgcat::mcset en MSG_BOT_TG_UNKNOWNUSER	"<i>%s@IRC</i> is not known on <a href=\"%s\">%s</a>"
::msgcat::mcset en MSG_BOT_UNKNOWNCMD		"I don't get that. Type /help to see a list of all commands."

# Messages for admins controlling your bot
::msgcat::mcset en MSG_BOT_PASSWORDSET	"Welcme to %s! Your password has been set."
::msgcat::mcset en MSG_BOT_USERLOGIN		"Welcome to %s! You're now logged in as %s."
::msgcat::mcset en MSG_BOT_USERLOGOUT		"You are now logged out as %s."
::msgcat::mcset en MSG_BOT_FIRSTLOGIN	"This is your first Telegram-login to %s."
::msgcat::mcset en MSG_BOT_LASTLOGIN	"The last time you logged in to %s was at %s."
::msgcat::mcset en MSG_BOT_USERPASSWRONG	"That username and password combination is unknown to me."
::msgcat::mcset en MSG_BOT_USERLOGGEDINAS		"You are logged in as %s."
::msgcat::mcset en MSG_BOT_USERINFO	"Your username is %s\nYour Telegram-ID is %s\nYour last Telegram-login was at %s\nYour last Telegram-logout was at %s\nYour last Telegram-login ID was %s\nYour Telegram-account was created on %s\nYour IRC-account was created at %s\nYour last IRC-login was at %s\nYour IRC-hostnames are %s\nYour IRC info is %s"
::msgcat::mcset en MSG_BOT_NOTLOGGEDIN	"You're not logged in."
::msgcat::mcset en MSG_BOT_UNAUTHORIZED	"You're not authorized to do that."
