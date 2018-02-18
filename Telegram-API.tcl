# ---------------------------------------------------------------------------- #
# Telegram-API module v20180218 for Eggdrop                                    #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Global internal variables                                                    #
# ---------------------------------------------------------------------------- #

# Create a namespace for the Telegram-API script
namespace eval ::telegram {}

# Declare global variables and set default values
set		::telegram::tg_poll_freq		5
set		::telegram::tg_web_page_preview		false
set		::telegram::tg_prefer_usernames		true
set		::telegram::locale			"en"
set		::telegram::timeformat			"%Y-%m-%d %H:%M:%S"
set		::telegram::colorize_nicknames		0
set		::telegram::userflags			"jlvck"
set		::telegram::chanflags			"iptmsw"
set		::telegram::cmdmodifier			"/!."

# Declare global internal variables; not user-configurable
set		::telegram::tg_update_id		0
set		::telegram::tg_bot_nickname		""
set		::telegram::tg_bot_realname		""
set 		::telegram::irc_bot_nickname		""
array set	::telegram::tg_chat_title		{}
array set	::telegram::tg_chat_description		{}
array set	::telegram::tg_pinned_messages		{}
array set	::telegram::tg_invite_link		{}
array set	::telegram::public_commands		{}
array set	::telegram::public_commands_help	{}
array set	::telegram::private_commands		{}
array set	::telegram::private_commands_help	{}
array set	::telegram::filetransfers		{}



# ---------------------------------------------------------------------------- #
# Initialization procedures                                                    #
# ---------------------------------------------------------------------------- #
# Initialize some variables (botnames)                                         #
# ---------------------------------------------------------------------------- #
proc ::telegram::initialize {} {
	global nick

	# Get some basic info about the Telegram bot
	if {[::libtelegram::getMe] ne 0} {
		putlog $::libtelegram::errorMessage
		utimer $::telegram::tg_poll_freq ::telegram::initialize
		return $::libtelegram::errorNumber
	}

	# Get the Telegram bot's nickname and realname
	set ::telegram::tg_bot_nickname [::libjson::getValue $::libtelegram::result ".result.username"]
	set ::telegram::tg_bot_realname [concat [::libjson::getValue $::libtelegram::result ".result.first_name//empty"] [::libjson::getValue $::libtelegram::result ".result.last_name//empty"]]
	set ::telegram::irc_bot_nickname "$nick"

	# Get up to date information on all Telegram groups/supergroups/channels
	foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
		# Chat titles: Only get chat titles and descriptions for (super)groups we haven't queried yet
		if {![info exists ::telegram::tg_chat_title($tg_chat_id)]} {
			if {[::libtelegram::getChat $tg_chat_id] ne 0} {
				putlog $::libtelegram::errorMessage
#				return $::libtelegram::errorNumber
			}
			set ::telegram::tg_chat_type($tg_chat_id) [::libunicode::utf82ascii [::libjson::getValue $::libtelegram::result ".result.type"]]
			set ::telegram::tg_chat_title($tg_chat_id) [::libunicode::utf82ascii [::libjson::getValue $::libtelegram::result ".result.title//empty"]]
			set ::telegram::tg_chat_description($tg_chat_id) [::libjson::getValue $::libtelegram::result ".result.description//empty"]
			set ::telegram::tg_chat_photo($tg_chat_id) [::libjson::getValue $::libtelegram::result ".result.photo.big_file_id//empty"]
		}

		# Pinned messages: Only get pinned messages for (super)groups we haven't queried yet
		if {![info exists ::telegram::tg_pinned_messages($tg_chat_id)]} {
			if {[set chattype [::libjson::getValue $::libtelegram::result ".result.pinned_message.chat.type"]] ne "null"} {
				set ::telegram::tg_pinned_messages($tg_chat_id) [::telegram::getPinnedMessage $chattype [::libjson::getValue $::libtelegram::result ".result.pinned_message"]]
				if {$::telegram::tg_pinned_messages($tg_chat_id) eq ""} {
					unset -nocomplain ::telegram::tg_pinned_messages($tg_chat_id)
				}
			}
		}

		# Invite links: Only get invite links for supergroups and channels we haven't queried yet
		if {![info exists ::telegram::tg_invite_link($tg_chat_id)]} {
			# Check if an invite link is already available in the chat object
			if {[set ::telegram::tg_invite_link($tg_chat_id) [::libjson::getValue $::libtelegram::result ".result.invite_link//empty"]] eq ""} {
				# If not, then create a new one (for supergroups and channels only)
				if {$::telegram::tg_chat_type($tg_chat_id) != "group"} {
					if {[::libtelegram::exportChatInviteLink $tg_chat_id] ne 0} {
						putlog $::libtelegram::errorMessage
					}
					set ::telegram::tg_invite_link($tg_chat_id) [::libjson::getValue $::libtelegram::result ".result//empty"]
				}
				if {$::telegram::tg_invite_link($tg_chat_id) eq ""} {
					unset -nocomplain ::telegram::tg_invite_link($tg_chat_id)
				}
			}
		}
	}
	return 0
}



