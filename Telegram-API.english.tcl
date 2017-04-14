# ---------------------------------------------------------------------------- #
# Telegram-API module for Eggdrop - English language file                      #
#                                                                              #
# written by Eelco Huininga 2016-2017                                          #
# ---------------------------------------------------------------------------- #

# Messages from IRC to Telegram
set MSG_IRC_MSGSENT			"<i>%s@IRC:</i> %s"
set MSG_IRC_NICKJOINED		"<i>%s@IRC</i> has entered <a href=\"%s\">%s</a>."
set MSG_IRC_NICKLEFT		"<i>%s@IRC</i> has left <a href=\"%s\">%s</a> (%s)."
set MSG_IRC_NICKACTION		"<i>%s@IRC:</i> %s %s"
set MSG_IRC_NICKCHANGE		"<i>%s@IRC</i> is now known as <i>%s</i>"
set MSG_IRC_TOPICCHANGE		"<i>%s@IRC</i> has changed the topic on <a href=\"%s\">%s</a> to <i>%s</i>"
set MSG_IRC_KICK			"<i>%s@IRC</i> has kicked <i>%s</i> from <i>%s</i>: <b>%s</b>"

# Messages from Telegram to IRC
set MSG_TG_MSGSENT			"\026%s@Telegram:\026 %s"
set MSG_TG_AUDIOSENT		"\026%s@Telegram has sent an audiofile: %s - %s (%s s). Use \026/ctcp %s tgfile %s \026to download the file."
set MSG_TG_DOCSENT			"\026%s@Telegram has sent a document: %s (%s bytes).  Use \026/ctcp %s tgfile %s \026to download the file."
set MSG_TG_PHOTOSENT		"\026%s@Telegram has sent a photo%s. Use \026/ctcp %s tgfile %s \026to download the file."
set MSG_TG_STICKERSENT		"\026%s@Telegram has sent a sticker (%s).\026"
set MSG_TG_VIDEOSENT		"\026%s@Telegram has sent a video%s (%s s). Use \026/ctcp %s tgfile %s \026to download the file."
set MSG_TG_VOICESENT		"\026%s@Telegram has sent a voice file: %s (%s bytes). Use \026/ctcp %s tgfile %s \026to download the file."
set MSG_TG_CONTACTSENT		"\026%s@Telegram has sent a contact: %s (%s %s).\026"
set MSG_TG_LOCATIONSENT		"\026%s@Telegram has sent a location (longitude=%s latitude=%s).\026"
set MSG_TG_VENUESENT		"\026%s@Telegram has sent a venue: location=%s title=%s address=%s foursquare_id=%s.\026"
set MSG_TG_USERADD			"\026%s@Telegram has added %s to the Telegram group.\026"
set MSG_TG_USERLEFT			"\026%s@Telegram has removed %s from the Telegram group.\026"
set MSG_TG_CHATTITLE		"\026%s@Telegram has changed the topic of the Telegram group to %s.\026"
set MSG_TG_PICCHANGE		"\026%s@Telegram has changed the Telegram group picture. Use \026/ctcp %s tgfile %s \026to download the file."
set MSG_TG_PICDELETE		"\026%s@Telegram has removed the Telegram group picture."
set MSG_TG_UNKNOWNSTICKER	"Unknown sticker."
set MSG_TG_UNIMPL			"Unknown Telegram message received."

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
set MSG_BOT_CONNECTED		"Chat group %s (%s) is now connected to %s."
set MSG_BOT_DISCONNECTED	"Chat group %s (%s) is now disconnected from %s."
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
