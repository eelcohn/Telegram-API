# ---------------------------------------------------------------------------- #
# Telegram TCL library v20180126                                               #
# This library has functions for interacting with the Telegram servers         #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

namespace eval libtelegram {
	variable ::libtelegram::bot_id
	variable ::libtelegram::bot_token
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::getUpdates                                                    #
# ---------------------------------------------------------------------------- #
# Receive incoming updates from the Telegram servers                           #
# https://core.telegram.org/bots/api#getUpdates                                #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::getUpdates {offset} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/getUpdates -d offset=$offset]	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using getUpdates method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::setWebHook                                                    #
# ---------------------------------------------------------------------------- #
# Specify a url and receive incoming updates via an outgoing webhook           #
# https://core.telegram.org/bots/api#setwebhook                                #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::setWebHook {url certificate max_connections allowed_updates} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/setWebHook -d url=$url -d certificate=$certificate -d max_connections=$max_connections -d allowed_updates=$allowed_updates]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using setWebHook method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::deleteWebHook                                                 #
# ---------------------------------------------------------------------------- #
# Removes a webhook                                                            #
# https://core.telegram.org/bots/api#deletewebhook                             #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::deleteWebHook {} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/deleteWebHook]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using deleteWebHook method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::getWebHookInfo                                                #
# ---------------------------------------------------------------------------- #
# Returns info on the current webhook                                          #
# https://core.telegram.org/bots/api#getwebhookinfo                            #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::getWebHookInfo {} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/getWebHookInfo]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using getWebHookInfo method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::getMe                                                         #
# ---------------------------------------------------------------------------- #
# Get some basic information about the bot                                     #
# https://core.telegram.org/bots/api#getMe                                     #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::getMe {} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/getMe]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using getMe method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::sendMessage                                                   #
# ---------------------------------------------------------------------------- #
# Sends a message to a chat group in Telegram                                  #
# https://core.telegram.org/bots/api#sendmessage                               #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::sendMessage {chat_id msg_id parse_mode message} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/sendMessage -d disable_web_page_preview=$::telegram::tg_web_page_preview -d chat_id=$chat_id -d parse_mode=$parse_mode -d reply_to_message_id=$msg_id -d text=$message]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using sendMessage reply method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::forwardMessage                                                #
# ---------------------------------------------------------------------------- #
# Forwards a message to a user or a chat group in Telegram                     #
# https://core.telegram.org/bots/api#forwardmessage                            #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::forwardMessage {chat_id from_chat_id disable_notification message_id} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/forwardMessage -d chat_id=$chat_id -d from_chat_id=$from_chat_id -d disable_notification=$disable_notification -d message_id=$message_id]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using forwardMessage reply method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::sendPhoto                                                     #
# ---------------------------------------------------------------------------- #
# sendPhoto: Sends a photo to a chat group in Telegram                         #
# https://core.telegram.org/bots/api#sendphoto                                 #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::sendPhoto {chat_id msg_id photo caption} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/sendPhoto -d chat_id=$chat_id -d reply_to_message_id=$msg_id -d photo=$photo -d caption=$caption]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using sendPhoto method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::sendAudio                                                     #
# ---------------------------------------------------------------------------- #
# sendAudio: Sends a audio file to a chat group in Telegram                    #
# https://core.telegram.org/bots/api#sendaudio                                 #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::sendAudio {chat_id msg_id audio caption} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/sendAudio -d chat_id=$chat_id -d reply_to_message_id=$msg_id -d audio=$audio -d caption=$caption]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using sendAudio method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::sendDocument                                                  #
# ---------------------------------------------------------------------------- #
# sendDocument: Sends a document to a chat group in Telegram                   #
# https://core.telegram.org/bots/api#senddocument                              #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::sendDocument {chat_id msg_id document caption} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/sendDocument -d chat_id=$chat_id -d reply_to_message_id=$msg_id -d document=$document -d caption=$caption]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using sendDocument method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::sendVideo                                                     #
# ---------------------------------------------------------------------------- #
# sendVideo: Sends a video to a chat group in Telegram                         #
# https://core.telegram.org/bots/api#sendvideo                                 #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::sendVideo {chat_id msg_id video caption} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/sendVideo -d chat_id=$chat_id -d reply_to_message_id=$msg_id -d video=$video -d caption=$caption]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using sendVideo method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::sendVoice                                                     #
# ---------------------------------------------------------------------------- #
# sendVoice: Sends a playable voice message to a chat group in Telegram        #
# https://core.telegram.org/bots/api#sendvoice                                 #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::sendVoice {chat_id msg_id voice caption} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/sendVoice -d chat_id=$chat_id -d reply_to_message_id=$msg_id -d voice=$voice -d caption=$caption]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using sendVoice method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::sendVideoNote                                                 #
# ---------------------------------------------------------------------------- #
# sendVideoNote: Sends a video note to a chat group in Telegram                #
# https://core.telegram.org/bots/api#sendvideonote                             #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::sendVideoNote {chat_id msg_id video_note} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/sendVideoNote -d chat_id=$chat_id -d reply_to_message_id=$msg_id -d video_note=$video_note]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using sendVideoNote method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::sendMediaGroup                                                #
# ---------------------------------------------------------------------------- #
# sendMediaGroup: Sends a group of photos or videos as an album                #
# https://core.telegram.org/bots/api#sendmediagroup                            #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::sendMediaGroup {chat_id media disable_notification reply_to_msg_id} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/sendMediaGroup -d chat_id=$chat_id -d disable_notification=$disable_notification -d reply_to_message_id=$reply_to_msg_id]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using sendMediaGroup method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::sendLocation                                                  #
# ---------------------------------------------------------------------------- #
# sendLocation: Sends a location to a chat group in Telegram                   #
# https://core.telegram.org/bots/api#sendlocation                              #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::sendLocation {chat_id msg_id latitude longitude} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/sendLocation -d chat_id=$chat_id -d reply_to_message_id=$msg_id -d latitude=$latitude -d longitude=$longitude]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using sendLocation method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::sendVenue                                                     #
# ---------------------------------------------------------------------------- #
# Sends a venue to a chat group in Telegram                                    #
# https://core.telegram.org/bots/api#sendvenue                                 #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::sendVenue {chat_id msg_id latitude longitude title address} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/sendVenue -d chat_id=$chat_id -d reply_to_message_id=$msg_id -d latitude=$latitude -d longitude=$longitude -d title=$title -d address=$address]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using sendVenue method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::sendContact                                                   #
# ---------------------------------------------------------------------------- #
# Sends a contact to a chat group in Telegram                                  #
# https://core.telegram.org/bots/api#sendcontact                               #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::sendContact {chat_id msg_id phone_number first_name last_name} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/sendContact -d chat_id=$chat_id -d reply_to_message_id=$msg_id -d phone_number=$phone_number -d first_name=$first_name -d last_name=$last_name]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using sendContact method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::sendChatAction                                                #
# ---------------------------------------------------------------------------- #
# Changes the bot's status in Telegram                                         #
# https://core.telegram.org/bots/api#sendChatAction                            #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::sendChatAction {chat_id action} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/sendChatAction -d chat_id=$chat_id -d action=$action]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using sendChatAction method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::getUserProfilePhotos                                          #
# ---------------------------------------------------------------------------- #
# Changes the bot's status in Telegram                                         #
# https://core.telegram.org/bots/api#getuserprofilephotos                      #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::getUserProfilePhotos {user_id offset limit} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/getUserProfilePhotos -d user_id=$user_id -d offset=$offset -d limit=$limit]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using getUserProfilePhotos method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::getFile                                                       #
# ---------------------------------------------------------------------------- #
# Changes the bot's status in Telegram                                         #
# https://core.telegram.org/bots/api#getfile                                   #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::getFile {file_id} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/getFile -d file_id=$file_id]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using getFile method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::kickChatMember                                                #
# ---------------------------------------------------------------------------- #
# Kicks an user from a chat group in Telegram                                  #
# https://core.telegram.org/bots/api#kickchatmember                            #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::kickChatMember {chat_id user_id} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/kickChatMember -d chat_id=$chat_id -d user_id=$user_id]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using kickChatMember method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::setChatPhoto                                                  #
# ---------------------------------------------------------------------------- #
# Sets the channel's profile photo of a chat group in Telegram                 #
# https://core.telegram.org/bots/api#setchatphoto                              #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::setChatPhoto {chat_id photo} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/setChatPhoto -d chat_id=$chat_id -d photo=$photo]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using setChatPhoto method."
		return -1
	}

	if {[jsonGetValue $result "" "ok"] eq "false"} {
		putlog "Telegram-API: bad result from setChatPhoto method: [jsonGetValue $result "" "description"]"
	}

	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::setChatTitle                                                  #