# ---------------------------------------------------------------------------- #
# Procedures for reading data from the Telegram servers                        #
# ---------------------------------------------------------------------------- #
# Poll the Telegram server for updates                                         #
# ---------------------------------------------------------------------------- #
proc ::telegram::pollTelegram {} {
	# Check if the bot has already joined a channel
	if { [botonchan] != 1 } {
		# Eggdrop hasn't joined all channels yet, so don't start polling Telegram yet
		putlog "Telegram-API: Not connected to IRC, skipping"
		utimer $::telegram::tg_poll_freq ::telegram::pollTelegram
		return -1
	}

	# Poll the Telegram API for updates and check if we got a result
	if {[::libtelegram::getUpdates $::telegram::tg_update_id] ne 0} {
		# Network is probably down, so schedule the next poll
		putlog $::libtelegram::errorMessage
		if {[::libjson::getValue $::libtelegram::result ".parameters"] ne "null"} {
			if {[::libjson::getValue $::libtelegram::result ".parameters.migrate_to_chat_id"] ne "null"} {
				# A chat group has been migrated to a supergroup, but the conf file still got the chat_id for the old group
				putlog "Telegram-API: Please edit your conf file with your new chat_id: [::libjson::getValue $::libtelegram::result ".parameters.migrate_to_chat_id"]"
			} else {
				putlog "Telegram-API: [::libjson::getValue $::libtelegram::result ".parameters"]"
			}
		}
		utimer $::telegram::tg_poll_freq ::telegram::pollTelegram
 		return $::libtelegram::errorNumber
	}

	# Cycle through each status update
	foreach msg [split [::libjson::getValue $::libtelegram::result ".result\[\]"] "\n"] {
		set ::telegram::tg_update_id [::libjson::getValue $msg ".update_id"]
#		set msgtype [::libjson::getValue $msg ". | keys\[\] | select(. != \"update_id\")"]
		set msgtype [::libjson::getValue $msg "keys_unsorted\[1\]"]
		set chattype [::libjson::getValue $msg ".$msgtype.chat.type"]

 		switch $chattype {
			"private" {
				# Record is a private chat record
				if {[::libjson::hasKey $msg ".message.text"]} {
					set txt [::libunicode::utf82ascii [::libjson::getValue $msg ".message.text"]]
					set msgid [::libjson::getValue $msg ".message.message_id"]
					set fromid [::libjson::getValue $msg ".message.from.id"]

					::telegram::privateCommand "$fromid" "$msgid" "$txt"
				}
			}

			"group" -
			"supergroup" -
			"channel" {
				# Record is a group, supergroup or channel record
				set chatid [::libjson::getValue $msg ".$msgtype.chat.id"]

				# Get the sender's name for this message
				if {$chattype eq "channel"} {
					set name [::telegram::getUsername [::libjson::getValue $msg ".channel_post.chat"]]
					set from_id [::libjson::getValue $msg ".channel_post.chat.id"]
				} else {
					set name [::telegram::getUsername [::libjson::getValue $msg ".$msgtype.from"]]
					set from_id [::libjson::getValue $msg ".$msgtype.from.id"]
				}

				# Get the caption of this message (if any)
				if {[::libjson::hasKey $msg ".$msgtype.caption"]} {
					set caption " ([::libunicode::utf82ascii [::libjson::getValue $msg ".$msgtype.caption//empty"]])"
				} else {
					set caption ""
				}

				# Get the reply-to name for this message (if available)
				if {[::libjson::hasKey $msg ".$msgtype.reply_to_message"]} {
					set replyname [::telegram::getUsername [::libjson::getValue $msg ".$msgtype.reply_to_message.from"]]
				}

				# Check if this message is a forwarded message
				if {[::libjson::hasKey $msg ".$msgtype.forward_from"]} {
					set forwardname [::telegram::getUsername [::libjson::getValue $msg ".$msgtype.forward_from"]]
				}

				# Check if this message is a forwarded channelmessage
				if {[::libjson::hasKey $msg ".$msgtype.forward_from_chat"]} {
					set forwardname [::telegram::getUsername [::libjson::getValue $msg ".$msgtype.forward_from_chat"]]
				}

				# Check if a text message has been sent to the Telegram group
				if {[set txt [::libjson::getValue $msg ".$msgtype.text"]] ne "null"} {
					# Modify text if it is a reply-to or forwarded from
					if {[info exists replyname]} {
						set replytomsg [::libjson::getValue $msg ".$msgtype.reply_to_message.text"]
						set txt "[::msgcat::mc MSG_TG_MSGREPLYTOSENT "$txt" "$replyname" "$replytomsg"]"
					} elseif {[info exists forwardname]} {
						set txt "[::msgcat::mc MSG_TG_MSGFORWARDED "$txt" "$forwardname"]"
					} 

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						# Send the text message if it matches
						if {$chatid eq $tg_chat_id} {
							# Treat each line seperate
							foreach line [split [string map {\\n \n} [::libunicode::utf82ascii $txt]] "\n"] {
								putchan $irc_channel [::msgcat::mc MSG_TG_MSGSENT "$name" "$line"]
		
								# If the line contains an URL, get the title of the website
								if {[string match -nocase "*http://?*" $line] || [string match -nocase "*https://?*" $line] || [string match -nocase "*www.?*" $line]} {
									putchan $irc_channel [::telegram::getWebsiteTitle $line]
								}
							}
		
							# Check if it was a public bot command
							if {[string match "*\\[string index $txt 0]*" "$::telegram::cmdmodifier"]} {
								set msgid [::libjson::getValue $msg ".$msgtype.message_id"]
								::telegram::publicCommand $from_id "$tg_chat_id" "$msgid" "$irc_channel" "$txt"
							}
						}
					}
				}

				# Check if this message is a pinned message
				if {[::libjson::hasKey $msg ".$msgtype.pinned_message"]} {
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							set ::telegram::tg_pinned_messages($chatid) [::telegram::getPinnedMessage $chattype [::libjson::getValue $msg ".$msgtype.pinned_message"]]
							putchan $irc_channel [::msgcat::mc MSG_TG_MSGSENT "$name" "$::telegram::tg_pinned_messages($chatid)"]
						}
					}
				}

				# Check if a sticker has been sent to the Telegram group
				if {[set file_id [::libjson::getValue $msg ".$msgtype.sticker.file_id"]] ne "null"} {
					set setname [::libjson::getValue $msg ".$msgtype.sticker.set_name"]
					set emoji [::libjson::getValue $msg ".$msgtype.sticker.emoji"]

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_STICKERSENT "$name" "$setname" "[sticker2ascii $file_id]"]
						}
					}
				}

				# Check if audio has been sent to the Telegram group
				if {[set tg_file_id [::libjson::getValue $msg ".$msgtype.audio.file_id"]] ne "null"} {
					set tg_performer [::libjson::getValue $msg ".$msgtype.audio.performer"]
					set tg_title [::libjson::getValue $msg ".$msgtype.audio.title"]
					if {[set tg_duration [::libjson::getValue $msg ".$msgtype.audio.duration"]] eq ""} {
						set tg_duration "0"
					}

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_AUDIOSENT "$name" "$tg_performer" "$tg_title" "[expr {$tg_duration/60}]:[expr {$tg_duration%60}]" "$tg_file_id"]
						}
					}
				}

				# Check if a document has been sent to the Telegram group
				if {[set tg_file_id [::libjson::getValue $msg  ".$msgtype.document.file_id"]] ne "null"} {
					set tg_file_name [::libjson::getValue $msg ".$msgtype.document.file_name"]
					set tg_file_size [::libjson::getValue $msg ".$msgtype.document.file_size"]

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_DOCSENT "$name" "$caption" "$tg_file_name" "$tg_file_size" "$tg_file_id"]
						}
					}
				}

				# Check if a photo has been sent to the Telegram group
				if {[set tg_file_id [::libjson::getValue $msg ".$msgtype.photo\[-1\].file_id"]] ne "null"} {
					set tg_file_size [::libjson::getValue $msg ".$msgtype.photo\[-1\].file_size"]

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_PHOTOSENT "$name" "$caption" "$tg_file_size" "$tg_file_id"]
						}
					}
				}

				# Check if a video has been sent to the Telegram group
				if {[set tg_file_id [::libjson::getValue $msg ".$msgtype.video.file_id"]] ne "null"} {
					if {[set tg_duration [::libjson::getValue $msg ".$msgtype.video.duration"]] eq "null"} {
						set tg_duration "0"
					}

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_VIDEOSENT "$name" "$caption" "[expr {$tg_duration/60}]:[expr {$tg_duration%60}]" "$tg_file_id"]
						}
					}
				}

				# Check if a voice object has been sent to the Telegram group
				if {[set tg_file_id [::libjson::getValue $msg ".$msgtype.voice.file_id"]] ne "null"} {
					set tg_file_size [::libjson::getValue $msg ".$msgtype.voice.file_size"]
					if {[set tg_duration [::libjson::getValue $msg ".$msgtype.voice.duration"]] eq ""} {
						set tg_duration "0"
					}

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_VOICESENT "$name" "[expr {$tg_duration/60}]:[expr {$tg_duration%60}]" "$tg_file_size" "$tg_file_id"]
						}
					}
				}

				# Check if a contact has been sent to the Telegram group
				if {[set tg_phone_number [::libjson::getValue $msg ".$msgtype.contact.phone_number"]] ne "null"} {
					set tg_first_name [::libjson::getValue $msg ".$msgtype.contact.first_name//empty"]
					set tg_last_name [::libjson::getValue $msg ".$msgtype.contact.last_name//empty"]

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_CONTACTSENT "$name" "+$tg_phone_number" "$tg_first_name" "$tg_last_name"]
						}
					}
				}

				# Check if a location has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.location"]} {
					# Check if a venue has been sent to the Telegram group
					if {[set tg_location [::libjson::getValue $msg ".$msgtype.venue.location"]] ne "null"} {
						set tg_title [::libjson::getValue $msg ".$msgtype.venue.title"]
						set tg_address [::libjson::getValue $msg ".$msgtype.venue.address"]
						set tg_foursquare_id [::libjson::getValue $msg ".$msgtype.venue.foursquare_id"]

						# Scan all IRC channels to check if it's connected to this Telegram group
						foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
							if {$chatid eq $tg_chat_id} {
								putchan $irc_channel [::msgcat::mc MSG_TG_VENUESENT "$name" "$tg_location" "$tg_title" "$tg_address" "$tg_foursquare_id"]
							}
						}
					} else {
						# Not a venue, so it must be a location
						set tg_longitude [::libjson::getValue $msg ".$msgtype.location.longitude"]
						set tg_latitude [::libjson::getValue $msg ".$msgtype.location.latitude"]

						# Scan all IRC channels to check if it's connected to this Telegram group
						foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
							if {$chatid eq $tg_chat_id} {
								putchan $irc_channel [::msgcat::mc MSG_TG_LOCATIONSENT "$name" "$tg_longitude" "$tg_latitude"]
							}
						}
					}
				}

				# Check if someone has been added to the Telegram group
				if {[set new_member_id [::libjson::getValue $msg ".$msgtype.new_chat_member.id"]] ne "null"} {
					set new_chat_member [::telegram::getUsername [::libjson::getValue $msg ".$msgtype.new_chat_member"]]

					# Check if we want to send a public welcome message to the new participant
					if {[string match "*w*" $::telegram::chanflags]} {
						::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_TG_WELCOME "$::telegram::tg_chat_title($chat_id)" "$::telegram::tg_bot_nickname" "$serveraddress/$channel" "$channel"]
					}

					# Check if we want to send a private welcome message to the new participant
					if {[string match "*W*" $::telegram::chanflags]} {
						::libtelegram::sendMessage $new_member_id "" "html" [::msgcat::mc MSG_TG_WELCOME "$::telegram::tg_chat_title($chat_id)" "$::telegram::tg_bot_nickname" "$serveraddress/$channel" "$channel"]
					}

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							if {$name eq $new_chat_member} {
								putchan $irc_channel [::msgcat::mc MSG_TG_USERJOINED "[::libunicode::utf82ascii $name]"]
							} else {
								putchan $irc_channel [::msgcat::mc MSG_TG_USERADD "[::libunicode::utf82ascii $name]" "[::libunicode::utf82ascii $new_chat_member]"]
							}
						}
					}
				}

				# Check if someone has been removed from the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.left_chat_member"]} {
					set left_chat_member [::telegram::getUsername [::libjson::getValue $msg ".$msgtype.left_chat_member"]]

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							if {$name eq $left_chat_member} {
								putchan $irc_channel [::msgcat::mc MSG_TG_USERLEFT "[::libunicode::utf82ascii $name]"]
							} else {
								putchan $irc_channel [::msgcat::mc MSG_TG_USERREMOVED "[::libunicode::utf82ascii $name]" "[::libunicode::utf82ascii $left_chat_member]"]
							}
						}
					}
				}

				# Check if the title of the Telegram group chat has changed
				if {[set chat_title [::libjson::getValue $msg ".$msgtype.new_chat_title"]] ne "null"} {
					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							set ::telegram::tg_chat_title($tg_chat_id) [::libunicode::utf82ascii $chat_title]
							putchan $irc_channel [::msgcat::mc MSG_TG_TITLECHANGE "[::libunicode::utf82ascii $name]" "$::telegram::tg_chat_title($tg_chat_id)"]
						}
					}
				}

				# Check if the photo of the Telegram group chat has changed
				if {[set file_id [::libjson::getValue $msg ".$msgtype.new_chat_photo\[-1\].file_id"]] ne "null"} {
					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_PICCHANGE "[::libunicode::utf82ascii $name]" "$file_id"]
						}
					}
				}

				# Check if the photo of the Telegram group chat has been deleted
				if {[::libjson::hasKey $msg ".$msgtype.delete_chat_photo"]} {
					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_PICDELETE "[::libunicode::utf82ascii $name]"]
						}
					}
				}

				# Check if the group is migrated to a supergroup
				if {[set newchatid [::libjson::getValue $msg ".$msgtype.migrate_to_chat_id"]] ne "null"} {
					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_GROUPMIGRATED "[::libunicode::utf82ascii $name] $chatid $newchatid"]
							putlog "Telegam-API: The group with id $chatid has been migrated to a supergroup by $name. Please edit your config file and add \{$newchatid $irc_channel\}"
						}
					}
				}
			}

			default {
				# Handle any unknown messages
				putlog "Unknown message received: $msg"
			}
		}
		incr ::telegram::tg_update_id
	}

	# ...and set a timer so it triggers the next poll
	utimer $::telegram::tg_poll_freq ::telegram::pollTelegram

	return 0
}

