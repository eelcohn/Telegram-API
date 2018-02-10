# ---------------------------------------------------------------------------- #
# Telegram-API module v20180210 for Eggdrop                                    #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Global internal variables                                                    #
# ---------------------------------------------------------------------------- #

# Create a namespace for the Telegram-API script
namespace eval ::telegram {}

# Declare global variables
set		::telegram::tg_update_id		0
set		::telegram::tg_bot_nickname		""
set		::telegram::tg_bot_realname		""
set 		::telegram::irc_bot_nickname		""
set		::telegram::userflags			"jlvck"
set		::telegram::chanflags			"iptms"
set		::telegram::cmdmodifier			"/"
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
	set result [::libtelegram::getMe]

	if {[::libjson::getValue $result ".ok"] ne "true"} {
		putlog "Telegram-API: bad result from getMe method: [::libjson::getValue $result ".description"]"
		utimer $::telegram::tg_poll_freq tg2irc_pollTelegram
		return -1
	}

	# Get the Telegram bot's nickname and realname
	set ::telegram::tg_bot_nickname [::libjson::getValue $result ".result.username"]
	set ::telegram::tg_bot_realname [concat [::libjson::getValue $result ".result.first_name//empty"] [::libjson::getValue $result ".result.last_name//empty"]]
	set ::telegram::irc_bot_nickname "$nick"

	# Get up to date information on all Telegram groups/supergroups/channels
	foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
		# Chat titles: Only get chat titles for (super)groups we haven't queried yet
		if {![info exists ::telegram::tg_chat_title($tg_chat_id)]} {
			set result [::libtelegram::getChat $tg_chat_id]
			set ::telegram::tg_chat_title($tg_chat_id) [::libjson::getValue $result ".result.title//empty"]
		}
		# Chat descriptions: Only get chat descriptions for (super)groups we haven't queried yet
		if {![info exists ::telegram::tg_chat_description($tg_chat_id)]} {
			set result [::libtelegram::getChat $tg_chat_id]
			set ::telegram::tg_chat_description($tg_chat_id) [::libjson::getValue $result ".result.description//empty"]
		}
		# Pinned messages: Only get pinned messages for (super)groups we haven't queried yet
		if {![info exists ::telegram::tg_pinned_messages($tg_chat_id)]} {
			set result [::libtelegram::getChat $tg_chat_id]
			if {[set chattype [::libjson::getValue $result ".result.pinned_message.chat.type"]] ne "null"} {
				set ::telegram::tg_pinned_messages($tg_chat_id) [::telegram::getPinnedMessage $chattype [::libjson::getValue $result ".result.pinned_message"]]
				if {$::telegram::tg_pinned_messages($tg_chat_id) eq ""} {
					unset -nocomplain ::telegram::tg_pinned_messages($tg_chat_id)
				}
			}
		}
		# Invite links: Only get invite links for (super)groups we haven't queried yet
		if {![info exists ::telegram::tg_invite_link($tg_chat_id)]} {
			# Check if an invite link is already available in the chat object
			if {[set ::telegram::tg_invite_link($tg_chat_id) [::libjson::getValue $result ".result.invite_link//empty"]] eq ""} {
				# If not, then create a new one
				set result [::libtelegram::exportChatInviteLink $tg_chat_id]
				if {[set ::telegram::tg_invite_link($tg_chat_id) [::libjson::getValue $result ".result//empty"]] eq ""} {
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
	if {[set result [::libtelegram::getUpdates $::telegram::tg_update_id]] == -1} {
		# Network is probably down, so schedule the next poll
		utimer $::telegram::tg_poll_freq ::telegram::pollTelegram
 		return -2
	}

	# Check if the result was valid
	if {[::libjson::getValue $result ".ok"] ne "true"} {
		if {[::libjson::getValue $result ".ok"] eq "false"} {
			if {[::libjson::getValue $result ".parameters.migrate_to_chat_id"] ne "null"} {
				# A chat group has been migrated to a supergroup, but the conf file still got the chat_id for the old group
				set errormessage "[::libjson::getValue $result ".description"] - Please edit your conf file with your new chat_id: [::libjson::getValue $result ".parameters.migrate_to_chat_id"]"
			} else {
				set errormessage "[::libjson::getValue $result ".description"] - [::libjson::getValue $result ".parameters"]"
			}
		} else {
			# The Telegram servers are probably down
			set errormessage "Got a result, but not formatted as JSON. Server is probably down."
		}
		putlog "Telegram-API: bad result from getUpdates method: $errormessage"
		utimer $::telegram::tg_poll_freq ::telegram::pollTelegram
		return -3
	}

	# Iterate through each status update
	foreach msg [split [::libjson::getValue $result ".result\[\]"] "\n"] {
		set ::telegram::tg_update_id [::libjson::getValue $msg ".update_id"]
#		set msgtype [::libjson::getValue $msg ". | keys\[\] | select(. != \"update_id\")"]
		set msgtype [::libjson::getValue $msg "keys_unsorted\[1\]"]
		set chattype [::libjson::getValue $msg ".$msgtype.chat.type"]

 		switch $chattype {
			"private" {
				# Record is a private chat record
				if {[::libjson::hasKey $msg ".message.text"]} {
					set txt [remove_slashes [::libunicode::utf82ascii [::libjson::getValue $msg ".message.text"]]]
					set msgid [::libjson::getValue $msg ".message.message_id"]
					set fromid [::libjson::getValue $msg ".message.from.id"]

					tg2irc_privateCommands "$fromid" "$msgid" "$txt"
				}
			}

			"group" -
			"supergroup" -
			"channel" {
				# Record is a group, supergroup or channel record
				set chatid [::libjson::getValue $msg ".$msgtype.chat.id"]

				# Get the sender's name for this message
				set name [::telegram::getUsername $chattype [::libjson::getValue $msg ".$msgtype"]]

				# Get the caption of this message (if any)
				if {[::libjson::hasKey $msg ".$msgtype.caption"]} {
					set caption " ([remove_slashes [::libunicode::utf82ascii [::libjson::getValue $msg ".$msgtype.caption//empty"]]])"
				} else {
					set caption ""
				}

				# Get the reply-to name for this message (if available)
				if {[::libjson::hasKey $msg ".$msgtype.reply_to_message"]} {
					set replyname [::telegram::getUsername $chattype [::libjson::getValue $msg ".$msgtype.reply_to_message"]]
				}

				# Check if this message is a forwarded message
				if {[::libjson::hasKey $msg ".$msgtype.forward_from"]} {
					set forwardname [::telegram::getUsername $chattype [::libjson::getValue $msg ".$msgtype.forward_from"]]
				}

				# Check if a text message has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.text"]} {
					set txt [::libunicode::utf82ascii [::libjson::getValue $msg ".$msgtype.text"]]

					# Modify text if it is a reply-to or forwarded from
					if {[::libjson::hasKey $msg ".$msgtype.reply_to_message"]} {
						set replytomsg [::libunicode::utf82ascii [::libjson::getValue $msg ".$msgtype.reply_to_message.text"]]
						set txt "[::msgcat::mc MSG_TG_MSGREPLYTOSENT "$txt" "$replyname" "$replytomsg"]"
					} elseif {[::libjson::hasKey $msg ".$msgtype.forward_from"]} {
						set txt "[::msgcat::mc MSG_TG_MSGFORWARDED "$txt" "$forwardname"]"
					} 

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						# Send the text message if it matches
						if {$chatid eq $tg_chat_id} {
							# Treat each line seperate
							foreach line [split [string map {\\n \n} $txt] "\n"] {
								putchan $irc_channel [::msgcat::mc MSG_TG_MSGSENT "$name" "[remove_slashes $line]"]
		
								# If the line contains an URL, get the title of the website
								if {[string match -nocase "*http://?*" $line] || [string match -nocase "*https://?*" $line] || [string match -nocase "*www.?*" $line]} {
									putchan $irc_channel [getWebsiteTitle $line]
								}
							}
		
							# Check if it was a public bot command
							if {[string index $txt 0] eq $::telegram::cmdmodifier} {
								set msgid [::libjson::getValue $msg ".$msgtype.message_id"]
								tg2irc_botCommands "$tg_chat_id" "$msgid" "$irc_channel" "$txt"
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
				if {[::libjson::hasKey $msg ".$msgtype.sticker"]} {
					set setname [::libjson::getValue $msg ".$msgtype.sticker.set_name"]
					set emoji [::libjson::getValue $msg ".$msgtype.sticker.emoji"]
					set file_id [::libjson::getValue $msg ".$msgtype.sticker.file_id"]

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_STICKERSENT "$name" "$setname" "[sticker2ascii $file_id]"]
						}
					}
				}

				# Check if audio has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.audio"]} {
					set tg_file_id [::libjson::getValue $msg ".$msgtype.audio.file_id"]
					set tg_performer [::libjson::getValue $msg ".$msgtype.audio.performer"]
					set tg_title [::libjson::getValue $msg ".$msgtype.audio.title"]
					set tg_duration [::libjson::getValue $msg ".$msgtype.audio.duration"]
					if {$tg_duration eq ""} {
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
				if {[::libjson::hasKey $msg ".$msgtype.document"]} {
					set tg_file_id [::libjson::getValue $msg  ".$msgtype.document.file_id"]
					set tg_file_name [::libjson::getValue $msg ".$msgtype.document.file_name"]
					set tg_file_size [::libjson::getValue $msg ".$msgtype.document.file_size"]

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_DOCSENT " $name" "$caption" "$tg_file_name" "$tg_file_size" "$tg_file_id"]
						}
					}
				}

				# Check if a photo has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.photo"]} {
					set tg_file_id [::libjson::getValue $msg ".$msgtype.photo\[-1\].file_id"]
					set tg_file_size [::libjson::getValue $msg ".$msgtype.photo\[-1\].file_size"]

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_PHOTOSENT "$name" "$caption" "$tg_file_size" "$tg_file_id"]
						}
					}
				}

				# Check if a video has been sent to the Telegram group
				if {[::libjson::hasKey $msg ".$msgtype.video"]} {
					set tg_file_id [::libjson::getValue $msg ".$msgtype.video.file_id"]
					set tg_duration [::libjson::getValue $msg ".$msgtype.video.duration"]
					if {$tg_duration eq "null"} {
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
				if {[::libjson::hasKey $msg ".$msgtype.voice"]} {
					set tg_file_id [::libjson::getValue $msg ".$msgtype.voice.file_id"]
					set tg_duration [::libjson::getValue $msg ".$msgtype.voice.duration"]
					set tg_file_size [::libjson::getValue $msg ".$msgtype.voice.file_size"]
					if {$tg_duration eq ""} {
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
				if {[::libjson::hasKey $msg ".$msgtype.contact"]} {
					set tg_phone_number [::libjson::getValue $msg ".$msgtype.contact.phone_number"]
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
					if {[::libjson::hasKey $msg ".$msgtype.venue"]} {
						set tg_location [::libjson::getValue $msg ".$msgtype.venue.location"]
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
				if {[::libjson::hasKey $msg ".$msgtype.new_chat_member"]} {
					set new_chat_member [concat [::libjson::getValue $msg ".$msgtype.new_chat_member.first_name"] [::libjson::getValue $msg ".$msgtype.new_chat_member.last_name"]]

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
					set left_chat_member [concat [::libjson::getValue $msg ".$msgtype.left_chat_member.first_name"] [::libjson::getValue $msg ".$msgtype.left_chat_member.last_name"]]

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
				if {[::libjson::hasKey $msg ".$msgtype.new_chat_title"]} {
					set chat_title [::libjson::getValue $msg ".$msgtype.new_chat_title"]

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_CHATTITLE "[::libunicode::utf82ascii $name]" "[::libunicode::utf82ascii $chat_title]"]
						}
					}
				}

				# Check if the photo of the Telegram group chat has changed
				if {[::libjson::hasKey $msg ".$msgtype.new_chat_photo"]} {
					set tg_file_id [::libjson::getValue $msg ".$msgtype.new_chat_photo\[3\].file_id"]

					# Scan all IRC channels to check if it's connected to this Telegram group
					foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
						if {$chatid eq $tg_chat_id} {
							putchan $irc_channel [::msgcat::mc MSG_TG_PICCHANGE "[::libunicode::utf82ascii $name]" "$tg_file_id"]
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
}

# ---------------------------------------------------------------------------- #
# Respond to group commands send by Telegram users                             #
# ---------------------------------------------------------------------------- #
proc tg2irc_botCommands {chat_id msgid channel message} {
	global serveraddress

	set parameter_start [string wordend $message 1]
	set command [string tolower [string range $message 1 $parameter_start-1]]

	# Check if this command has a bot identifier in it (/command@BotIdentifier)
	if {[string match -nocase "@*" [string range $message $parameter_start end]]} {
		# If so, then check if the identifier matches our bot
		if {![string match -nocase "@$::telegram::tg_bot_realname*" [string range $message $parameter_start end]]} {
			# If not, then stop processing the command
			return
		} else {
			set parameter_start [string wordend $message $parameter_start+1]
		}
	}

	# Let the Telegram users know that we've received the bot command, and we're preparing an answer
	::libtelegram::sendChatAction $chat_id "typing"

	switch $command {
		"help" {
			set response "[::msgcat::mc MSG_BOT_PUBHELP "$::telegram::irc_bot_nickname"]\n"
			foreach {command helpmessage} [array get ::telegram::public_commands_help] {
				append $response "$command $helpmessage\n"
			}
			::libtelegram::sendMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"irctopic" {
			set response "[::msgcat::mc MSG_BOT_TG_TOPIC "$serveraddress/$channel" "$channel" "[topic $channel]"]"
			::libtelegram::sendMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"ircuser" {
			set handle [string trim [string range $message $parameter_start end]]

			if {$handle != ""} {
				if {[onchan $handle $channel]} {
					set online_since [getchanjoin $handle $channel]
					set response "[::msgcat::mc MSG_BOT_IRCUSER "$handle" "$online_since" "$serveraddress/$channel" "$channel" "[getchanhost $handle $channel]"]"
				} else {
					set response "[::msgcat::mc MSG_BOT_TG_UNKNOWNUSER "$handle" "$serveraddress/$channel" "channel"]"
				}
			} else {
				set response [::msgcat::mc MSG_BOT_HELP_IRCUSER]
			}
			::libtelegram::sendMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		"ircusers" {
			set response "[::msgcat::mc MSG_BOT_IRCUSERS "$serveraddress/$channel" "$channel" "[chanlist $channel]"]"
			::libtelegram::sendMessage $chat_id $msgid "html" "$response"
			putchan $channel "[strip_html $response]"
		}

		default {
			# Not one of the standard bot commands, so check if the bot command is in our dynamic command list
			foreach {cmd prc} [array get ::telegram::public_commands] {
				if {$command == $cmd} {
					$prc $chat_id $msgid $channel $message $parameter_start
					return
				}
			}

			# Not in our dynamic command list either, so respond with an unknown command message
			::libtelegram::sendMessage $chat_id $msgid "markdown" "[::msgcat::mc MSG_BOT_UNKNOWNCMD]"
			putchan $channel "[::msgcat::mc MSG_BOT_UNKNOWNCMD]"
		}
	}
}

# ---------------------------------------------------------------------------- #
# Add a bot command to the dynamic bot command list                            #
# ---------------------------------------------------------------------------- #
proc add_public_command {keyword procedure helpmessage} {
	set ::telegram::public_commands($keyword) $procedure
	set ::telegram::public_commands_help($keyword) $helpmessage
}

# ---------------------------------------------------------------------------- #
# Remove a bot command from the dynamic bot command list                       #
# ---------------------------------------------------------------------------- #
proc del_public_command {keyword} {
	if {[info exists $::telegram::public_commands($keyword)]} {
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
proc tg2irc_privateCommands {from_id msgid message} {
	set parameter_start [string wordend $message 1]
	set command [string tolower [string range $message 1 $parameter_start-1]]

	libtelegram::sendChatAction $from_id "typing"

	switch $command {
		"help" {
			set response "[::msgcat::mc MSG_BOT_PRVHELP "$::telegram::irc_bot_nickname"]\n"
			foreach {command helpmessage} [array get ::telegram::private_commands_help] {
				append $response "$command $helpmessage\n"
			}
			::libtelegram::sendMessage $from_id $msgid "html" "$response"
		}

		"login" {
			set login_start [string wordend $message 1]
			set login_end [string wordend $message $login_start+1]

			set irchandle [string trim [string range $message $login_start $login_end]]
			set ircpassword [string trim [string range $message $login_end end]]

			# Set the password if this is the first time this user logs in
#			if {[getuser $irchandle PASS] == ""} {
#				setuser $irchandle PASS "$ircpassword"
#				::libtelegram::sendMessage $from_id $msgid "markdown" "[::msgcat::mc MSG_BOT_PASSWORDSET "$::telegram::tg_bot_nickname"]"
#			}

			# Check if the password matches
			if {[passwdok $irchandle $ircpassword]} {
				setuser $irchandle XTRA "TELEGRAM_USERID" "[string range $from_id 0 12]"
#				setuser $irchandle XTRA "IRL" "[string range $first_name 0 159] [string range $last_name 0 159]"

				# Lookup the last login time
				set lastlogin [getuser $irchandle XTRA "TELEGRAM_LASTLOGIN"]
				if {$lastlogin == ""} {
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
				putlog "Telegram-API: Succesfull login from $from_id, username $irchandle"
			} else {
				# Username/password combo doesn't match
				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_USERPASSWRONG]"
				putlog "Telegram-API: Failed login attempt from $from_id, username $irchandle"
			}
		}

		"logout" {
			set irchandle ""

			# Look up the IRC handle for the Telegram user
			foreach user [userlist] {
				if {[getuser $user XTRA "TELEGRAM_USERID"] == "$from_id"} {
					set irchandle $user
				}
			}

			if {$irchandle != ""} {
				setuser $irchandle XTRA "TELEGRAM_USERID" ""
				setuser $irchandle XTRA "TELEGRAM_LASTUSERID" "$from_id"
				setuser $irchandle XTRA "TELEGRAM_LASTLOGOUT" "[clock seconds]"
				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_USERLOGOUT "$irchandle" "$from_id"]"
				putlog "Telegram-API: Succesfull logout from $from_id, username $irchandle"
			} else {
				::libtelegram::sendMessage $from_id $msgid "html" "[::msgcat::mc MSG_BOT_NOTLOGGEDIN]"
			}
		}

		# Show user information
		"myinfo" {
			set irchandle ""

			# Look up the IRC handle for the Telegram user
			foreach user [userlist] {
				if {[getuser $user XTRA "TELEGRAM_USERID"] == "$from_id"} {
					set irchandle $user
				}
			}

			if {$irchandle != ""} {
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
				putlog "Telegram-API: My informatio accessed by $from_id, username $irchandle"
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
			::libtelegram::sendMessage $from_id $msgid "markdown" "[::msgcat::mc MSG_BOT_UNKNOWNCMD]"
		}
	}
}

# ---------------------------------------------------------------------------- #
# Add a bot command to the dynamic bot command list                            #
# ---------------------------------------------------------------------------- #
proc add_private_command {keyword procedure helpmessage} {
	set ::telegram::private_commands($keyword) $procedure
	set ::telegram::private_commands_help($keyword) $procedure
}

# ---------------------------------------------------------------------------- #
# Remove a bot command from the dynamic bot command list                       #
# ---------------------------------------------------------------------------- #
proc del_private_command {keyword} {
	if {[info exists $::telegram::private_commands($keyword)]} {
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
		set pin_name [::libjson::getValue $pinned_message ".chat.username"]
	} else {
		if {[set pin_name [::libjson::getValue $pinned_message ".from.username"]] == "null" } {
			set pin_name [::libunicode::utf82ascii [concat [::libjson::getValue $pinned_message ".from.first_name//empty"] [::libjson::getValue $pinned_message ".from.last_name//empty"]]]
		}
		set pin_name "\003[getColorFromUserID [::libjson::getValue $pinned_message ".from.id"]]$pin_name\003"
	}		

	set pin_date "[clock format [::libjson::getValue $pinned_message ".date"] -format $::telegram::timeformat]"
	set pin_txt "[::libunicode::utf82ascii [::libjson::getValue $pinned_message ".text"]]"

	return [::msgcat::mc MSG_TG_PINNEDMESSAGE "$pin_name" "[remove_slashes $pin_txt]" "$pin_date"]
}

# ---------------------------------------------------------------------------- #
# Get the username or realname for a Telegram message                          #
# ---------------------------------------------------------------------------- #
proc ::telegram::getUsername {chattype msg} {
	if {$chattype eq "channel"} {
		# Set sender's name to the title of the channel for channel announcements
		set name [::libunicode::utf82ascii [::libjson::getValue $msg ".chat.username"]]
	} else {
		# Set sender's name for group or supergroup messages
		set name [::libunicode::utf82ascii [::libjson::getValue $msg ".from.username"]]
		if {$name == "null" } {
			set name [::libunicode::utf82ascii [concat [::libjson::getValue $msg ".from.first_name//empty"] [::libjson::getValue $msg ".from.last_name//empty"]]]
		}
		putlog "[::libjson::getValue $msg ".from.id"] -> $name"
		set name "\003[getColorFromUserID [::libjson::getValue $msg ".from.id"]]$name\003"
	}
}



# ---------------------------------------------------------------------------- #
# Procedures for sending data from IRC to Telegram                             #
# ---------------------------------------------------------------------------- #
# Send a message from IRC to Telegram                                          #
# ---------------------------------------------------------------------------- #
proc irc2tg_sendMessage {nick hostmask handle channel msg} {
	# Check if this is a bot command
	if {[string match "*[string index $msg 0]*" "/!."]} {
		# If so, then check which bot command it is, and process it. Don't send it to the Telegram group though.
		set parameter_start [string wordend $msg 1]
		set command [string tolower [string range $msg 1 $parameter_start-1]]
		if {[string match $command "tgfile"]} {
			irc2tg_sendFile $nick [string trim [string range $msg $parameter_start end]]
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
proc irc2tg_nickJoined {nick uhost handle channel} {
	global serveraddress

	# Show the invite link for all Telegram groups connected to this IRC channel
	foreach {tg_chat_id irc_channel} [array get ::telegram::tg_channels] {
		if {$channel eq $irc_channel} {
			# Check if we want to show a pinned message on this IRC channel
			if {[string match "*p*" $::telegram::chanflags]} {
				# Show pinned messages (if any) as a notice to the new user on IRC
				if {[info exists ::telegram::tg_pinned_messages($tg_chat_id)]} {
					putchan $irc_channel "$::telegram::tg_pinned_messages($tg_chat_id)"
				}
			}

			# Check if we want to show an invite link on this IRC channel
			if {[string match "*i*" $::telegram::chanflags]} {
				# Show the Telegram chat invite link
				if {[info exists ::telegram::tg_invite_link($tg_chat_id)]} {
					putchan $channel "[::msgcat::mc MSG_IRC_INVITELINK $::telegram::tg_chat_title($tg_chat_id) $::telegram::tg_invite_link($tg_chat_id)]"
				}
			}
		}
	}

	# Don't notify the Telegram users when the bot joins an IRC channel
	if {$nick ne $::telegram::irc_bot_nickname} {
		foreach {chat_id tg_channel} [array get ::telegram::tg_channels] {
			if {$channel eq $tg_channel} {
				# Only send a join message to the Telegram group if the 'join'-flag is set in the user flags variable
				if {[string match "*j*" $::telegram::userflags]} {
					if {![validuser $nick]} {
						::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_NICKJOINED "$nick" "$serveraddress/$channel" "$channel"]
					}
				}
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that someone has left an IRC channel            #
# ---------------------------------------------------------------------------- #
proc irc2tg_nickLeft {nick uhost handle channel message} {
	global  serveraddress

	# Don't notify the Telegram users when the bot joins an IRC channel
	if {$nick eq $::telegram::irc_bot_nickname} {
		return 0
	}

	# Only send a leave message to the Telegram group if the 'leave'-flag is set in the user flags variable
	if {[string match "*l*" $::telegram::userflags]} {
		foreach {chat_id tg_channel} [array get ::telegram::tg_channels] {
			if {$channel eq $tg_channel} {
				if {![validuser $nick]} {
#					::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_NICKLEFT "$nick" "$serveraddress/$channel" "$channel" "$message"]
				}
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Send an action from an IRC user to Telegram                                  #
# ---------------------------------------------------------------------------- #
proc irc2tg_nickAction {nick uhost handle dest keyword message} {
	# Only send an action message to the Telegram group if the 'voice'-flag is set in the user flags variable
	if {[string match "*v*" $::telegram::userflags]} {
		foreach {chat_id tg_channel} [array get ::telegram::tg_channels] {
			if {$dest eq $tg_channel} {
				::libtelegram::sendMessage $chat_id "" "html" [::msgcat::mc MSG_IRC_NICKACTION "$nick" "$nick" "$message"]
			}
		}
	}
	return 0
}

# ---------------------------------------------------------------------------- #
# Inform the Telegram group(s) that an IRC nickname has been changed           #
# ---------------------------------------------------------------------------- #
proc irc2tg_nickChange {nick uhost handle channel newnick} {
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
proc irc2tg_topicChange {nick uhost handle channel topic} {
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
proc irc2tg_nickKicked {nick uhost handle channel target reason} {
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
proc irc2tg_modeChange {nick uhost hand channel mode target} {
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
proc irc2tg_sendFile {nick file_id} {
	global xfer-timeout

	set max_file_size 20480000
	set timeout [expr ${xfer-timeout} + 1]

#	if {[regexp {"/[^A-Za-z0-9\-_]/"} $file_id]} {
		set result [::libtelegram::getFile $file_id]
		if {$result ne -1} {
			set file_path [::libjson::getValue $result ".result.file_path"]
			set file_size [::libjson::getValue $result ".result.file_size"]

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
						utimer $timeout cleanUpFiles

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
}

# ---------------------------------------------------------------------------- #
# Delete the downloaded Telegram attachments after use                         #
# ---------------------------------------------------------------------------- #
proc cleanUpFiles {} {
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
# Some general usage procedures
# ---------------------------------------------------------------------------- #
# Get the userflags for a specific user                                        #
# ---------------------------------------------------------------------------- #
proc getUserFlags {irchandle} {
	set irchandle ""

	# Look up the IRC handle for the Telegram user
	foreach user [userlist] {
		if {[getuser $user XTRA "TELEGRAM_USERID"] == "$from_id"} {
			set irchandle $user
		}
	}

	# Get the userflags for this user, or return the global userflags if the user doesn't have them
	if {$irchandle != ""} {
		if {[getuser $irchandle XTRA "TELEGRAM_USERFLAGS"] == ""} {
			return $::telegram::userflags
		} else {
			return [getuser $irchandle XTRA "TELEGRAM_USERFLAGS"]
		}
	}
	return $::telegram::userflags
}	

# ---------------------------------------------------------------------------- #
# Replace sticker code with ASCII code                                         #
# ---------------------------------------------------------------------------- #
proc sticker2ascii {file_id} {
	global stickertable

	foreach {filedesc stickerdesc} [array get stickertable] {
		if {$file_id == $filedesc} {
			return $stickerdesc
		}
	}

	return [::msgcat::mc MSG_TG_UNKNOWNSTICKER]
}

# ---------------------------------------------------------------------------- #
# Remove HTML tags from a string                                               #
# ---------------------------------------------------------------------------- #
proc strip_html {htmlText} {
	regsub -all {<[^>]+>} $htmlText "" newText
	return $newText
}

# ---------------------------------------------------------------------------- #
# Remove double slashes from a string                                          #
# ---------------------------------------------------------------------------- #
proc remove_slashes {txt} {
	regsub -all {\\} $txt {} txt
	return $txt
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
proc getColorFromUserID {user_id} {
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
proc getWebsiteTitle {url} {
	if { [ catch {
		set result [exec curl --tlsv1.2 --location -s -X GET $url]
	} ] } {
		return "No preview available"
	}

	set titlestart [string first "<title>" $result]
	if {$titlestart eq -1} {
		return "No title available"
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

set scriptdir [file dirname [info script]]

package require msgcat

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
bind pubm - * irc2tg_sendMessage
bind join - * irc2tg_nickJoined
bind part - * irc2tg_nickLeft
bind sign - * irc2tg_nickLeft
bind ctcp - "ACTION" irc2tg_nickAction
bind nick - * irc2tg_nickChange
bind topc - * irc2tg_topicChange
bind kick - * irc2tg_nickKicked
bind mode - * irc2tg_modeChange

::telegram::initialize

::telegram::pollTelegram

putlog "Script loaded: Telegram-API.tcl ($::telegram::tg_bot_nickname)"