# ---------------------------------------------------------------------------- #
# Sets the channel's profile title of a chat group in Telegram                 #
# https://core.telegram.org/bots/api#setchattitle                              #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::setChatTitle {chat_id title} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/setChatTitle -d chat_id=$chat_id -d title=$title]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using setChatTitle method."
		return -1
	}

	if {[jsonGetValue $result "" "ok"] eq "false"} {
		putlog "Telegram-API: bad result from setChatTitle method: [jsonGetValue $result "" "description"]"
	}

	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::getChat                                                       #
# ---------------------------------------------------------------------------- #
# Get up to date information about the chat group in Telegram                  #
# https://core.telegram.org/bots/api#getchat                                   #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::getChat {chat_id} {

	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/getChat -d chat_id=$chat_id]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using getChat method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::getChatAdministrators                                         #
# ---------------------------------------------------------------------------- #
# Get a list of administrators in a chat group in Telegram                     #
# https://core.telegram.org/bots/api#getchatadministrators                     #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::getChatAdministrators {chat_id} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/getChatAdministrators -d chat_id=$chat_id]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using getChatAdministrators method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::getChatMemberCount                                            #
# ---------------------------------------------------------------------------- #
# Get the number of members in a chat group in Telegram                        #
# https://core.telegram.org/bots/api#getchatmemberscount                       #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::getChatMembersCount {chat_id} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/getChatMembersCount -d chat_id=$chat_id]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using getChatMembersCount method."
		return -1
	}
	return $result
}

# ---------------------------------------------------------------------------- #
# ::libtelegram::getChatMember                                                 #
# ---------------------------------------------------------------------------- #
# Get information about a member of a chat group in Telegram                   #
# https://core.telegram.org/bots/api#getchatmember                             #
# ---------------------------------------------------------------------------- #
proc ::libtelegram::getChatMember {chat_id user_id} {
	if { [ catch {
		set result [exec curl --tlsv1.2 -s -X POST https://api.telegram.org/bot$::libtelegram::bot_id:$::libtelegram::bot_token/getChatMember -d chat_id=$chat_id -d user_id=$user_id]
	} ] } {
		putlog "Telegram-API: cannot connect to api.telegram.com using getChatMember method."
		return -1
	}
	return $result
}