# ---------------------------------------------------------------------------- #
# Respond to group commands send by Telegram users                             #
# ---------------------------------------------------------------------------- #
proc ::telegram::publicCommand {from_id chat_id msgid channel message} {
	global serveraddress

	# Don't process single character commands
	if {[set parameter_start [string wordend $message 1]] == 1} {
		return 0
	}

	# Only process is command is in range a...z
	if {![string is alpha [set command [string tolower [string range $message 1 $parameter_start-1]]]]} {
		return 0
	}

	# Check if this command has a bot identifier in it (/command@BotIdentifier)
	if {[string match -nocase "@*" [string range $message $parameter_start end]]} {
		# If so, then check if the identifier matches our bot
		if {![string match -nocase "@$::telegram::tg_bot_realname*" [string range $message $parameter_start end]]} {
			# If not, then stop processing the command
			return 0
		} else {
			set parameter_start [string wordend $message $parameter_start+1]
		}
	}

	# Let the Telegram users know that we've received the bot command, and we're preparing an answer
	::libtelegram::sendChatAction $chat_id "typing"

	if {$command eq "help"} {
		set response "[::msgcat::mc MSG_BOT_PUBHELP "$::telegram::irc_bot_nickname"]\n\n"
		foreach {command helpmessage} [lsort -stride 2 [array get ::telegram::public_commands_help]] {
			append response "/$command $helpmessage\n"
		}
		::libtelegram::sendMessage $chat_id $msgid "html" "[url_encode $response]"
		putchan $channel "[strip_html $response]"
	} else {
		# Not one of the standard bot commands, so check if the bot command is in our dynamic command list
		foreach {cmd prc} [array get ::telegram::public_commands] {
			if {$command == $cmd} {
				if {[$prc $from_id $chat_id $msgid $channel $message $parameter_start] ne 0} {
					# The module returned an error, so show the help message for the specified command
					set response "/$command $::telegram::public_commands_help($command)"
					::libtelegram::sendMessage $chat_id $msgid "html" "[url_encode $response]"
					putchan $channel "[strip_html $response]"
				}	
				return 0
			}
		}

		# Not in our dynamic command list either, so respond with an unknown command message
		::libtelegram::sendMessage $chat_id $msgid "html" "[::msgcat::mc MSG_BOT_UNKNOWNCMD]"
		putchan $channel "[::msgcat::mc MSG_BOT_UNKNOWNCMD]"
		return -1
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Add a bot command to the dynamic bot command list                            #
# ---------------------------------------------------------------------------- #
proc ::telegram::addPublicCommand {keyword procedure helpmessage} {
	set ::telegram::public_commands($keyword) $procedure
	set ::telegram::public_commands_help($keyword) $helpmessage
}

# ---------------------------------------------------------------------------- #
# Remove a bot command from the dynamic bot command list                       #
# ---------------------------------------------------------------------------- #
proc ::telegram::delPublicCommand {keyword} {
	if {[info exists ::telegram::public_commands($keyword)]} {
		unset -nocomplain ::telegram::public_commands($keyword)
		unset -nocomplain ::telegram::public_commands_help($keyword)
		return true
	} else {
		return false
	}
}

# ---------------------------------------------------------------------------- #
# Respond to private commands send by Telegram users                           #
# ---------------------------------------------------------------------------- #
proc ::telegram::privateCommand {from_id msgid message} {
	set parameter_start [string wordend $message 1]
	set command [string tolower [string range $message 1 $parameter_start-1]]

	::libtelegram::sendChatAction $from_id "typing"

	switch $command {
		"help" {
			set response "[::msgcat::mc MSG_BOT_PRVHELP "$::telegram::irc_bot_nickname"]\n\n"
			foreach {command helpmessage} [lsort -stride 2 [array get ::telegram::private_commands_help]] {
				append response "/$command $helpmessage\n"
			}
			::libtelegram::sendMessage $from_id $msgid "html" "[url_encode $response]"
		}

		"login" {
			set login_start [string wordend $message 1]
			set login_end [string wordend $message $login_start+1]

			set irchandle [string trim [string range $message $login_start $login_end]]
			set ircpassword [string trim [string range $message $login_end end]]

			# Set the password if this is the first time this user logs in
#			if {[getuser $irchandle PASS] == ""} {
#				setuser $irchandle PASS "$ircpassword"
#				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_PASSWORDSET "$::telegram::tg_bot_nickname"]"
#			}

			# Check if the password matches
			if {[passwdok $irchandle $ircpassword]} {
				setuser $irchandle XTRA "TELEGRAM_USERID" "[string range $from_id 0 12]"
#				setuser $irchandle XTRA "IRL" "[string range $first_name 0 159] [string range $last_name 0 159]"

				# Lookup the last login time
				if {[set lastlogin [getuser $irchandle XTRA "TELEGRAM_LASTLOGIN"]] == ""} {
					# First login of this user, so set LASTLOGOUT and LASTUSERID to defaults
					set lastlogin "[::msgcat::mc MSG_BOT_FIRSTLOGIN "$::telegram::tg_bot_nickname"]"
					setuser $irchandle XTRA "TELEGRAM_LASTLOGOUT" "0"
					setuser $irchandle XTRA "TELEGRAM_LASTUSERID" "0"
				} else {
					# Prepare string with last login time
					set lastlogin "[::msgcat::mc MSG_BOT_LASTLOGIN "$::telegram::tg_bot_nickname" "[clock format $lastlogin -format $::telegram::timeformat]"]"
				}

				# ...and set the last login time to the current time
				setuser $irchandle XTRA "TELEGRAM_LASTLOGIN" "[clock seconds]"

				# Set the Telegram account creation date if this is the first time the user logs in
				if {[getuser $irchandle XTRA "TELEGRAM_CREATED"] == ""} {
					setuser $irchandle XTRA "TELEGRAM_CREATED" "[clock seconds]"
				}

				# Set the userflags to the default settings
				if {[getuser $irchandle XTRA "TELEGRAM_USERFLAGS"] == ""} {
					setuser $irchandle XTRA "TELEGRAM_USERFLAGS" "$::telegram::userflags"
				}

				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_USERLOGIN "$::telegram::tg_bot_nickname" "$irchandle"]\n\n $lastlogin"
				putlog "Telegram-API: Succesful login from $from_id, username $irchandle"
			} else {
				# Username/password combo doesn't match
				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_USERPASSWRONG]"
				putlog "Telegram-API: Failed login attempt from $from_id, username $irchandle"
			}
		}

		"logout" {
			if {[set irchandle [::telegram::getIRCNickFromTelegramID $from_id]] != -1} {
				setuser $irchandle XTRA "TELEGRAM_USERID" ""
				setuser $irchandle XTRA "TELEGRAM_LASTUSERID" "$from_id"
				setuser $irchandle XTRA "TELEGRAM_LASTLOGOUT" "[clock seconds]"
				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_USERLOGOUT "$irchandle" "$from_id"]"
				putlog "Telegram-API: Succesful logout from $from_id, username $irchandle"
			} else {
				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_NOTLOGGEDIN]"
			}
		}

		# Show user information
		"myinfo" {
			if {[set irchandle [::telegram::getIRCNickFromTelegramID $from_id]] != -1} {
				set tg_lastlogin [clock format [getuser $irchandle XTRA "TELEGRAM_LASTLOGIN"] -format $::telegram::timeformat]
				set tg_lastlogout [clock format [getuser $irchandle XTRA "TELEGRAM_LASTLOGOUT"] -format $::telegram::timeformat]
				set tg_lastuserid [getuser $irchandle XTRA "TELEGRAM_LASTUSERID"]
				set tg_created [clock format [getuser $irchandle XTRA "TELEGRAM_CREATED"] -format $::telegram::timeformat]
				set tg_userflags [getuser $irchandle XTRA "TELEGRAM_USERFLAGS"]
				set irc_created [clock format [getuser $irchandle XTRA "created"] -format $::telegram::timeformat]
				set irc_laston [clock format [lindex [split [getuser $irchandle LASTON] " "] 0] -format $::telegram::timeformat]
				set irc_hosts [getuser $irchandle HOSTS]
				set irc_info [getuser $irchandle INFO]
				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_USERINFO "$irchandle" "$from_id" "$tg_lastlogin" "$tg_lastlogout" "$tg_lastuserid" "$tg_created" "$irc_created" "$irc_laston" "irc_hosts" "$irc_info"]"
				putlog "Telegram-API: My information accessed by $from_id, username $irchandle"
			} else {
				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_NOTLOGGEDIN]"
			}
		}

		default {
			# Not one of the standard bot commands, so check if the bot command is in our dynamic command list
			foreach {cmd prc} [array get ::telegram::private_commands] {
				if {$command == $cmd} {
					$prc $chat_id $msgid $channel $message $parameter_start
					return
				}
			}

			# Not in our dynamic command list either, so respond with an unknown command message
			::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_UNKNOWNCMD]"
		}
	}
}

