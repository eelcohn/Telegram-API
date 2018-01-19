# ---------------------------------------------------------------------------- #
# Telegram-API module for Eggdrop - English language file v20180118            #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

# Messages from IRC to Telegram
set MSG_IRC_MSGSENT		"<i>%s@IRC:</i> %s"
set MSG_IRC_NICKJOINED		"<i>%s@IRC</i> has entered <a href=\"%s\">%s</a>."
set MSG_IRC_NICKLEFT		"<i>%s@IRC</i> has left <a href=\"%s\">%s</a> (%s)."
set MSG_IRC_NICKACTION		"<i>%s@IRC:</i> %s %s"
set MSG_IRC_NICKCHANGE		"<i>%s@IRC</i> is now known as <i>%s</i>"
set MSG_IRC_TOPICCHANGE		"<i>%s@IRC</i> has changed the topic on <a href=\"%s\">%s</a> to <i>%s</i>"
set MSG_IRC_KICK		"<i>%s@IRC</i> has kicked <i>%s</i> from <i>%s</i>: <b>%s</b>"
set MSG_IRC_MODECHANGE		"<i>%1\$s@IRC</i> zet de modus %3\$s op %2\$s"

# Messages from Telegram to IRC
set MSG_TG_MSGSENT			"%s@Telegram: %s"
set MSG_TG_MSGREPLYTOSENT "%1\$s (in reply to %2\$s@Telegram: %3\$s)"
set MSG_TG_MSGFORWARDED "%1\$s (forwarded from %2\$s)"
set MSG_TG_AUDIOSENT		"%s@Telegram has sent an audiofile: %s - %s (%s s). Use /ctcp %s tgfile %s to download the file."
set MSG_TG_DOCSENT			"%s@Telegram has sent a document: %s (%s bytes).  Use /ctcp %s tgfile %s to download the file."
set MSG_TG_PHOTOSENT		"%s@Telegram has sent a photo%s. Use /ctcp %s tgfile %s to download the file."
set MSG_TG_STICKERSENT		"%s@Telegram has sent a sticker (%s)."
set MSG_TG_VIDEOSENT		"%s@Telegram has sent a video%s (%s s). Use /ctcp %s tgfile %s to download the file."
set MSG_TG_VOICESENT		"%s@Telegram has sent a voice file: %s (%s bytes). Use /ctcp %s tgfile %s to download the file."
set MSG_TG_CONTACTSENT		"%s@Telegram has sent a contact: %s (%s %s)."
set MSG_TG_LOCATIONSENT		"%s@Telegram has sent a location: https://www.openstreetmap.org/#map=19/%3\$s/%2\$s"
set MSG_TG_VENUESENT		"%s@Telegram has sent a venue: location=%s title=%s address=%s foursquare_id=%s."
set MSG_TG_USERJOINED			"%s@Telegram has joined the Telegram group."
set MSG_TG_USERADD			"%s@Telegram has added %s to the Telegram group."
set MSG_TG_USERLEFT			"%s@Telegram has left the Telegram group."
set MSG_TG_USERREMOVED		"%s@Telegram has removed %s from the Telegram group."
set MSG_TG_CHATTITLE		"%s@Telegram has changed the topic of the Telegram group to %s."
set MSG_TG_PICCHANGE		"%s@Telegram has changed the Telegram group picture. Use /ctcp %s tgfile %s to download the file."
set MSG_TG_PICDELETE		"%s@Telegram has removed the Telegram group picture."
set MSG_TG_GROUPMIGRATED  "%1$\s@Telegram has migrated the Telegram group to a supergroup."
set MSG_TG_UNKNOWNSTICKER	"Unknown sticker."
set MSG_TG_UNIMPL			"Unknown Telegram message received: %1\$s"

# Messages for user commands for your bot
set MSG_BOT_HELP			"I'm <i>%s</i>, your personal barkeeper. Start a command with <b>/</b> and I'll show you a list of commands."
set MSG_BOT_HELP_IRCUSER	"You haven't entered an username. Type /ircuser <username> to look up information on an IRC user."
set MSG_BOT_TG_TOPIC		"The topic on <a href=\"%s\">%s</a> is: <i>%s</i>"
#set MSG_BOT_IRC_TOPIC		"Het onderwerp op %s is <i>%s</i>"
set MSG_BOT_IRCUSERS		"On <a href=\"%s\">%s\</a> are <i>%s\</i> known."
set MSG_BOT_IRCUSER			"<i>%s@IRC</i> is since %s on <a href=\"%s\">%s</a> known as <i>%s</i>"
set MSG_BOT_TG_UNKNOWNUSER	"<i>%s@IRC</i> is not known on <a href=\"%s\">%s</a>"
set MSG_BOT_UNKNOWNCMD		"I don't get that. Type /help to see a list of all commands."

# Messages for admins controlling your bot
set MSG_BOT_PASSWORDSET	"Welcme to %s! Your password has been set."
set MSG_BOT_USERLOGIN		"Welcome to %s! You're now logged in as %s."
set MSG_BOT_USERLOGOUT		"You are now logged out as %s."
set MSG_BOT_FIRSTLOGIN	"This is your first Telegram-login to %s."
set MSG_BOT_LASTLOGIN	"The last time you logged in to %s was at %s."
set MSG_BOT_USERPASSWRONG	"That username and password combination is unknown to me."
set MSG_BOT_USERLOGGEDINAS		"You are logged in as %s."
set MSG_BOT_USERINFO	"Your username is %s\nYour Telegram-ID is %s\nYour last Telegram-login was at %s\nYour last Telegram-logout was at %s\nYour last Telegram-login ID was %s\nYour Telegram-account was created on %s\nYour IRC-account was created at %s\nYour last IRC-login was at %s\nYour IRC-hostnames are %s\nYour IRC info is %s"
set MSG_BOT_NOTLOGGEDIN	"You're not logged in."
set MSG_BOT_UNAUTHORIZED	"You're not authorized to do that."

# Messages for the Quote-module
set MSG_QUOTE_NOTEXIST		"Quote number %s does not exist."
set MSG_QUOTE_NOTFOUND		"No quotes with %s found."
set MSG_QUOTE_QUOTEADDED	"Quote has been added to the quote-list."
set MSG_QUOTE_HELP			"Use <i>/quote</i> to view a quote from the legendary quote database."
set MSG_QUOTE_ADDHELP		"Use <i>/addquote</i> to add a quote to the quote-list."

# Messages for the PSN-module
set MSG_PSN_RESULT			"Player: %sLevel: %sRecently seen playing:1. %s2. %s3. %s"
set MSG_PSN_NOTFOUND		"No data found. This user may have their profile set to private."