# ---------------------------------------------------------------------------- #
# Add a bot command to the dynamic bot command list                            #
# ---------------------------------------------------------------------------- #
proc ::telegram::addPrivateCommand {keyword procedure helpmessage} {
	set ::telegram::private_commands($keyword) $procedure
	set ::telegram::private_commands_help($keyword) $procedure
}

# ---------------------------------------------------------------------------- #
# Remove a bot command from the dynamic bot command list                       #
# ---------------------------------------------------------------------------- #
proc ::telegram::delPrivateCommand {keyword} {
	if {[info exists ::telegram::private_commands($keyword)]} {
		unset -nocomplain ::telegram::private_commands($keyword)
		unset -nocomplain ::telegram::private_commands_help($keyword)
		return true
	} else {
		return false
	}
}

# ---------------------------------------------------------------------------- #
# Format the pinned message to a message readable by IRC users                 #
# ---------------------------------------------------------------------------- #
proc ::telegram::getPinnedMessage {chattype pinned_message} {
	# Get the name of the Telegram user who wrote the message
	if {$chattype eq "channel"} {
		set pin_name [::libunicode::utf82ascii [::libjson::getValue $pinned_message ".chat.username"]]
	} else {
		set pin_name [::telegram::getUsername [::libjson::getValue $pinned_message ".from"]]
	}

	set pin_date "[clock format [::libjson::getValue $pinned_message ".date"] -format $::telegram::timeformat]"
	set pin_txt "[::libunicode::utf82ascii [::libjson::getValue $pinned_message ".text"]]"

	return [::msgcat::mc MSG_TG_PINNEDMESSAGE "$pin_name" "$pin_txt" "$pin_date"]
}

# ---------------------------------------------------------------------------- #
# Get the username or realname for a Telegram user object                      #
# ---------------------------------------------------------------------------- #
proc ::telegram::getUsername {userobject} {
	# Set sender's name for group or supergroup messages
	if {$::telegram::tg_prefer_usernames} {
		if {[set name [::libjson::getValue $userobject ".username"]] == "null"} {
			set name [concat [::libjson::getValue $userobject ".first_name//empty"] [::libjson::getValue $userobject ".last_name//empty"]]
		}
	} else {
		set name [concat [::libjson::getValue $userobject ".first_name//empty"] [::libjson::getValue $userobject ".last_name//empty"]]
	}
	set name "\003[::telegram::getColorFromUserID [::libjson::getValue $userobject ".id"]][::libunicode::utf82ascii $name]\003"

	return $name
}



# ---------------------------------------------------------------------------- #
# Procedures for sending data from IRC to Telegram                             #
# ---------------------------------------------------------------------------- #
# Send a message from IRC to Telegram                                          #
# ---------------------------------------------------------------------------- #
proc ::telegram::ircSendMessage {nick hostmask handle channel msg} {
	# Check if this is a bot command
	if {[string match "*\\[string index $msg 0]*" "$::telegram::cmdmodifier"]} {
		# If so, then check which bot command it is, and process it. Don't send it to the Telegram group though.
		set parameter_start [string wordend $msg 1]
		set command [string tolower [string range $msg 1 $parameter_start-1]]
		if {[string match $command "tgadmins"]} {
			::telegram::tgAdminsInfo $channel $nick [string trim [string range $msg $parameter_start end]]
			return 0
		}
		if {[string match $command "tgfile"]} {
			::telegram::ircSendFile $nick [string trim [string range $msg $parameter_start end]]
			return 0
		}
		if {[string match $command "tginfo"]} {
			::telegram::tgInfo $channel $nick [string trim [string range $msg $parameter_start end]]
			return 0
		}
		if {[string match $command "tgwhois"]} {
			::telegram::tgWhoIs $channel $nick [string trim [string range $msg $parameter_start end]]
			return 0
		}
	}

	# Only send a message to the Telegram group if the 'voice'-flag is set in the user flags variable
	if {[string match "*v*" $::telegram::userflags]} {
		foreach {chat_id tg_channel} [array get ::telegram::tg_channels] {
			if {$channel eq $tg_channel} {
				::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_MSGSENT "$nick" "[url_encode [::libunicode::ascii2utf8 $msg]]"]
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that someone joined an IRC channel              #
# ---------------------------------------------------------------------------- #
proc ::telegram::ircNickJoined {nick uhost handle channel} {
	global serveraddress

	# Show the invite link for all Telegram groups connected to this IRC channel
	foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
		if {$channel eq $irc_channel} {
			# Check if we want to show a pinned message on this IRC channel
			if {[string match "*p*" $::telegram::chanflags]} {
				# Show pinned messages (if any) as a notice to the new user on IRC
				if {[info exists ::telegram::tg_pinned_messages($tg_chat_id)]} {
					puthelp "NOTICE $channel :$::telegram::tg_pinned_messages($tg_chat_id)"
				}
			}

			# Check if we want to show an invite link on this IRC channel
			if {[string match "*i*" $::telegram::chanflags]} {
				# Show the Telegram chat invite link
				if {[info exists ::telegram::tg_invite_link($tg_chat_id)]} {
					puthelp "NOTICE $channel :[::msgcat::mc MSG_IRC_INVITELINK $::telegram::tg_chat_type($tg_chat_id) $::telegram::tg_chat_title($tg_chat_id) $::telegram::tg_invite_link($tg_chat_id)]"
				}
			}
		}
	}

	# Don't notify the Telegram users when the bot joins an IRC channel
	if {$nick ne $::telegram::irc_bot_nickname} {
		foreach {chat_id tg_channel} [array get ::telegram::tg_channels] {
			if {$channel eq $tg_channel} {
				# Only send a join message to the Telegram group if the 'join'-flag is set in the user flags variable
				if {[string match "*j*" [::telegram::getUserFlags $handle]]} {
#					if {![validuser $handle]} {
#						putlog "$nick $handle joined with hostmask $uhost as an invalid user"
#						::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_NICKJOINED "$nick" "$serveraddress/$channel" "$channel"]
#					} else {
						putlog "$nick $handle joined with hostmask $uhost as an valid user"
#					}
				}
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that someone has left an IRC channel            #
# ---------------------------------------------------------------------------- #
proc ::telegram::ircNickLeft {nick uhost handle channel message} {
	global  serveraddress

	# Don't notify the Telegram users when the bot leaves an IRC channel
	if {$nick ne $::telegram::irc_bot_nickname} {
		foreach {chat_id tg_channel} [array get ::telegram::tg_channels] {
			if {$channel eq $tg_channel} {
				# Only send a leave message to the Telegram group if the 'leave'-flag is set in the user flags variable
				if {[string match "*l*" [::telegram::getUserFlags $handle]]} {
#					if {![validuser $handle]} {
#						::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_NICKLEFT "$nick" "$serveraddress/$channel" "$channel" "$message"]
						putlog "$nick $handle left with hostmask $uhost as an valid user"
#					}
				}
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Send an action from an IRC user to Telegram                                  #
# ---------------------------------------------------------------------------- #
proc ::telegram::ircNickAction {nick uhost handle channel keyword message} {
	# Only send an action message to the Telegram group if the 'voice'-flag is set in the user flags variable
	if {[string match "*v*" $::telegram::userflags]} {
		foreach {chat_id tg_channel} [array get ::telegram::tg_channels] {
			if {$channel eq $tg_channel} {
				::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_NICKACTION "$nick" "$nick" "$message"]
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that an IRC nickname has been changed           #
# ---------------------------------------------------------------------------- #
proc ::telegram::ircNickChange {nick uhost handle channel newnick} {
	# Only send a nick change message to the Telegram group if the 'change'-flag is set in the user flags variable
	if {[string match "*c*" $::telegram::userflags]} {
		foreach {chat_id tg_channel} [array get ::telegram::tg_channels] {
			if {$channel eq $tg_channel} {
				::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_NICKCHANGE "$nick" "$newnick"]
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that the topic of an IRC channel has changed    #
# ---------------------------------------------------------------------------- #
proc ::telegram::ircTopicChange {nick uhost handle channel topic} {
	global serveraddress

	if {[string match "*t*" $::telegram::chanflags]} {
		foreach {chat_id tg_channel} [array get ::telegram::tg_channels] {
			if {$channel eq $tg_channel} {
				if {$nick ne "*"} {
					::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_TOPICCHANGE "$nick" "$serveraddress/$channel" "$channel" "$topic"]
					if {[string match "*s*" $::telegram::chanflags]} {
						::libtelegram::setChatTitle $chat_id $topic
					}
				}
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that someone has been kicked from the channel   #
# ---------------------------------------------------------------------------- #
proc ::telegram::ircNickKicked {nick uhost handle channel target reason} {
	# Only send a kick message to the Telegram group if the 'kick'-flag is set in the user flags variable
	if {[string match "*k*" $::telegram::userflags]} {
		foreach {chat_id tg_channel} [array get ::telegram::tg_channels] {
			if {$channel eq $tg_channel} {
				::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_KICK "$nick" "$target" "$channel" "$reason"]
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that a channel's mode has changed               #
# ---------------------------------------------------------------------------- #
proc ::telegram::ircModeChange {nick uhost hand channel mode target} {
	if {$target == ""} {
		# Mode change target was a channel
		if {[string match "*m*" $::telegram::chanflags]} {
			foreach {chat_id tg_channel} [array get ::telegram::tg_channels] {
				if {$channel eq $tg_channel} {
					::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_MODECHANGE "$nick" "$channel" "$mode"]
				}
			}
		}
	} else {
		# Mode change target was an user
		if {[string match "*m*" $::telegram::userflags]} {
			foreach {chat_id tg_channel} [array get ::telegram::tg_channels] {
				if {$channel eq $tg_channel} {
					::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_MODECHANGE "$nick" "$channel" "$mode"]
				}
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Download a Telegram attachment and send it via DCC to an IRC user            #
# ---------------------------------------------------------------------------- #
proc ::telegram::ircSendFile {nick file_id} {
	global xfer-timeout

	set max_file_size 20480000
	set timeout [expr ${xfer-timeout} + 1]

#	if {[regexp {"/[^A-Za-z0-9\-_]/"} $file_id]} {
		if {[::libtelegram::getFile $file_id] ne 0} {
			set file_path [::libjson::getValue $::libtelegram::result ".result.file_path"]
			set file_size [::libjson::getValue $::libtelegram::result ".result.file_size"]

			if {$file_size > $max_file_size} {
				putlog "irc2tg_sendFile: file $file_id too big ($file_size)"
				puthelp "NOTICE $nick :[::msgcat::mc MSG_IRC_DCCSENDFAILED]"
				return -1
			} else {
				set filename [file tail $file_path]
				set fullname [file join /tmp $filename]
				if {[::libtelegram::downloadFile $file_path $fullname] eq 0} {
					if {[file exists $fullname]} {
						# To prevent our temp folder filling up with downloaded Telegram files, we'll set a timeout on the filetransfer
						set ::telegram::filetransfers($fullname) [expr [clock seconds] + $timeout]
						utimer $timeout ::telegram::cleanUpFiles

						switch -- [dccsend $fullname $nick] {
							0 {
								puthelp "NOTICE $nick :[::msgcat::mc MSG_IRC_DCCSENDFILE $filename]"
							}

							1 {
								puthelp "NOTICE $nick :[::msgcat::mc MSG_IRC_DCCSENDFULL $filename]"
							}

							2 {
								puthelp "NOTICE $nick :[::msgcat::mc MSG_IRC_DCCSOCKET $filename]"
							}

							3 {
								puthelp "NOTICE $nick :[::msgcat::mc MSG_IRC_DCCNOTFOUND $filename]"
							}

							4 {
								puthelp "NOTICE $nick :[::msgcat::mc MSG_IRC_DCCQUEUED $filename]"
							}

							default {
								putlog "Telegram-API: irc2tg_sendFile: dccsend returned default value! This should never happen, please check your log files!"
								puthelp "NOTICE $nick :[::msgcat::mc MSG_IRC_DCCSENDFAILED]"
							}
						}
					}
				} else {
					putlog "Telegram-API: irc2tg_sendFile: ::libtelegram::downloadFile failed"
					puthelp "NOTICE $nick :[::msgcat::mc MSG_IRC_DCCSENDFAILED]"
					return -2
				}
			}
		} else {
			putlog "Telegram-API: irc2tg_sendFile: ::libtelegram::getFile failed"
			puthelp "NOTICE $nick :[::msgcat::mc MSG_IRC_DCCSENDFAILED]"
			return -3
		}
#	} else {
#		putlog "Telegram-API: irc2tg_sendFile: $nick ($hostmask) attempted to download an illegal Telegram file: $file_id"
#		return -4
#	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Delete the downloaded Telegram attachments after use                         #
# ---------------------------------------------------------------------------- #
proc ::telegram::cleanUpFiles {} {
	foreach {filename time} [array get ::telegram::filetransfers] {
		if {$time <= [clock seconds]} {
			if { [catch { file delete -force $filename } error] } {
				putlog "WARNING! DCC transfer timed out but could not delete temporary file $filename!"
			} else {
				putlog "DCC transfer timed out. File $filename succesfully deleted"
			}
			array unset ::telegram::filetransfers $filename
		}
	}
}

# ---------------------------------------------------------------------------- #
# Show information about a Telegram group, supergroup or channel               #
# ---------------------------------------------------------------------------- #
proc ::telegram::tgInfo {channel nick argc} {
	foreach {chat_id tg_channel} [array get ::telegram::tg_channels] {
		if {$channel eq $tg_channel} {
			# Get the number of members in the group, supergroup or channel
			if {[::libtelegram::getChatMembersCount $chat_id] eq 0} {
				set ::telegram::tg_chat_membercount($chat_id) [::libjson::getValue $::libtelegram::result ".result"]
			} else {
				set ::telegram::tg_chat_membercount($chat_id) -1
			}
			puthelp "NOTICE $nick :[::msgcat::mc MSG_TG_CHATTITLE $chat_id $::telegram::tg_chat_type($chat_id) $::telegram::tg_chat_title($chat_id)]"
			puthelp "NOTICE $nick :[::msgcat::mc MSG_TG_CHATDESC $chat_id $::telegram::tg_chat_description($chat_id)]"
			puthelp "NOTICE $nick :[::msgcat::mc MSG_TG_CHATMEMBERCOUNT $chat_id $::telegram::tg_chat_membercount($chat_id)]"
			if {$::telegram::tg_chat_photo($chat_id) ne ""} {
				puthelp "NOTICE $nick :[::msgcat::mc MSG_TG_CHATPHOTO $chat_id $::telegram::tg_chat_photo($chat_id)]"
			}
			if {[info exists ::telegram::tg_invite_link($chat_id)]} {
				puthelp "NOTICE $nick :[::msgcat::mc MSG_IRC_INVITELINK $::telegram::tg_chat_type($chat_id) $::telegram::tg_chat_title($chat_id) $::telegram::tg_invite_link($chat_id)]"
			}
			if {[info exists ::telegram::tg_pinned_messages($chat_id)]} {
				puthelp "NOTICE $nick :$::telegram::tg_pinned_messages($chat_id)"
			}
		}
	}
}

# ---------------------------------------------------------------------------- #
# Show information about a Telegram user                                       #
# ---------------------------------------------------------------------------- #
proc ::telegram::tgWhoIs {channel nick user_id} {
	foreach {chat_id tg_channel} [array get ::telegram::tg_channels] {
		if {$channel eq $tg_channel} {
			if {[::libtelegram::getChatMember $chat_id $user_id] eq 0} {
				set realname [concat [::libjson::getValue $::libtelegram::result ".result.user.first_name//empty"] [::libjson::getValue $::libtelegram::result ".result.user.last_name//empty"]]
				if {[set username [::libjson::getValue $::libtelegram::result ".result.user.username"]] eq "null"} {
					set username ""
				} else {
					set username " ($username)"
				}
				if {[::libjson::getValue $::libtelegram::result ".result.user.is_bot"] eq "true"} {
					set usertype [::msgcat::mc MSG_BOT_TGBOT]
				} else {
					set usertype [::msgcat::mc MSG_BOT_TGUSER]
				}
				set language_code [::libjson::getValue $::libtelegram::result ".result.user.language_code"]
				set status [::libjson::getValue $::libtelegram::result ".result.status"]

				puthelp "NOTICE $nick :[::msgcat::mc MSG_BOT_TGWHOISNAME $user_id $usertype $realname $username]"
				puthelp "NOTICE $nick :[::msgcat::mc MSG_BOT_TGWHOISSTATUS $user_id $status]"
				puthelp "NOTICE $nick :[::msgcat::mc MSG_BOT_TGWHOISLANG $user_id $language_code]"
				if {[::libtelegram::getUserProfilePhotos $user_id 0 1] eq 0} {
					set userphoto [::libjson::getValue $::libtelegram::result ".result.photos\[\]\[-1\].file_id"]
					puthelp "NOTICE $nick :[::msgcat::mc MSG_BOT_TGWHOISPHOTO $user_id $userphoto]"
				}
			} else {
				if {$::libtelegram::errorNumber == -1} {
					putchan $channel "[::msgcat::mc MSG_TG_NOCONNECTION $user_id]"
				} else {
					putchan $channel "[::msgcat::mc MSG_BOT_TGUSERNOTVALID $user_id]"
				}
			}
		}
	}
}

# ---------------------------------------------------------------------------- #
# Show administrators in a Telegram group, supergroup or channel               #
# ---------------------------------------------------------------------------- #
proc ::telegram::tgAdminsInfo {nick chat_id} {
	set permissions [list can_be_edited can_change_info can_post_messages can_edit_messages can_delete_messages can_invite_users can_restrict_members can_pin_messages can_promote_members can_send_messages can_send_media_messages can_send_other_messages can_add_web_page_previews]

	# Get info on the administrators
	if {[::libtelegram::getChatAdministrators $chat_id] eq 0} {
		set administrators [::libjson::getValue $::libtelegram::result ".result"]

		foreach administrator [split [::libjson::getValue $::libtelegram::result ".result\[\]"] "\n"] {
			if {[set username [::libjson::getValue $::libtelegram::result ".user.username"]] eq "null"} {
				set username "N/A"
			}
			set first_name [::libjson::getValue $::libtelegram::result ".user.first_name"]
			if {[set last_name [::libjson::getValue $::libtelegram::result ".user.last_name"]] eq "null"} {
				set last_name "N/A"
			}
			if {[::libjson::getValue $::libtelegram::result ".user.is_bot"] eq "true"} {
				set usertype [::msgcat::mc MSG_BOT_TGBOT]
			} else {
				set usertype [::msgcat::mc MSG_BOT_TGUSER]
			}
			set language_code [::libjson::getValue $::libtelegram::result ".user.language_code"]
			set until_date 0
			switch [::libjson::getValue $::libtelegram::result ".status"] {
				"creator" {
					set userstatus [::msgcat::mc MSG_CREATOR]
				}

				"administrator" {
					set userstatus [::msgcat::mc MSG_ADMINISTRATOR]
				}

				"member" {
					set userstatus [::msgcat::mc MSG_MEMBER]
				}

				"restricted" {
					set userstatus [::msgcat::mc MSG_RESTRICTED]
					set until_date [::libjson::getValue $::libtelegram::result ".user.until_date"]
				}

				"left" {
					set userstatus [::msgcat::mc MSG_LEFT]
				}

				"kicked" {
					set userstatus [::msgcat::mc MSG_KICKED]
					set until_date [::libjson::getValue $::libtelegram::result ".user.until_date"]
				}

			default {
					set userstatus [::msgcat::mc MSG_UNKNOWN]
				}
			}
			puthelp "NOTICE $nick :[::msgcat::mc MSG_TG_USERSTATUS $userstatus $until_date]"

			# Fetch permissions
			foreach permission $permissions {
				if {[set $permission [::libjson::getValue $::libtelegram::result ".$permission"]] eq "null"} {
					set $permission [::msgcat::mc MSG_NOTAVAILABLE]
				}
				puthelp "NOTICE $nick :[::msgcat::mc MSG_USERPERMISSION $permission [subst $$permission]]"
			}
		}
	}
}



# ---------------------------------------------------------------------------- #
# Some general usage procedures
# ---------------------------------------------------------------------------- #
# Look up the IRC handle for an Telegram user ID                               #
# ---------------------------------------------------------------------------- #
proc ::telegram::getIRCNickFromTelegramID {telegram_id} {
	foreach user [userlist] {
		if {[getuser $user XTRA "TELEGRAM_USERID"] == "$telegram_id"} {
			return $user
		}
	}
	return -1
}

# ---------------------------------------------------------------------------- #
# Get the userflags for a specific user                                        #
# ---------------------------------------------------------------------------- #
proc ::telegram::getUserFlags {telegram_id} {
	# Get the userflags for this user, or return the global userflags if the user doesn't have them
	if {[set irchandle [::telegram::getIRCNickFromTelegramID $telegram_id]] ne -1} {
		if {[set result [getuser $irchandle XTRA "TELEGRAM_USERFLAGS"]] ne ""} {
			return $result
		}
	}
	return $::telegram::userflags
}	

# ---------------------------------------------------------------------------- #
# Remove HTML tags from a string                                               #
# ---------------------------------------------------------------------------- #
proc strip_html {htmlText} {
	regsub -all {<[^>]+>} $htmlText "" newText
	return $newText
}

# ---------------------------------------------------------------------------- #
# Encode all except "unreserved" characters; use UTF-8 for extended chars.     #
# ---------------------------------------------------------------------------- #
proc url_encode {str} {
	set str [string map {"&" "&amp;" "<" "&lt;" ">" "&gt;"} $str]
#	set uStr [encoding convertto utf-8 $str]
	set chRE {[^-A-Za-z0-9._~\n]};		# Newline is special case!
	set replacement {%[format "%02X" [scan "\\\0" "%c"]]}
#	return [string map {"\n" "%0A"} [subst [regsub -all $chRE $uStr $replacement]]]
	return [string map {"\n" "%0A"} [subst [regsub -all $chRE $str $replacement]]]
}

# ---------------------------------------------------------------------------- #
# Calculate an IRC color code for a user ID                                    #
# ---------------------------------------------------------------------------- #
proc ::telegram::getColorFromUserID {user_id} {
	if {($::telegram::colorize_nicknames == 0) || ($::telegram::colorize_nicknames > 15)} {
		# Default color is black for no colorization
		return 1
	} else {
		# Calculate color by doing userid mod x, where x is 1...15
		return $::telegram::usercolors([expr $user_id % $::telegram::colorize_nicknames])
	}
}

# ---------------------------------------------------------------------------- #
# Get the title of a website for website previews on IRC                       #
# ---------------------------------------------------------------------------- #
proc ::telegram::getWebsiteTitle {url} {
	if { [ catch {
		set result [exec curl --tlsv1.2 --location -s -X GET $url]
	} ] } {
		return "[::msgcat::mc MSG_WEBPREVIEW_UNAVAILABLE]"
	}

	if {[set titlestart [string first "<title" $result]] eq -1} {
		return "[::msgcat::mc MSG_WEBPREVIEW_NOTITLE]"
	} else {
		set titlestart [string first ">" $result $titlestart]
		set titleend [string first "</title>" $result $titlestart]
		return [string range $result $titlestart+1 $titleend-1]
	}
}



# ---------------------------------------------------------------------------- #
# Start of main code                                                           #
# ---------------------------------------------------------------------------- #
# Start bot by loading Telegram modules, bind actions and do a Telegram poll   #
# ---------------------------------------------------------------------------- #

package require msgcat

set scriptdir [file dirname [info script]]

source "[file join $scriptdir lib libjson.tcl]"
source "[file join $scriptdir lib libtelegram.tcl]"
source "[file join $scriptdir lib libunicode.tcl]"
source "[file join $scriptdir Telegram-API-config.tcl]"
source "[file join $scriptdir Stickers.tcl]"

# Set localization
::msgcat::mclocale $::telegram::locale
::msgcat::mcload "[file join $scriptdir lang]"

# Dynamically load public bot command modules
foreach module [glob -nocomplain -dir "[file join $scriptdir modules]" *.tcl] {
	source $module
}

# Bind this script to IRC events
bind pubm - * ::telegram::ircSendMessage
bind join - * ::telegram::ircNickJoined
bind part - * ::telegram::ircNickLeft
bind sign - * ::telegram::ircNickLeft
bind ctcp - "ACTION" ::telegram::ircNickAction
bind nick - * ::telegram::ircNickChange
bind topc - * ::telegram::ircTopicChange
bind kick - * ::telegram::ircNickKicked
bind mode - * ::telegram::ircModeChange

::telegram::initialize

::telegram::pollTelegram

putlog "Script loaded: Telegram-API.tcl ($::telegram::tg_bot_nickname)"
