# ---------------------------------------------------------------------------- #
# Unicode library for Tcl - v20180208                                          #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

namespace eval libunicode {}

# ---------------------------------------------------------------------------- #
# Convert escaped-Unicode characters to ASCII characters                       #
# ---------------------------------------------------------------------------- #
proc ::libunicode::escaped2ascii {txt} {
	foreach {escaped ascii} [array get ::libunicode::escapedtable] {
		set txt [string map -nocase "$escaped $ascii" $txt]
	}
	return $txt
}

# ---------------------------------------------------------------------------- #
# Convert ASCII characters to escaped-Unicode characters                       #
# ---------------------------------------------------------------------------- #
proc ::libunicode::ascii2escaped {txt} {
	foreach {escaped ascii} [array get ::libunicode::escapedtable] {
		set txt [string map -nocase "$ascii $escaped" $txt]
	}
	return $txt
}

# ---------------------------------------------------------------------------- #
# Convert UTF-8 encoded Unicode to ASCII characters                            #
# ---------------------------------------------------------------------------- #
proc ::libunicode::utf82ascii {txt} {
	foreach {utf8 ascii} [array get ::libunicode::utf8table] {
		set txt [string map -nocase "$utf8 $ascii" $txt]
	}
	return $txt
}

# ---------------------------------------------------------------------------- #
# Convert ASCII characters to UTF-8 encoded Unicode                            #
# ---------------------------------------------------------------------------- #
proc ::libunicode::ascii2utf8 {txt} {
	foreach {utf8 ascii} [array get ::libunicode::utf8table] {
		set txt [string map -nocase "$ascii $utf8" $txt]
	}
	return $txt
}

# ---------------------------------------------------------------------------- #
# Convert UTF-16 encoded Unicode to ASCII characters                           #
# ---------------------------------------------------------------------------- #
proc ::libunicode::utf162ascii {txt} {
	foreach {utf16 ascii} [array get ::libunicode::utf16table] {
		set txt [string map -nocase "$utf16 $ascii" $txt]
	}
	return $txt
}

# ---------------------------------------------------------------------------- #
# Convert ASCII characters to UTF-16 encoded Unicode                           #
# ---------------------------------------------------------------------------- #
proc ::libunicode::ascii2utf16 {txt} {
	foreach {utf16 ascii} [array get ::libunicode::utf16table] {
		set txt [string map -nocase "$ascii $utf16" $txt]
	}
	return $txt
}

# ---------------------------------------------------------------------------- #
# Convert an escaped-Unicode string to an UTF-8 encoded string                 #
# ---------------------------------------------------------------------------- #
proc ::libunicode::escaped2utf8 {str} {
	set result ""

	while {[set index1 [string first "\\u" $str]] ne -1} {
		set value1 [string range $str $index1+2 $index1+5]
		scan $value1 %x hex1
		if {($hex1 >= 0x0080) && ($hex1 <= 0x07ff)} {
			set byte1 [expr 0xc0 + (($hex1 & 0x07c0) >> 6)]
			set byte2 [expr 0x80 + ($hex1 & 0x003f)]
#			set str [string map "\\\\u$value1 [binary decode hex [format %x $byte1][format %x $byte2]]" $str]
			set result [string range $str 0 $index1-2]
			append result "[binary decode hex [format %x $byte1][format %x $byte2]]"
			append result [string range $str $index1+6 end]
			set str $result
		}
		if {(($hex1 >= 0x0800) && ($hex1 <= 0xd7ff)) || ($hex1 >= 0xe000)} {
			set byte1 [expr 0xe0 + (($hex1 & 0xf000) >> 12)]
			set byte2 [expr 0x80 + (($hex1 & 0x0fc0) >> 6)]
			set byte3 [expr 0x80 + ($hex1 & 0x003f)]
#			set str [string map "\\\\u$value1 [binary decode hex [format %x $byte1][format %x $byte2][format %x $byte3]]" $str]
			set result [string range $str 0 $index1-2]
			append result "[binary decode hex [format %x $byte1][format %x $byte2][format %x $byte3]]"
			append result [string range $str $index1+6 end]
			set str $result
		}
		if {($hex1 >= 0xd800) && ($hex1 <= 0xdfff)} {
			set index2 [string first "\\u" $str $index1+5]
			set value2 [string range $str $index2+2 $index2+5]
			scan $value2 %x hex2
			set value [expr 0x10000 + (($hex1 - 0xd800) << 10) + ($hex2 - 0xdc00)]
			set byte1 [expr 0xf0 + (($value & 0x1c0000) >> 18)]
			set byte2 [expr 0x80 + (($value & 0x03f000) >> 12)]
			set byte3 [expr 0x80 + (($value & 0x000fc0) >> 6)]
			set byte4 [expr 0x80 + ($value & 0x00003f)]
#			set str [string map "\\\\u$value1\\\\u$value2 [binary decode hex [format %x $byte1][format %x $byte2][format %x $byte3][format %x $byte4]]" $str]
			set result [string range $str 0 $index1-2]
			append result "[binary decode hex [format %x $byte1][format %x $byte2][format %x $byte3][format %x $byte4]]"
			append result [string range $str $index2+6 end]
			set str $result
		}
	}
	return $str
}

# ---------------------------------------------------------------------------- #
# Convert Unicode characters to escaped-Unicode characters                     #
# ---------------------------------------------------------------------------- #
proc ::libunicode::utf82escaped {string} {
	set result ""
	set utf16output true

	#foreach char $string 
	set len [string length $string]
	for {set i 0} {$i < $len} {incr i} {
		set char1 [scan [string index $string $i] %c]
		# Don't know what to do with 0x80-0xBF, so we'll just treat them as regular ASCII characters
		if {$char1 < 0xC0} {
			append result [string index $string $i]
		} else {
			incr i
			if {$i eq $len} {
				# Safeguard if last character is > 0x80
				append result $char1
			} else {
				set char2 [scan [string index $string $i] %c]
				if {$char1 < 0xe0} {
					append result "\\u[format %.4x [expr [expr [expr $char1 & 0x1F] << 6] + [expr $char2 & 0x3F]]]"
				} else {
					incr i
					if {$i eq $len} {
						# Safeguard if last character is > 0x80
						append result $char1$char2
					} else {
						set char3 [scan [string index $string $i] %c]
						if {$char1 < 0xF0} {
							append result "\\u[format %.4x [expr [expr [expr $char1 & 0x0F] << 12] + [expr [expr $char2 & 0x3F] << 6] + [expr $char3 & 0x3F]]]"
						} else {
							incr i
							if {$i eq $len} {
								# Safeguard if last character is > 0x80
								append result $char1$char2$char3
							} else {
								set char4 [scan [string index $string $i] %c]
								set unicode [expr [expr [expr $char1 & 0x07] << 18] + [expr [expr $char2 & 0x3F] << 12] + [expr [expr $char3 & 0x3F] << 6] + [expr $char4 & 0x3F]]
								if {$utf16output} {
									append result "\\u[format %.4x [expr [expr $unicode >> 10] + 0xD7C0]]\\u[format %.4x [expr [expr $unicode & 0x3FF] | 0xDC00]]"
								} else {
									append result "\\u[format %.4x $unicode]"
								}
							}
						}
					}
				}
			}
		}
	}
	return $result
#	set result ""
#
#	foreach q [split $string {}] {
#		scan $q %c t
#		if {$t > 127} {
#			puts "[format "%04.4x" $t] "
#			append result "\\u[format %04.4x $t]"
#		} else {
#			append result $q
#		}
#	}

}

# ---------------------------------------------------------------------------- #
# Convert an escaped-Unicode string to an UTF-16 encoded string                #
# ---------------------------------------------------------------------------- #
proc ::libunicode::escaped2utf16 {str} {
	set result ""

	while {[set index1 [string first "\\u" $str]] ne -1} {
		set value1 [string range $str $index1+2 $index1+5]
		scan $value1 %x hex1
		if {($hex1 >= 0xd800) && ($hex1 <= 0xdfff)} {
			set index2 [string first "\\u" $str $index1+5]
			set value2 [string range $str $index2+2 $index2+5]
			scan $value2 %x hex2
			set byte1 [expr (($hex1 & 0xff00) >> 8)]
			set byte2 [expr ($hex1 & 0x00ff)]
			set byte3 [expr (($hex2 & 0xff00) >> 8)]
			set byte4 [expr ($hex2 & 0x00ff)]
#			set str [string map "\\\\u$value1\\\\u$value2 [binary decode hex [format %x $byte1][format %x $byte2][format %x $byte3][format %x $byte4]]" $str]
			set result [string range $str 0 $index1-2]
			append result "[binary decode hex [format %x $byte1][format %x $byte2][format %x $byte3][format %x $byte4]]"
			append result [string range $str $index2+6 end]
			set str $result
		} else {
			set byte1 [expr (($hex1 & 0xff00) >> 8)]
			set byte2 [expr ($hex1 & 0x00ff)]
#			set str [string map "\\\\u$value1 [binary decode hex [format %x $byte1][format %x $byte2]]" $str]
			set result [string range $str 0 $index1-2]
			append result "[binary decode hex [format %x $byte1][format %x $byte2]]"
			append result [string range $str $index1+6 end]
			set str $result
		}
	}
	return $str
}

# ---------------------------------------------------------------------------- #
# Convert escaped-Unicode characters to Unicode characters                     #
# ---------------------------------------------------------------------------- #
proc ::libunicode::utf162escaped {string} {
	set result ""
return ""
	set index [string first "\\u" $string]

	while {$index ne -1} {
		set value [string range $string $index+2 $index+5]
		scan $value %x hex
		set string [string map {"\\u$value" $hex} $string]
		set index [string first "\\u" $string $index+1]	
	}
	return $string
}

# http://www.charbase.com/
# http://www.charbase.com/block/emoticons
# http://www.charbase.com/block/miscellaneous-symbols-and-pictographs
# https://emojiterra.com/star-struck/
# http://www.endmemo.com/unicode/symbols.php

# 1f100-1f1ff = \ud83c\udd00 - \ud83c\uddff: Enclosed Alphanumeric Supplement / Regional indicator symbols
# 1f300-1f5ff = \ud83c\udf00 - \ud83d\uddff: Miscellaneous Symbols And Pictographs Block
# 1F600-1f64f = \ud83d\ude00 - \ud83d\ude4f: Emoticons
# 1f650-1f67f = \ud83d\ude50 - \ud83d\ude7f: 
# 1f680-1f6ff = \ud83d\ude80 - \ud83d\udeff: Transport And Map Symbols Block
# 1f900-1f9ff = \ud83e\udd00 - \ud83d\uddff: Supplemental symbols and pictographs

array set ::libunicode::escapedtable {
	{\\u00a1}		{¡}
	{\\u00a2}		{¢}
	{\\u00a3}		{£}
	{\\u00a4}		{€}
	{\\u00a5}		{¥}
	{\\u00a6}		{Š}
	{\\u00a7}		{§}
	{\\u00a8}		{š}
	{\\u00a9}		{©}
	{\\u00aa}		{ª}
	{\\u00ab}		{«}
	{\\u00ac}		{¬}
	{\\u00ae}		{®}
	{\\u00af}		{¯}
	{\\u00b0}		{°}
	{\\u00b1}		{±}
	{\\u00b2}		{²}
	{\\u00b3}		{³}
	{\\u00b4}		{Ž}
	{\\u00b5}		{µ}
	{\\u00b6}		{¶}
	{\\u00b7}		{·}
	{\\u00b8}		{ž}
	{\\u00b9}		{¹}
	{\\u00ba}		{º}
	{\\u00bb}		{»}
	{\\u00bc}		{Œ}
	{\\u00bd}		{œ}
	{\\u00be}		{Ÿ}
	{\\u00bf}		{¿}
	{\\u00c0}		{À}
	{\\u00c1}		{Á}
	{\\u00c2}		{Â}
	{\\u00c3}		{Ã}
	{\\u00c4}		{Ä}
	{\\u00c5}		{Å}
	{\\u00c6}		{Æ}
	{\\u00c7}		{Ç}
	{\\u00c8}		{È}
	{\\u00c9}		{É}
	{\\u00ca}		{Ê}
	{\\u00cb}		{Ë}
	{\\u00cc}		{Ì}
	{\\u00cd}		{Í}
	{\\u00ce}		{Î}
	{\\u00cf}		{Ï}
	{\\u00e0}		{à}
	{\\u00e1}		{á}
	{\\u00e2}		{â}
	{\\u00e3}		{ã}
	{\\u00e4}		{ä}
	{\\u00e5}		{å}
	{\\u00e6}		{æ}
	{\\u00e7}		{ç}
	{\\u00e8}		{è}
	{\\u00e9}		{é}
	{\\u00ea}		{ê}
	{\\u00eb}		{ë}
	{\\u00ec}		{ì}
	{\\u00ed}		{í}
	{\\u00ee}		{î}
	{\\u00ef}		{ï}
	{\\u00f0}		{ð}
	{\\u00f1}		{ñ}
	{\\u00f2}		{ò}
	{\\u00f3}		{ó}
	{\\u00f4}		{ô}
	{\\u00f5}		{õ}
	{\\u00f6}		{ö}
	{\\u00f7}		{÷}
	{\\u00f8}		{ø}
	{\\u00f9}		{ù}
	{\\u00fa}		{ú}
	{\\u00fb}		{û}
	{\\u00fc}		{ü}
	{\\u00fd}		{ý}
	{\\u00fe}		{þ}
	{\\u00ff}		{ÿ}
	{\\u0e3f}		{฿}
	{\\u2019}		{'}
	{\\u200d\\u2640}	{female:}
	{\\u200d\\u2642}	{male:}
	{\\u203c}		{!!}
	{\\u2049}		{!?}
	{\\u20a8}		{₨}
	{\\u20a9}		{₩}
	{\\u20aa}		{₪}
	{\\u20ab}		{₫}
	{\\u20ac}		{€}
	{\\u20b1}		{₱}
	{\\u20b9}		{₹}
	{\\u2105}		{c/o}
	{\\u2117}		{℗}
	{\\u2120}		{℠}
	{\\u2122}		{™}
	{\\u2139}		{:information_source:}
	{\\u2194}		{:left_right:}
	{\\u2195}		{:up_down:}
	{\\u2196}		{:northwest:}
	{\\u2197}		{:northeaast:}
	{\\u2198}		{:southeast:}
	{\\u2199}		{:southwest:}
	{\\u21a9}		{:back_left:}
	{\\u21aa}		{:back_right:}
	{\\u231a}		{:watch:}
	{\\u231b}		{:hourglass:}
	{\\u23ec}		{:arrow_double_down:}
	{\\u23f1}		{:stopwatch:}
	{\\u23f3}		{:hourglass:}
	{\\u24c2}		{:m:}
	{\\u25aa}		{:black_small_square:}
	{\\u25ab}		{:white_small_square:}
	{\\u25c0}		{:arrow_backward:}
	{\\u25fb}		{:white_medium_square:}
	{\\u25fc}		{:black_medium_square:}
	{\\u25fd}		{:white_medium_small_square:}
	{\\u2600}		{:sunny:}
	{\\u2601}		{:cloud:}
	{\\u2602}		{:umbrella:}
	{\\u2603}		{:snowman:}
	{\\u2604}		{:comet:}
	{\\u2605}		{:black_star:}
	{\\u2606}		{:white_star:}
	{\\u2607}		{:lightning:}
	{\\u2608}		{:thunderstorm:}
	{\\u2609}		{:sun:}
	{\\u260a}		{:ascending_note:}
	{\\u260b}		{:descending_note:}
	{\\u260c}		{:conjunction:}
	{\\u260d}		{:opposition:}
	{\\u260e}		{:telephone_black:}
	{\\u260f}		{:telephone_white:}
	{\\u2610}		{:ballot_box:}
	{\\u2611}		{:ballot_box_checked:}
	{\\u2612}		{:ballot_box_x:}
	{\\u2613}		{:saltire:}
	{\\u2614}		{:umbrella_rain:}
	{\\u2615}		{:coffee:}
	{\\u2616}		{:shogi_white:}
	{\\u2617}		{:shogi_black:}
	{\\u2618}		{:shamrock:}
	{\\u2619}		{:reversed_rotated_floral_heart_bullet:}
	{\\u261a}		{:finger_pointing_left:}
	{\\u261b}		{:finger_pointing_right:}
	{\\u261c}		{:finger_pointing_left:}
	{\\u261d}		{:finger_pointing_up:}
	{\\u261e}		{:finger_pointing_right:}
	{\\u261f}		{:finger_pointing_down:}
	{\\u2620}		{:skull_and_bones:}
	{\\u2621}		{:caution:}
	{\\u2622}		{:radioactive:}
	{\\u2623}		{:biohazard:}
	{\\u2624}		{:caduceus:}
	{\\u2625}		{:ankh:}
	{\\u2626}		{:orthodox_cross:}
	{\\u2627}		{:chi_rho:}
	{\\u2628}		{:cross_of_lorraine:}
	{\\u2629}		{:cross_of_jerusalem:}
	{\\u262a}		{:star_and_crescent:}
	{\\u262b}		{:farsi:}
	{\\u262c}		{:adi_shakti:}
	{\\u262d}		{:hammer_and_sickle:}
	{\\u262e}		{:peace_symbol:}
	{\\u262f}		{:yin_yan:}
	{\\u2630}		{:trigram_heaven:}
	{\\u2631}		{:trigram_lake:}
	{\\u2632}		{:trigram_fire:}
	{\\u2633}		{:trigram_thunder:}
	{\\u2634}		{:trigram_wind:}
	{\\u2635}		{:trigram_water:}
	{\\u2636}		{:trigram_mountain:}
	{\\u2637}		{:trigram_earth:}
	{\\u2638}		{:wheel_of_dharma:}
	{\\u2639}		{:-(}
	{\\u263a}		{:-)}
	{\\u263b}		{:-)}
	{\\u263c}		{:sun_with_rays:}
	{\\u263d}		{:moon_first_quarter:}
	{\\u263e}		{:moon_last_quarter:}
	{\\u263f}		{:mercury:}
	{\\u2640}		{:female:}
	{\\u2641}		{:earth:}
	{\\u2642}		{:male:}
	{\\u2643}		{:jupiter:}
	{\\u2644}		{:saturn:}
	{\\u2645}		{:uranus:}
	{\\u2646}		{:neptune:}
	{\\u2647}		{:pluto:}
	{\\u2648}		{:aries:}
	{\\u2649}		{:taurus:}
	{\\u264a}		{:gemini:}
	{\\u264b}		{:cancer:}
	{\\u264c}		{:leo:}
	{\\u264d}		{:virgo:}
	{\\u264e}		{:libra:}
	{\\u264f}		{:scorpius:}
	{\\u2650}		{:sagittarius:}
	{\\u2651}		{:capricorn:}
	{\\u2652}		{:aquarius:}
	{\\u2653}		{:pisces:}
	{\\u2654}		{:white_chess_king:}
	{\\u2655}		{:white_chess_queen:}
	{\\u2656}		{:white_chess_rook:}
	{\\u2657}		{:white_chess_bishop:}
	{\\u2658}		{:white_chess_knight:}
	{\\u2659}		{:white_chess_pawn:}
	{\\u265a}		{:black_chess_king:}
	{\\u265b}		{:black_chess_queen:}
	{\\u265c}		{:black_chess_rook:}
	{\\u265d}		{:black_chess_bishop:}
	{\\u265e}		{:black_chess_knight:}
	{\\u265f}		{:black_chess_pawn:}
	{\\u2660}		{:black_spades:}
	{\\u2661}		{:white_hearts:}
	{\\u2662}		{:white_diamonds:}
	{\\u2663}		{:black_clubs:}
	{\\u2664}		{:white_spades:}
	{\\u2665}		{:black_hearts:}
	{\\u2666}		{:black_diamonds:}
	{\\u2667}		{:white_clubs:}
	{\\u2668}		{:warning_hot:}
	{\\u2669}		{:quarter_note:}
	{\\u266a}		{:eight_note:}
	{\\u266b}		{:beamed_eight_note:}
	{\\u266c}		{:beamed_sixteenth_note:}
	{\\u266d}		{:music_flat:}
	{\\u266e}		{:music_natural:}
	{\\u266f}		{:music_sharp:}
	{\\u2670}		{:west_syrriac_cross:}
	{\\u2671}		{:east_syrriac_cross:}
	{\\u2672}		{:recycle:}
	{\\u2673}		{:recycle_type1:}
	{\\u2674}		{:recycle_type2:}
	{\\u2675}		{:recycle_type3:}
	{\\u2676}		{:recycle_type4:}
	{\\u2677}		{:recycle_type5:}
	{\\u2678}		{:recycle_type6:}
	{\\u2679}		{:recycle_type7:}
	{\\u267a}		{:recycle_generic:}
	{\\u267b}		{:recycle:}
	{\\u267b}		{:recycle_paper:}
	{\\u267b}		{:recycle_paper_partially:}
	{\\u267e}		{:infinity:}
	{\\u267f}		{:wheelchair:}
	{\\u2680}		{:die_face_1:}
	{\\u2681}		{:die_face_2:}
	{\\u2682}		{:die_face_3:}
	{\\u2683}		{:die_face_4:}
	{\\u2684}		{:die_face_5:}
	{\\u2685}		{:die_face_6:}
	{\\u2686}		{:white_circle_dot_right:}
	{\\u2687}		{:white_circle_dots_left_right:}
	{\\u2688}		{:black_circle_dot_right:}
	{\\u2689}		{:black_circle_dots_left_right:}
	{\\u268a}		{:monogram_yang:}
	{\\u268b}		{:monogram_yin:}
	{\\u268c}		{:diagram_greater_yang:}
	{\\u268d}		{:diagram_lesser_yang:}
	{\\u268e}		{:diagram_greater_yin:}
	{\\u268f}		{:diagram_lesser_yin:}
	{\\u2690}		{:white_flag:}
	{\\u2691}		{:black_flag:}
	{\\u2693}		{:anchor:}
	{\\u2694}		{:crossed_swords:}
	{\\u2695}		{:aesculape:}
	{\\u2696}		{:scales:}
	{\\u2697}		{:alembic:}
	{\\u2698}		{:flower:}
	{\\u2699}		{:gear:}
	{\\u269a}		{:staff_of_hermes:}
	{\\u269b}		{:atom:}
	{\\u269c}		{:fleur_de_lis:}
	{\\u269d}		{:white_star:}
	{\\u269e}		{:three_lines_converging_right:}
	{\\u269f}		{:three_lines_converging_left:}
	{\\u26a0}		{:warning:}
	{\\u26a1}		{:zap:}
	{\\u26a2}		{:double_female_sign:}
	{\\u26a3}		{:double_male_sign:}
	{\\u26a4}		{:interlocked_male_female_sign:}
	{\\u26a5}		{:male_female_sign:}
	{\\u26a6}		{:male_stroked_sign:}
	{\\u26a7}		{:male_stroked_with_male_female_sign:}
	{\\u26a8}		{:vertical_male_stroked_sign:}
	{\\u26a9}		{:horizontal_male_stroked_sign:}
	{\\u26aa}		{:white_circle:}
	{\\u26ab}		{:black_circle:}
	{\\u26ac}		{:small_white_circle:}
	{\\u26ad}		{:marriage:}
	{\\u26ae}		{:divorce:}
	{\\u26af}		{:partnership:}
	{\\u26b0}		{:coffin:}
	{\\u26b1}		{:urn:}
	{\\u26b2}		{:neuter:}
	{\\u26b3}		{:ceres:}
	{\\u26b4}		{:pallas:}
	{\\u26b5}		{:juno:}
	{\\u26b6}		{:vesta:}
	{\\u26b7}		{:chiron:}
	{\\u26b8}		{:lilith:}
	{\\u26b9}		{:sextile:}
	{\\u26ba}		{:semisextile:}
	{\\u26bb}		{:quincunx:}
	{\\u26bc}		{:sesquiquadrate:}
	{\\u26bd}		{:soccer:}
	{\\u26be}		{:baseball:}
	{\\u26bf}		{:squared_key:}
	{\\u26c0}		{:white_draughts_man:}
	{\\u26c1}		{:white_draughts_king:}
	{\\u26c2}		{:black_draughts_man:}
	{\\u26c3}		{:black_draughts_king:}
	{\\u26c4}		{:snowman:}
	{\\u26c5}		{:sun_behind_cloud:}
	{\\u26c6}		{:rain:}
	{\\u26c7}		{:snowman_black:}
	{\\u26c8}		{:thunder_cloud_and_rain:}
	{\\u26c9}		{:shogi_white:}
	{\\u26ca}		{:shogi_black:}
	{\\u26cb}		{:diamond_in_square:}
	{\\u26cc}		{:crossing_lanes:}
	{\\u26cd}		{:disabled_car:}
	{\\u26ce}		{:ophiuchus:}
	{\\u26cf}		{:pick:}
	{\\u26d0}		{:car_sliding:}
	{\\u26d1}		{:helmet_white_cross:}
	{\\u26d2}		{:circled_crossing_lanes:}
	{\\u26d3}		{:chains:}
	{\\u26d4}		{:no_entry:}
	{\\u26d5}		{:alternate_oneway_traffic_left:}
	{\\u26d6}		{:twoway_left_way_traffic_black:}
	{\\u26d7}		{:twoway_left_way_traffic_white:}
	{\\u26d8}		{:left_lane_merge_black:}
	{\\u26d9}		{:left_lane_merge_white:}
	{\\u26da}		{:drive_slow:}
	{\\u26db}		{:down_pointing_triangle:}
	{\\u26dc}		{:left_closed_entry:}
	{\\u26dd}		{:squared_saltire:}
	{\\u26de}		{:diagonal_in_white_circle_black_square:}
	{\\u26df}		{:black_truck:}
	{\\u26e0}		{:restricted_left_entry:}
	{\\u26e1}		{:restricted_left_entry:}
	{\\u26e2}		{:uranus:}
	{\\u26e3}		{:circle_with_stroke_and_two_dots:}
	{\\u26e4}		{:pentagram:}
	{\\u26e5}		{:pentagram_interlaced_right:}
	{\\u26e6}		{:pentagram_interlaced_left:}
	{\\u26e7}		{:pentagram_inverted:}
	{\\u26e8}		{:black_cross_on_shield:}
	{\\u26e9}		{:shinto_shrine:}
	{\\u26ea}		{:church:}
	{\\u26eb}		{:castle:}
	{\\u26ec}		{:historic_site:}
	{\\u26ed}		{:gear_without_hub:}
	{\\u26ee}		{:gear_with_handles:}
	{\\u26ef}		{:lighthouse:}
	{\\u26f0}		{:mountain:}
	{\\u26f1}		{:beach_umbrella:}
	{\\u26f2}		{:fountain:}
	{\\u26f3}		{:golf:}
	{\\u26f4}		{:ferry:}
	{\\u26f5}		{:sailboat:}
	{\\u26f6}		{:square_four_corners:}
	{\\u26f7}		{:skier:}
	{\\u26f8}		{:ice_skate:}
	{\\u26f9}		{:person_playing_basketball:}
	{\\u26fa}		{:tent:}
	{\\u26fb}		{:japanese_bank:}
	{\\u26fc}		{:headstone_graveyard:}
	{\\u26fd}		{:gaspump:}
	{\\u26fe}		{:coffee_sign:}
	{\\u26ff}		{:flag_with_stripe:}
	{\\u2700}		{:scissors:}
	{\\u2701}		{:scissors_upper_blade:}
	{\\u2702}		{:scissors:}
	{\\u2703}		{:scissors_lower_blade:}
	{\\u2704}		{:scissors:}
	{\\u2705}		{:check_mark:}
	{\\u2706}		{:telephone_sign:}
	{\\u2707}		{:tapedrive:}
	{\\u2708}		{:airplane:}
	{\\u2709}		{:envelope:}
	{\\u270a}		{:raised_fist:}
	{\\u270b}		{:raised_hand:}
	{\\u270c}		{:victory_hand:}
	{\\u270d}		{:writing_hand:}
	{\\u270e}		{:pencil:}
	{\\u270f}		{:pencil:}
	{\\u2710}		{:pencil:}
	{\\u2711}		{:ink_pen:}
	{\\u2712}		{:ink_pen:}
	{\\u2713}		{:check_mark:}
	{\\u2714}		{:check_mark:}
	{\\u2715}		{:multiplication_x:}
	{\\u2716}		{:heavy_multiplication_x:}
	{\\u2717}		{:ballot_x:}
	{\\u2718}		{:heavy_ballot_x:}
	{\\u2719}		{:greek_cross:}
	{\\u271a}		{:greek_cross:}
	{\\u271b}		{:open_center_cross:}
	{\\u271c}		{:heavy_open_center_cross:}
	{\\u271d}		{:latin_cross:}
	{\\u271e}		{:latin_cross_shadowed:}
	{\\u271f}		{:latin_cross_outlined:}
	{\\u2720}		{:maltese_cross:}
	{\\u2721}		{:star_of_david:}
	{\\u2728}		{:sparkles:}
	{\\u2734}		{:eight_pointed_black_star:}
	{\\u2744}		{:snowflake:}
	{\\u2753}		{:?_black:}
	{\\u2754}		{:?_grey:}
	{\\u2755}		{:!_grey:}
	{\\u2757}		{:!:}
	{\\u2763}		{:heart_exclamation_mark:}
	{\\u2764}		{:heart:}
	{\\u2797}		{:heavy_division_sign:}
	{\\u27b0}		{:curly_loop:}
	{\\u27bf}		{:double_curly_loop:}
	{\\u2935}		{:arrow_heading_down:}
	{\\u2b05}		{:arrow_left:}
	{\\u2b1b}		{:black_large_square:}
	{\\u2b1c}		{:white_large_square:}
	{\\u2b50}		{:star:}
	{\\u2b55}		{:circle:}
	{\\u3030}		{:wavy_dash:}

	{\\ud83c\\udd00}	{" :0.:"}
	{\\ud83c\\udd01}	{" :0,:"}
	{\\ud83c\\udd02}	{" :1,:"}
	{\\ud83c\\udd03}	{" :2,:"}
	{\\ud83c\\udd04}	{" :3,:"}
	{\\ud83c\\udd05}	{" :4,:"}
	{\\ud83c\\udd06}	{" :5,:"}
	{\\ud83c\\udd07}	{" :6,:"}
	{\\ud83c\\udd08}	{" :7,:"}
	{\\ud83c\\udd09}	{" :8,:"}
	{\\ud83c\\udd0a}	{" :9,:"}
	{\\ud83c\\udd10}	{" :(A):"}
	{\\ud83c\\udd11}	{" :(B):"}
	{\\ud83c\\udd12}	{" :(C):"}
	{\\ud83c\\udd13}	{" :(D):"}
	{\\ud83c\\udd14}	{" :(E):"}
	{\\ud83c\\udd15}	{" :(F):"}
	{\\ud83c\\udd16}	{" :(G):"}
	{\\ud83c\\udd17}	{" :(H):"}
	{\\ud83c\\udd18}	{" :(I):"}
	{\\ud83c\\udd19}	{" :(J):"}
	{\\ud83c\\udd1a}	{" :(K):"}
	{\\ud83c\\udd1b}	{" :(L):"}
	{\\ud83c\\udd1c}	{" :(M):"}
	{\\ud83c\\udd1d}	{" :(N):"}
	{\\ud83c\\udd1e}	{" :(O):"}
	{\\ud83c\\udd1f}	{" :(P):"}
	{\\ud83c\\udd20}	{" :(Q):"}
	{\\ud83c\\udd21}	{" :(R):"}
	{\\ud83c\\udd22}	{" :(S):"}
	{\\ud83c\\udd23}	{" :(T):"}
	{\\ud83c\\udd24}	{" :(U):"}
	{\\ud83c\\udd25}	{" :(V):"}
	{\\ud83c\\udd26}	{" :(W):"}
	{\\ud83c\\udd27}	{" :(X):"}
	{\\ud83c\\udd28}	{" :(Y):"}
	{\\ud83c\\udd29}	{" :(Z):"}
	{\\ud83c\\udd30}	{" :[A]:"}
	{\\ud83c\\udd31}	{" :[B]:"}
	{\\ud83c\\udd32}	{" :[C]:"}
	{\\ud83c\\udd33}	{" :[D]:"}
	{\\ud83c\\udd34}	{" :[E]:"}
	{\\ud83c\\udd35}	{" :[F]:"}
	{\\ud83c\\udd36}	{" :[G]:"}
	{\\ud83c\\udd37}	{" :[H]:"}
	{\\ud83c\\udd38}	{" :[I]:"}
	{\\ud83c\\udd39}	{" :[J]:"}
	{\\ud83c\\udd3a}	{" :[K]:"}
	{\\ud83c\\udd3b}	{" :[L]:"}
	{\\ud83c\\udd3c}	{" :[M]:"}
	{\\ud83c\\udd3d}	{" :[N]:"}
	{\\ud83c\\udd3e}	{" :[O]:"}
	{\\ud83c\\udd3f}	{" :[P]:"}
	{\\ud83c\\udd40}	{" :[Q]:"}
	{\\ud83c\\udd41}	{" :[R]:"}
	{\\ud83c\\udd42}	{" :[S]:"}
	{\\ud83c\\udd43}	{" :[T]:"}
	{\\ud83c\\udd44}	{" :[U]:"}
	{\\ud83c\\udd45}	{" :[V]:"}
	{\\ud83c\\udd46}	{" :[W]:"}
	{\\ud83c\\udd47}	{" :[X]:"}
	{\\ud83c\\udd48}	{" :[Y]:"}
	{\\ud83c\\udd49}	{" :[Z]:"}
	{\\ud83c\\udd4a}	{" :[HV]:"}
	{\\ud83c\\udd4b}	{" :[MV]:"}
	{\\ud83c\\udd4c}	{" :[SD]:"}
	{\\ud83c\\udd4d}	{" :[SS]:"}
	{\\ud83c\\udd4e}	{" :[PPV]:"}
	{\\ud83c\\udd4f}	{" :[WC]:"}
	{\\ud83c\\udd70}	{" :bloodtype_a:"}
	{\\ud83c\\udd71}	{" :bloodtype_b:"}
	{\\ud83c\\udd7e}	{" :bloodtype_o:"}
	{\\ud83c\\udd7f}	{" :parking:"}
	{\\ud83c\\udd8e}	{" :bloodtype_ab:"}
	{\\ud83c\\udd8f}	{" :wc:"}
	{\\ud83c\\udd93}	{" :free:"}

	{\\ud83c\\udde6\\ud83c\\udde6}	{" :flag_aa:"}
	{\\ud83c\\udde6\\ud83c\\udde7}	{" :flag_ab:"}
	{\\ud83c\\udde6\\ud83c\\udde8}	{" :flag_ac:"}
	{\\ud83c\\udde6\\ud83c\\udde9}	{" :flag_andorra:"}
	{\\ud83c\\udde6\\ud83c\\uddea}	{" :flag_united_arab_emirates:"}
	{\\ud83c\\udde6\\ud83c\\uddeb}	{" :flag_afghanistan:"}
	{\\ud83c\\udde6\\ud83c\\uddec}	{" :flag_antigua_and_barbuda:"}
	{\\ud83c\\udde6\\ud83c\\udded}	{" :flag_ah:"}
	{\\ud83c\\udde6\\ud83c\\uddee}	{" :flag_anguilla:"}
	{\\ud83c\\udde6\\ud83c\\uddef}	{" :flag_aj:"}
	{\\ud83c\\udde6\\ud83c\\uddf0}	{" :flag_ak:"}
	{\\ud83c\\udde6\\ud83c\\uddf1}	{" :flag_albania:"}
	{\\ud83c\\udde6\\ud83c\\uddf2}	{" :flag_armenia:"}
	{\\ud83c\\udde6\\ud83c\\uddf3}	{" :flag_an:"}
	{\\ud83c\\udde6\\ud83c\\uddf4}	{" :flag_angola:"}
	{\\ud83c\\udde6\\ud83c\\uddf5}	{" :flag_ap:"}
	{\\ud83c\\udde6\\ud83c\\uddf6}	{" :flag_antartica:"}
	{\\ud83c\\udde6\\ud83c\\uddf7}	{" :flag_argentina:"}
	{\\ud83c\\udde6\\ud83c\\uddf8}	{" :flag_american_samoa:"}
	{\\ud83c\\udde6\\ud83c\\uddf9}	{" :flag_austria:"}
	{\\ud83c\\udde6\\ud83c\\uddfa}	{" :flag_australia:"}
	{\\ud83c\\udde6\\ud83c\\uddfb}	{" :flag_av:"}
	{\\ud83c\\udde6\\ud83c\\uddfc}	{" :flag_aruba:"}
	{\\ud83c\\udde6\\ud83c\\uddfd}	{" :flag_aland_islands:"}
	{\\ud83c\\udde6\\ud83c\\uddfe}	{" :flag_ay:"}
	{\\ud83c\\udde6\\ud83c\\uddff}	{" :flag_azerbaijan:"}
	{\\ud83c\\udde7\\ud83c\\udde6}	{" :flag_bosnia_herzegovina:"}
	{\\ud83c\\udde7\\ud83c\\udde7}	{" :flag_barbados:"}
	{\\ud83c\\udde7\\ud83c\\udde8}	{" :flag_bc:"}
	{\\ud83c\\udde7\\ud83c\\udde9}	{" :flag_bangladesh:"}
	{\\ud83c\\udde7\\ud83c\\uddea}	{" :flag_belgium:"}
	{\\ud83c\\udde7\\ud83c\\uddeb}	{" :flag_burkinha_faso:"}
	{\\ud83c\\udde7\\ud83c\\uddec}	{" :flag_bulgaria:"}
	{\\ud83c\\udde7\\ud83c\\udded}	{" :flag_bahrain:"}
	{\\ud83c\\udde7\\ud83c\\uddee}	{" :flag_burundi:"}
	{\\ud83c\\udde7\\ud83c\\uddef}	{" :flag_benin:"}
	{\\ud83c\\udde7\\ud83c\\uddf0}	{" :flag_bk:"}
	{\\ud83c\\udde7\\ud83c\\uddf1}	{" :flag_saint_barthelemy:"}
	{\\ud83c\\udde7\\ud83c\\uddf2}	{" :flag_bermuda:"}
	{\\ud83c\\udde7\\ud83c\\uddf3}	{" :flag_brunei_darussalam:"}
	{\\ud83c\\udde7\\ud83c\\uddf4}	{" :flag_bolivia:"}
	{\\ud83c\\udde7\\ud83c\\uddf5}	{" :flag_bp:"}
	{\\ud83c\\udde7\\ud83c\\uddf6}	{" :flag_bonaire_saint_ustatius_saba:"}
	{\\ud83c\\udde7\\ud83c\\uddf7}	{" :flag_brazil:"}
	{\\ud83c\\udde7\\ud83c\\uddf8}	{" :flag_bahamas:"}
	{\\ud83c\\udde7\\ud83c\\uddf9}	{" :flag_bhutan:"}
	{\\ud83c\\udde7\\ud83c\\uddfa}	{" :flag_bu:"}
	{\\ud83c\\udde7\\ud83c\\uddfb}	{" :flag_bouvet_island:"}
	{\\ud83c\\udde7\\ud83c\\uddfc}	{" :flag_botswana:"}
	{\\ud83c\\udde7\\ud83c\\uddfd}	{" :flag_bx:"}
	{\\ud83c\\udde7\\ud83c\\uddfe}	{" :flag_belarus:"}
	{\\ud83c\\udde7\\ud83c\\uddff}	{" :flag_belize:"}
	{\\ud83c\\udde8\\ud83c\\udde6}	{" :flag_canada:"}
	{\\ud83c\\udde8\\ud83c\\udde7}	{" :flag_cb:"}
	{\\ud83c\\udde8\\ud83c\\udde8}	{" :flag_cocos_islands:"}
	{\\ud83c\\udde8\\ud83c\\udde9}	{" :flag_congo:"}
	{\\ud83c\\udde8\\ud83c\\uddea}	{" :flag_ce:"}
	{\\ud83c\\udde8\\ud83c\\uddeb}	{" :flag_central_african_republic:"}
	{\\ud83c\\udde8\\ud83c\\uddec}	{" :flag_congo:"}
	{\\ud83c\\udde8\\ud83c\\udded}	{" :flag_switzerland:"}
	{\\ud83c\\udde8\\ud83c\\uddee}	{" :flag_ivory_coast:"}
	{\\ud83c\\udde8\\ud83c\\uddef}	{" :flag_cj:"}
	{\\ud83c\\udde8\\ud83c\\uddf0}	{" :flag_cook_islands:"}
	{\\ud83c\\udde8\\ud83c\\uddf1}	{" :flag_chile:"}
	{\\ud83c\\udde8\\ud83c\\uddf2}	{" :flag_cameroon:"}
	{\\ud83c\\udde8\\ud83c\\uddf3}	{" :flag_china:"}
	{\\ud83c\\udde8\\ud83c\\uddf4}	{" :flag_colombia:"}
	{\\ud83c\\udde8\\ud83c\\uddf5}	{" :flag_cp:"}
	{\\ud83c\\udde8\\ud83c\\uddf6}	{" :flag_cq:"}
	{\\ud83c\\udde8\\ud83c\\uddf7}	{" :flag_costa_rica:"}
	{\\ud83c\\udde8\\ud83c\\uddf8}	{" :flag_cs:"}
	{\\ud83c\\udde8\\ud83c\\uddf9}	{" :flag_ct:"}
	{\\ud83c\\udde8\\ud83c\\uddfa}	{" :flag_cuba:"}
	{\\ud83c\\udde8\\ud83c\\uddfb}	{" :flag_cape_verde:"}
	{\\ud83c\\udde8\\ud83c\\uddfc}	{" :flag_curacao:"}
	{\\ud83c\\udde8\\ud83c\\uddfd}	{" :flag_christmas_island:"}
	{\\ud83c\\udde8\\ud83c\\uddfe}	{" :flag_cyprus:"}
	{\\ud83c\\udde8\\ud83c\\uddff}	{" :flag_czech_republic:"}
	{\\ud83c\\udde9\\ud83c\\udde6}	{" :flag_da:"}
	{\\ud83c\\udde9\\ud83c\\udde7}	{" :flag_db:"}
	{\\ud83c\\udde9\\ud83c\\udde8}	{" :flag_dc:"}
	{\\ud83c\\udde9\\ud83c\\udde9}	{" :flag_dd:"}
	{\\ud83c\\udde9\\ud83c\\uddea}	{" :flag_germany:"}
	{\\ud83c\\udde9\\ud83c\\uddeb}	{" :flag_df:"}
	{\\ud83c\\udde9\\ud83c\\uddec}	{" :flag_dg:"}
	{\\ud83c\\udde9\\ud83c\\udded}	{" :flag_dh:"}
	{\\ud83c\\udde9\\ud83c\\uddee}	{" :flag_di:"}
	{\\ud83c\\udde9\\ud83c\\uddef}	{" :flag_djibouti:"}
	{\\ud83c\\udde9\\ud83c\\uddf0}	{" :flag_denmark:"}
	{\\ud83c\\udde9\\ud83c\\uddf1}	{" :flag_dl:"}
	{\\ud83c\\udde9\\ud83c\\uddf2}	{" :flag_dominica:"}
	{\\ud83c\\udde9\\ud83c\\uddf3}	{" :flag_dn:"}
	{\\ud83c\\udde9\\ud83c\\uddf4}	{" :flag_dominican_republic:"}
	{\\ud83c\\udde9\\ud83c\\uddf5}	{" :flag_dp:"}
	{\\ud83c\\udde9\\ud83c\\uddf6}	{" :flag_dq:"}
	{\\ud83c\\udde9\\ud83c\\uddf8}	{" :flag_dr:"}
	{\\ud83c\\udde9\\ud83c\\uddf9}	{" :flag_ds:"}
	{\\ud83c\\udde9\\ud83c\\uddfa}	{" :flag_dt:"}
	{\\ud83c\\udde9\\ud83c\\uddfb}	{" :flag_du:"}
	{\\ud83c\\udde9\\ud83c\\uddfc}	{" :flag_dv:"}
	{\\ud83c\\udde9\\ud83c\\uddfd}	{" :flag_dx:"}
	{\\ud83c\\udde9\\ud83c\\uddfe}	{" :flag_dy:"}
	{\\ud83c\\udde9\\ud83c\\uddff}	{" :flag_algeria:"}
	{\\ud83c\\uddea\\ud83c\\udde6}	{" :flag_ea:"}
	{\\ud83c\\uddea\\ud83c\\udde7}	{" :flag_eb:"}
	{\\ud83c\\uddea\\ud83c\\udde8}	{" :flag_ecuador:"}
	{\\ud83c\\uddea\\ud83c\\udde9}	{" :flag_ed:"}
	{\\ud83c\\uddea\\ud83c\\uddea}	{" :flag_estonia:"}
	{\\ud83c\\uddea\\ud83c\\uddeb}	{" :flag_ef:"}
	{\\ud83c\\uddea\\ud83c\\uddec}	{" :flag_egypt:"}
	{\\ud83c\\uddea\\ud83c\\udded}	{" :flag_western_sahara:"}
	{\\ud83c\\uddea\\ud83c\\uddee}	{" :flag_ei:"}
	{\\ud83c\\uddea\\ud83c\\uddef}	{" :flag_ej:"}
	{\\ud83c\\uddea\\ud83c\\uddf0}	{" :flag_ek:"}
	{\\ud83c\\uddea\\ud83c\\uddf1}	{" :flag_el:"}
	{\\ud83c\\uddea\\ud83c\\uddf2}	{" :flag_em:"}
	{\\ud83c\\uddea\\ud83c\\uddf3}	{" :flag_en:"}
	{\\ud83c\\uddea\\ud83c\\uddf4}	{" :flag_eo:"}
	{\\ud83c\\uddea\\ud83c\\uddf5}	{" :flag_ep:"}
	{\\ud83c\\uddea\\ud83c\\uddf6}	{" :flag_eq:"}
	{\\ud83c\\uddea\\ud83c\\uddf7}	{" :flag_eritrea:"}
	{\\ud83c\\uddea\\ud83c\\uddf8}	{" :flag_spain:"}
	{\\ud83c\\uddea\\ud83c\\uddf9}	{" :flag_ethiopia:"}
	{\\ud83c\\uddea\\ud83c\\uddfa}	{" :flag_european_union:"}
	{\\ud83c\\uddea\\ud83c\\uddfb}	{" :flag_ev:"}
	{\\ud83c\\uddea\\ud83c\\uddfc}	{" :flag_ew:"}
	{\\ud83c\\uddea\\ud83c\\uddfd}	{" :flag_ex:"}
	{\\ud83c\\uddea\\ud83c\\uddfe}	{" :flag_ey:"}
	{\\ud83c\\uddea\\ud83c\\uddff}	{" :flag_ez:"}
	{\\ud83c\\uddeb\\ud83c\\udde6}	{" :flag_fa:"}
	{\\ud83c\\uddeb\\ud83c\\udde7}	{" :flag_fb:"}
	{\\ud83c\\uddeb\\ud83c\\udde8}	{" :flag_fc:"}
	{\\ud83c\\uddeb\\ud83c\\udde9}	{" :flag_fd:"}
	{\\ud83c\\uddeb\\ud83c\\uddea}	{" :flag_fe:"}
	{\\ud83c\\uddeb\\ud83c\\uddeb}	{" :flag_ff:"}
	{\\ud83c\\uddeb\\ud83c\\uddec}	{" :flag_fg:"}
	{\\ud83c\\uddeb\\ud83c\\udded}	{" :flag_fh:"}
	{\\ud83c\\uddeb\\ud83c\\uddee}	{" :flag_finland:"}
	{\\ud83c\\uddeb\\ud83c\\uddef}	{" :flag_fiji:"}
	{\\ud83c\\uddeb\\ud83c\\uddf0}	{" :flag_falkland_islands:"}
	{\\ud83c\\uddeb\\ud83c\\uddf1}	{" :flag_fl:"}
	{\\ud83c\\uddeb\\ud83c\\uddf2}	{" :flag_micronesia:"}
	{\\ud83c\\uddeb\\ud83c\\uddf3}	{" :flag_fn:"}
	{\\ud83c\\uddeb\\ud83c\\uddf4}	{" :flag_faroe_islands:"}
	{\\ud83c\\uddeb\\ud83c\\uddf5}	{" :flag_fp:"}
	{\\ud83c\\uddeb\\ud83c\\uddf6}	{" :flag_fq:"}
	{\\ud83c\\uddeb\\ud83c\\uddf7}	{" :flag_france:"}
	{\\ud83c\\uddeb\\ud83c\\uddf8}	{" :flag_fs:"}
	{\\ud83c\\uddeb\\ud83c\\uddf9}	{" :flag_ft:"}
	{\\ud83c\\uddeb\\ud83c\\uddfa}	{" :flag_fu:"}
	{\\ud83c\\uddeb\\ud83c\\uddfb}	{" :flag_fv:"}
	{\\ud83c\\uddeb\\ud83c\\uddfc}	{" :flag_fw:"}
	{\\ud83c\\uddeb\\ud83c\\uddfd}	{" :flag_fx:"}
	{\\ud83c\\uddeb\\ud83c\\uddfe}	{" :flag_fy:"}
	{\\ud83c\\uddeb\\ud83c\\uddff}	{" :flag_fz:"}
	{\\ud83c\\uddec\\ud83c\\udde6}	{" :flag_gabon:"}
	{\\ud83c\\uddec\\ud83c\\udde7}	{" :flag_great_brittain:"}
	{\\ud83c\\uddec\\ud83c\\udde8}	{" :flag_gc:"}
	{\\ud83c\\uddec\\ud83c\\udde9}	{" :flag_grenada:"}
	{\\ud83c\\uddec\\ud83c\\uddea}	{" :flag_georgia:"}
	{\\ud83c\\uddec\\ud83c\\uddeb}	{" :flag_french_guiana:"}
	{\\ud83c\\uddec\\ud83c\\uddec}	{" :flag_guernsey:"}
	{\\ud83c\\uddec\\ud83c\\udded}	{" :flag_ghana:"}
	{\\ud83c\\uddec\\ud83c\\uddee}	{" :flag_gibraltar:"}
	{\\ud83c\\uddec\\ud83c\\uddef}	{" :flag_gj:"}
	{\\ud83c\\uddec\\ud83c\\uddf0}	{" :flag_gk:"}
	{\\ud83c\\uddec\\ud83c\\uddf1}	{" :flag_greenland:"}
	{\\ud83c\\uddec\\ud83c\\uddf2}	{" :flag_gambia:"}
	{\\ud83c\\uddec\\ud83c\\uddf3}	{" :flag_guinea:"}
	{\\ud83c\\uddec\\ud83c\\uddf4}	{" :flag_go:"}
	{\\ud83c\\uddec\\ud83c\\uddf5}	{" :flag_guadeloupe:"}
	{\\ud83c\\uddec\\ud83c\\uddf6}	{" :flag_equatorial_guinea:"}
	{\\ud83c\\uddec\\ud83c\\uddf7}	{" :flag_greece:"}
	{\\ud83c\\uddec\\ud83c\\uddf8}	{" :flag_south_georgia:"}
	{\\ud83c\\uddec\\ud83c\\uddf9}	{" :flag_guatemala:"}
	{\\ud83c\\uddec\\ud83c\\uddfa}	{" :flag_guam:"}
	{\\ud83c\\uddec\\ud83c\\uddfb}	{" :flag_gv:"}
	{\\ud83c\\uddec\\ud83c\\uddfc}	{" :flag_guinea_bissau:"}
	{\\ud83c\\uddec\\ud83c\\uddfd}	{" :flag_gx:"}
	{\\ud83c\\uddec\\ud83c\\uddfe}	{" :flag_guyana:"}
	{\\ud83c\\uddec\\ud83c\\uddff}	{" :flag_gz:"}
	{\\ud83c\\udded\\ud83c\\udde6}	{" :flag_ha:"}
	{\\ud83c\\udded\\ud83c\\udde7}	{" :flag_hb:"}
	{\\ud83c\\udded\\ud83c\\udde8}	{" :flag_hc:"}
	{\\ud83c\\udded\\ud83c\\udde9}	{" :flag_hd:"}
	{\\ud83c\\udded\\ud83c\\uddea}	{" :flag_he:"}
	{\\ud83c\\udded\\ud83c\\uddeb}	{" :flag_hf:"}
	{\\ud83c\\udded\\ud83c\\uddec}	{" :flag_hg:"}
	{\\ud83c\\udded\\ud83c\\udded}	{" :flag_hh:"}
	{\\ud83c\\udded\\ud83c\\uddee}	{" :flag_hi:"}
	{\\ud83c\\udded\\ud83c\\uddef}	{" :flag_hj:"}
	{\\ud83c\\udded\\ud83c\\uddf0}	{" :flag_hong_kong:"}
	{\\ud83c\\udded\\ud83c\\uddf1}	{" :flag_hl:"}
	{\\ud83c\\udded\\ud83c\\uddf2}	{" :flag_heard_islands:"}
	{\\ud83c\\udded\\ud83c\\uddf3}	{" :flag_honduras:"}
	{\\ud83c\\udded\\ud83c\\uddf4}	{" :flag_ho:"}
	{\\ud83c\\udded\\ud83c\\uddf5}	{" :flag_hp:"}
	{\\ud83c\\udded\\ud83c\\uddf6}	{" :flag_hq:"}
	{\\ud83c\\udded\\ud83c\\uddf7}	{" :flag_croatia:"}
	{\\ud83c\\udded\\ud83c\\uddf8}	{" :flag_hs:"}
	{\\ud83c\\udded\\ud83c\\uddf9}	{" :flag_haiti:"}
	{\\ud83c\\udded\\ud83c\\uddfa}	{" :flag_hungary:"}
	{\\ud83c\\udded\\ud83c\\uddfb}	{" :flag_hv:"}
	{\\ud83c\\udded\\ud83c\\uddfc}	{" :flag_hw:"}
	{\\ud83c\\udded\\ud83c\\uddfd}	{" :flag_hx:"}
	{\\ud83c\\udded\\ud83c\\uddfe}	{" :flag_hy:"}
	{\\ud83c\\udded\\ud83c\\uddff}	{" :flag_hz:"}
	{\\ud83c\\uddee\\ud83c\\udde6}	{" :flag_ia:"}
	{\\ud83c\\uddee\\ud83c\\udde7}	{" :flag_ib:"}
	{\\ud83c\\uddee\\ud83c\\udde8}	{" :flag_canary_islands:"}
	{\\ud83c\\uddee\\ud83c\\udde9}	{" :flag_indonesia:"}
	{\\ud83c\\uddee\\ud83c\\uddea}	{" :flag_ireland:"}
	{\\ud83c\\uddee\\ud83c\\uddeb}	{" :flag_if:"}
	{\\ud83c\\uddee\\ud83c\\uddec}	{" :flag_ig:"}
	{\\ud83c\\uddee\\ud83c\\udded}	{" :flag_ih:"}
	{\\ud83c\\uddee\\ud83c\\uddee}	{" :flag_ii:"}
	{\\ud83c\\uddee\\ud83c\\uddef}	{" :flag_ij:"}
	{\\ud83c\\uddee\\ud83c\\uddf0}	{" :flag_ik:"}
	{\\ud83c\\uddee\\ud83c\\uddf1}	{" :flag_israel:"}
	{\\ud83c\\uddee\\ud83c\\uddf2}	{" :flag_isle_of_man:"}
	{\\ud83c\\uddee\\ud83c\\uddf3}	{" :flag_india:"}
	{\\ud83c\\uddee\\ud83c\\uddf4}	{" :flag_io:"}
	{\\ud83c\\uddee\\ud83c\\uddf5}	{" :flag_ip:"}
	{\\ud83c\\uddee\\ud83c\\uddf6}	{" :flag_iraq:"}
	{\\ud83c\\uddee\\ud83c\\uddf7}	{" :flag_iran:"}
	{\\ud83c\\uddee\\ud83c\\uddf8}	{" :flag_iceland:"}
	{\\ud83c\\uddee\\ud83c\\uddf9}	{" :flag_italy:"}
	{\\ud83c\\uddee\\ud83c\\uddfa}	{" :flag_iu:"}
	{\\ud83c\\uddee\\ud83c\\uddfb}	{" :flag_iv:"}
	{\\ud83c\\uddee\\ud83c\\uddfc}	{" :flag_iw:"}
	{\\ud83c\\uddee\\ud83c\\uddfd}	{" :flag_ix:"}
	{\\ud83c\\uddee\\ud83c\\uddfe}	{" :flag_iy:"}
	{\\ud83c\\uddee\\ud83c\\uddff}	{" :flag_iz:"}
	{\\ud83c\\uddef\\ud83c\\udde6}	{" :flag_ja:"}
	{\\ud83c\\uddef\\ud83c\\udde7}	{" :flag_jb:"}
	{\\ud83c\\uddef\\ud83c\\udde8}	{" :flag_jc:"}
	{\\ud83c\\uddef\\ud83c\\udde9}	{" :flag_jd:"}
	{\\ud83c\\uddef\\ud83c\\uddea}	{" :flag_jersey:"}
	{\\ud83c\\uddef\\ud83c\\uddeb}	{" :flag_jf:"}
	{\\ud83c\\uddef\\ud83c\\uddec}	{" :flag_jg:"}
	{\\ud83c\\uddef\\ud83c\\udded}	{" :flag_jh:"}
	{\\ud83c\\uddef\\ud83c\\uddee}	{" :flag_ji:"}
	{\\ud83c\\uddef\\ud83c\\uddef}	{" :flag_jj:"}
	{\\ud83c\\uddef\\ud83c\\uddf0}	{" :flag_jk:"}
	{\\ud83c\\uddef\\ud83c\\uddf1}	{" :flag_jl:"}
	{\\ud83c\\uddef\\ud83c\\uddf2}	{" :flag_jamaica:"}
	{\\ud83c\\uddef\\ud83c\\uddf3}	{" :flag_jn:"}
	{\\ud83c\\uddef\\ud83c\\uddf4}	{" :flag_jordan:"}
	{\\ud83c\\uddef\\ud83c\\uddf5}	{" :flag_japan:"}
	{\\ud83c\\uddef\\ud83c\\uddf6}	{" :flag_jq:"}
	{\\ud83c\\uddef\\ud83c\\uddf7}	{" :flag_jr:"}
	{\\ud83c\\uddef\\ud83c\\uddf8}	{" :flag_js:"}
	{\\ud83c\\uddef\\ud83c\\uddf9}	{" :flag_jt:"}
	{\\ud83c\\uddef\\ud83c\\uddfa}	{" :flag_ju:"}
	{\\ud83c\\uddef\\ud83c\\uddfb}	{" :flag_jv:"}
	{\\ud83c\\uddef\\ud83c\\uddfc}	{" :flag_jw:"}
	{\\ud83c\\uddef\\ud83c\\uddfd}	{" :flag_jx:"}
	{\\ud83c\\uddef\\ud83c\\uddfe}	{" :flag_jy:"}
	{\\ud83c\\uddef\\ud83c\\uddff}	{" :flag_jz:"}
	{\\ud83c\\uddf0\\ud83c\\udde6}	{" :flag_ka:"}
	{\\ud83c\\uddf0\\ud83c\\udde7}	{" :flag_kb:"}
	{\\ud83c\\uddf0\\ud83c\\udde8}	{" :flag_kc:"}
	{\\ud83c\\uddf0\\ud83c\\udde9}	{" :flag_kd:"}
	{\\ud83c\\uddf0\\ud83c\\uddea}	{" :flag_kenya:"}
	{\\ud83c\\uddf0\\ud83c\\uddeb}	{" :flag_kf:"}
	{\\ud83c\\uddf0\\ud83c\\uddec}	{" :flag_kyrgyzstan:"}
	{\\ud83c\\uddf0\\ud83c\\udded}	{" :flag_cambodia:"}
	{\\ud83c\\uddf0\\ud83c\\uddee}	{" :flag_kiribati:"}
	{\\ud83c\\uddf0\\ud83c\\uddef}	{" :flag_kj:"}
	{\\ud83c\\uddf0\\ud83c\\uddf0}	{" :flag_kk:"}
	{\\ud83c\\uddf0\\ud83c\\uddf1}	{" :flag_kl:"}
	{\\ud83c\\uddf0\\ud83c\\uddf2}	{" :flag_comoros:"}
	{\\ud83c\\uddf0\\ud83c\\uddf3}	{" :flag_saint_kitts_and_nevis:"}
	{\\ud83c\\uddf0\\ud83c\\uddf4}	{" :flag_ko:"}
	{\\ud83c\\uddf0\\ud83c\\uddf5}	{" :flag_north_korea:"}
	{\\ud83c\\uddf0\\ud83c\\uddf6}	{" :flag_kq:"}
	{\\ud83c\\uddf0\\ud83c\\uddf7}	{" :flag_south_korea:"}
	{\\ud83c\\uddf0\\ud83c\\uddf8}	{" :flag_ks:"}
	{\\ud83c\\uddf0\\ud83c\\uddf9}	{" :flag_kt:"}
	{\\ud83c\\uddf0\\ud83c\\uddfa}	{" :flag_ku:"}
	{\\ud83c\\uddf0\\ud83c\\uddfb}	{" :flag_kv:"}
	{\\ud83c\\uddf0\\ud83c\\uddfc}	{" :flag_kuwait:"}
	{\\ud83c\\uddf0\\ud83c\\uddfd}	{" :flag_kx:"}
	{\\ud83c\\uddf0\\ud83c\\uddfe}	{" :flag_cayman_islands:"}
	{\\ud83c\\uddf0\\ud83c\\uddff}	{" :flag_kazakhstan:"}
	{\\ud83c\\uddf1\\ud83c\\udde6}	{" :flag_laos:"}
	{\\ud83c\\uddf1\\ud83c\\udde7}	{" :flag_lebanon:"}
	{\\ud83c\\uddf1\\ud83c\\udde8}	{" :flag_saint_lucia:"}
	{\\ud83c\\uddf1\\ud83c\\udde9}	{" :flag_ld:"}
	{\\ud83c\\uddf1\\ud83c\\uddea}	{" :flag_le:"}
	{\\ud83c\\uddf1\\ud83c\\uddeb}	{" :flag_lf:"}
	{\\ud83c\\uddf1\\ud83c\\uddec}	{" :flag_lg:"}
	{\\ud83c\\uddf1\\ud83c\\udded}	{" :flag_lh:"}
	{\\ud83c\\uddf1\\ud83c\\uddee}	{" :flag_liechtenstein:"}
	{\\ud83c\\uddf1\\ud83c\\uddef}	{" :flag_lj:"}
	{\\ud83c\\uddf1\\ud83c\\uddf0}	{" :flag_sri_lanka:"}
	{\\ud83c\\uddf1\\ud83c\\uddf1}	{" :flag_ll:"}
	{\\ud83c\\uddf1\\ud83c\\uddf2}	{" :flag_lm:"}
	{\\ud83c\\uddf1\\ud83c\\uddf3}	{" :flag_ln:"}
	{\\ud83c\\uddf1\\ud83c\\uddf4}	{" :flag_lo:"}
	{\\ud83c\\uddf1\\ud83c\\uddf5}	{" :flag_lp:"}
	{\\ud83c\\uddf1\\ud83c\\uddf6}	{" :flag_lq:"}
	{\\ud83c\\uddf1\\ud83c\\uddf7}	{" :flag_liberia:"}
	{\\ud83c\\uddf1\\ud83c\\uddf8}	{" :flag_lesotho:"}
	{\\ud83c\\uddf1\\ud83c\\uddf9}	{" :flag_lithuania:"}
	{\\ud83c\\uddf1\\ud83c\\uddfa}	{" :flag_luxembourg:"}
	{\\ud83c\\uddf1\\ud83c\\uddfb}	{" :flag_latvia:"}
	{\\ud83c\\uddf1\\ud83c\\uddfc}	{" :flag_lw:"}
	{\\ud83c\\uddf1\\ud83c\\uddfd}	{" :flag_lx:"}
	{\\ud83c\\uddf1\\ud83c\\uddfe}	{" :flag_libya:"}
	{\\ud83c\\uddf1\\ud83c\\uddff}	{" :flag_lz:"}
	{\\ud83c\\uddf2\\ud83c\\udde6}	{" :flag_marocco:"}
	{\\ud83c\\uddf2\\ud83c\\udde7}	{" :flag_mb:"}
	{\\ud83c\\uddf2\\ud83c\\udde8}	{" :flag_monaco:"}
	{\\ud83c\\uddf2\\ud83c\\udde9}	{" :flag_moldova:"}
	{\\ud83c\\uddf2\\ud83c\\uddea}	{" :flag_montenegro:"}
	{\\ud83c\\uddf2\\ud83c\\uddeb}	{" :flag_saint_martin:"}
	{\\ud83c\\uddf2\\ud83c\\uddec}	{" :flag_madagascar:"}
	{\\ud83c\\uddf2\\ud83c\\udded}	{" :flag_marshall_islands:"}
	{\\ud83c\\uddf2\\ud83c\\uddee}	{" :flag_mi:"}
	{\\ud83c\\uddf2\\ud83c\\uddef}	{" :flag_mj:"}
	{\\ud83c\\uddf2\\ud83c\\uddf0}	{" :flag_macedonia:"}
	{\\ud83c\\uddf2\\ud83c\\uddf1}	{" :flag_mali:"}
	{\\ud83c\\uddf2\\ud83c\\uddf2}	{" :flag_myanmar:"}
	{\\ud83c\\uddf2\\ud83c\\uddf3}	{" :flag_mongolia:"}
	{\\ud83c\\uddf2\\ud83c\\uddf4}	{" :flag_macao:"}
	{\\ud83c\\uddf2\\ud83c\\uddf5}	{" :flag_northern_mariana_islands:"}
	{\\ud83c\\uddf2\\ud83c\\uddf6}	{" :flag_martinique:"}
	{\\ud83c\\uddf2\\ud83c\\uddf7}	{" :flag_mauritania:"}
	{\\ud83c\\uddf2\\ud83c\\uddf8}	{" :flag_montserrat:"}
	{\\ud83c\\uddf2\\ud83c\\uddf9}	{" :flag_malta:"}
	{\\ud83c\\uddf2\\ud83c\\uddfa}	{" :flag_mauritius:"}
	{\\ud83c\\uddf2\\ud83c\\uddfb}	{" :flag_maldives:"}
	{\\ud83c\\uddf2\\ud83c\\uddfc}	{" :flag_malawi:"}
	{\\ud83c\\uddf2\\ud83c\\uddfd}	{" :flag_mexico:"}
	{\\ud83c\\uddf2\\ud83c\\uddfe}	{" :flag_malaysia:"}
	{\\ud83c\\uddf2\\ud83c\\uddff}	{" :flag_mozambique:"}
	{\\ud83c\\uddf3\\ud83c\\udde6}	{" :flag_namibia:"}
	{\\ud83c\\uddf3\\ud83c\\udde7}	{" :flag_nb:"}
	{\\ud83c\\uddf3\\ud83c\\udde8}	{" :flag_new_caledonia:"}
	{\\ud83c\\uddf3\\ud83c\\udde9}	{" :flag_nd:"}
	{\\ud83c\\uddf3\\ud83c\\uddea}	{" :flag_niger:"}
	{\\ud83c\\uddf3\\ud83c\\uddeb}	{" :flag_norfolk_island:"}
	{\\ud83c\\uddf3\\ud83c\\uddec}	{" :flag_nigeria:"}
	{\\ud83c\\uddf3\\ud83c\\udded}	{" :flag_nh:"}
	{\\ud83c\\uddf3\\ud83c\\uddee}	{" :flag_nicaragua:"}
	{\\ud83c\\uddf3\\ud83c\\uddef}	{" :flag_nj:"}
	{\\ud83c\\uddf3\\ud83c\\uddf0}	{" :flag_nk:"}
	{\\ud83c\\uddf3\\ud83c\\uddf1}	{" :flag_netherlands:"}
	{\\ud83c\\uddf3\\ud83c\\uddf2}	{" :flag_nm:"}
	{\\ud83c\\uddf3\\ud83c\\uddf3}	{" :flag_nn:"}
	{\\ud83c\\uddf3\\ud83c\\uddf4}	{" :flag_norway:"}
	{\\ud83c\\uddf3\\ud83c\\uddf5}	{" :flag_nepal:"}
	{\\ud83c\\uddf3\\ud83c\\uddf6}	{" :flag_nq:"}
	{\\ud83c\\uddf3\\ud83c\\uddf7}	{" :flag_nauru:"}
	{\\ud83c\\uddf3\\ud83c\\uddf8}	{" :flag_ns:"}
	{\\ud83c\\uddf3\\ud83c\\uddf9}	{" :flag_nt:"}
	{\\ud83c\\uddf3\\ud83c\\uddfa}	{" :flag_niue:"}
	{\\ud83c\\uddf3\\ud83c\\uddfb}	{" :flag_nv:"}
	{\\ud83c\\uddf3\\ud83c\\uddfc}	{" :flag_nw:"}
	{\\ud83c\\uddf3\\ud83c\\uddfd}	{" :flag_nx:"}
	{\\ud83c\\uddf3\\ud83c\\uddfe}	{" :flag_ny:"}
	{\\ud83c\\uddf3\\ud83c\\uddff}	{" :flag_new_zealand:"}
	{\\ud83c\\uddf4\\ud83c\\udde6}	{" :flag_oa:"}
	{\\ud83c\\uddf4\\ud83c\\udde7}	{" :flag_ob:"}
	{\\ud83c\\uddf4\\ud83c\\udde8}	{" :flag_oc:"}
	{\\ud83c\\uddf4\\ud83c\\udde9}	{" :flag_od:"}
	{\\ud83c\\uddf4\\ud83c\\uddea}	{" :flag_oe:"}
	{\\ud83c\\uddf4\\ud83c\\uddeb}	{" :flag_of:"}
	{\\ud83c\\uddf4\\ud83c\\uddec}	{" :flag_og:"}
	{\\ud83c\\uddf4\\ud83c\\udded}	{" :flag_oh:"}
	{\\ud83c\\uddf4\\ud83c\\uddee}	{" :flag_oi:"}
	{\\ud83c\\uddf4\\ud83c\\uddef}	{" :flag_oj:"}
	{\\ud83c\\uddf4\\ud83c\\uddf0}	{" :flag_ok:"}
	{\\ud83c\\uddf4\\ud83c\\uddf1}	{" :flag_ol:"}
	{\\ud83c\\uddf4\\ud83c\\uddf2}	{" :flag_oman:"}
	{\\ud83c\\uddf4\\ud83c\\uddf3}	{" :flag_on:"}
	{\\ud83c\\uddf4\\ud83c\\uddf4}	{" :flag_oo:"}
	{\\ud83c\\uddf4\\ud83c\\uddf5}	{" :flag_op:"}
	{\\ud83c\\uddf4\\ud83c\\uddf6}	{" :flag_oq:"}
	{\\ud83c\\uddf4\\ud83c\\uddf7}	{" :flag_or:"}
	{\\ud83c\\uddf4\\ud83c\\uddf8}	{" :flag_os:"}
	{\\ud83c\\uddf4\\ud83c\\uddf9}	{" :flag_ot:"}
	{\\ud83c\\uddf4\\ud83c\\uddfa}	{" :flag_ou:"}
	{\\ud83c\\uddf4\\ud83c\\uddfb}	{" :flag_ov:"}
	{\\ud83c\\uddf4\\ud83c\\uddfc}	{" :flag_ow:"}
	{\\ud83c\\uddf4\\ud83c\\uddfd}	{" :flag_ox:"}
	{\\ud83c\\uddf4\\ud83c\\uddfe}	{" :flag_oy:"}
	{\\ud83c\\uddf4\\ud83c\\uddff}	{" :flag_oz:"}
	{\\ud83c\\uddf5\\ud83c\\udde6}	{" :flag_panama:"}
	{\\ud83c\\uddf5\\ud83c\\udde7}	{" :flag_pb:"}
	{\\ud83c\\uddf5\\ud83c\\udde8}	{" :flag_pc:"}
	{\\ud83c\\uddf5\\ud83c\\udde9}	{" :flag_pd:"}
	{\\ud83c\\uddf5\\ud83c\\uddea}	{" :flag_peru:"}
	{\\ud83c\\uddf5\\ud83c\\uddeb}	{" :flag_french_polynesia:"}
	{\\ud83c\\uddf5\\ud83c\\uddec}	{" :flag_papua_new_guinea:"}
	{\\ud83c\\uddf5\\ud83c\\udded}	{" :flag_philipines:"}
	{\\ud83c\\uddf5\\ud83c\\uddee}	{" :flag_pi:"}
	{\\ud83c\\uddf5\\ud83c\\uddef}	{" :flag_pj:"}
	{\\ud83c\\uddf5\\ud83c\\uddf0}	{" :flag_pakistan:"}
	{\\ud83c\\uddf5\\ud83c\\uddf1}	{" :flag_poland:"}
	{\\ud83c\\uddf5\\ud83c\\uddf2}	{" :flag_saint_pierre_and_iquelon:"}
	{\\ud83c\\uddf5\\ud83c\\uddf3}	{" :flag_pitcairn:"}
	{\\ud83c\\uddf5\\ud83c\\uddf4}	{" :flag_po:"}
	{\\ud83c\\uddf5\\ud83c\\uddf5}	{" :flag_pp:"}
	{\\ud83c\\uddf5\\ud83c\\uddf6}	{" :flag_pq:"}
	{\\ud83c\\uddf5\\ud83c\\uddf7}	{" :flag_puerto_rico:"}
	{\\ud83c\\uddf5\\ud83c\\uddf8}	{" :flag_palestine:"}
	{\\ud83c\\uddf5\\ud83c\\uddf9}	{" :flag_portugal:"}
	{\\ud83c\\uddf5\\ud83c\\uddfa}	{" :flag_pu:"}
	{\\ud83c\\uddf5\\ud83c\\uddfb}	{" :flag_pv:"}
	{\\ud83c\\uddf5\\ud83c\\uddfc}	{" :flag_palau:"}
	{\\ud83c\\uddf5\\ud83c\\uddfd}	{" :flag_px:"}
	{\\ud83c\\uddf5\\ud83c\\uddfe}	{" :flag_paraguay:"}
	{\\ud83c\\uddf5\\ud83c\\uddff}	{" :flag_pz:"}
	{\\ud83c\\uddf6\\ud83c\\udde6}	{" :flag_qatar:"}
	{\\ud83c\\uddf6\\ud83c\\udde7}	{" :flag_qb:"}
	{\\ud83c\\uddf6\\ud83c\\udde8}	{" :flag_qc:"}
	{\\ud83c\\uddf6\\ud83c\\udde9}	{" :flag_qd:"}
	{\\ud83c\\uddf6\\ud83c\\uddea}	{" :flag_qe:"}
	{\\ud83c\\uddf6\\ud83c\\uddeb}	{" :flag_qf:"}
	{\\ud83c\\uddf6\\ud83c\\uddec}	{" :flag_qg:"}
	{\\ud83c\\uddf6\\ud83c\\udded}	{" :flag_qh:"}
	{\\ud83c\\uddf6\\ud83c\\uddee}	{" :flag_qi:"}
	{\\ud83c\\uddf6\\ud83c\\uddef}	{" :flag_qj:"}
	{\\ud83c\\uddf6\\ud83c\\uddf0}	{" :flag_qk:"}
	{\\ud83c\\uddf6\\ud83c\\uddf1}	{" :flag_ql:"}
	{\\ud83c\\uddf6\\ud83c\\uddf2}	{" :flag_qm:"}
	{\\ud83c\\uddf6\\ud83c\\uddf3}	{" :flag_qn:"}
	{\\ud83c\\uddf6\\ud83c\\uddf4}	{" :flag_qo:"}
	{\\ud83c\\uddf6\\ud83c\\uddf5}	{" :flag_qp:"}
	{\\ud83c\\uddf6\\ud83c\\uddf6}	{" :flag_qq:"}
	{\\ud83c\\uddf6\\ud83c\\uddf7}	{" :flag_qr:"}
	{\\ud83c\\uddf6\\ud83c\\uddf8}	{" :flag_qs:"}
	{\\ud83c\\uddf6\\ud83c\\uddf9}	{" :flag_qt:"}
	{\\ud83c\\uddf6\\ud83c\\uddfa}	{" :flag_qu:"}
	{\\ud83c\\uddf6\\ud83c\\uddfb}	{" :flag_qv:"}
	{\\ud83c\\uddf6\\ud83c\\uddfc}	{" :flag_qw:"}
	{\\ud83c\\uddf6\\ud83c\\uddfd}	{" :flag_qx:"}
	{\\ud83c\\uddf6\\ud83c\\uddfe}	{" :flag_qy:"}
	{\\ud83c\\uddf6\\ud83c\\uddff}	{" :flag_qz:"}
	{\\ud83c\\uddf7\\ud83c\\udde6}	{" :flag_ra:"}
	{\\ud83c\\uddf7\\ud83c\\udde7}	{" :flag_rb:"}
	{\\ud83c\\uddf7\\ud83c\\udde8}	{" :flag_rc:"}
	{\\ud83c\\uddf7\\ud83c\\udde9}	{" :flag_rd:"}
	{\\ud83c\\uddf7\\ud83c\\uddea}	{" :flag_reunion:"}
	{\\ud83c\\uddf7\\ud83c\\uddeb}	{" :flag_rf:"}
	{\\ud83c\\uddf7\\ud83c\\uddec}	{" :flag_rg:"}
	{\\ud83c\\uddf7\\ud83c\\udded}	{" :flag_rh:"}
	{\\ud83c\\uddf7\\ud83c\\uddee}	{" :flag_ri:"}
	{\\ud83c\\uddf7\\ud83c\\uddef}	{" :flag_rj:"}
	{\\ud83c\\uddf7\\ud83c\\uddf0}	{" :flag_rk:"}
	{\\ud83c\\uddf7\\ud83c\\uddf1}	{" :flag_rl:"}
	{\\ud83c\\uddf7\\ud83c\\uddf2}	{" :flag_rm:"}
	{\\ud83c\\uddf7\\ud83c\\uddf3}	{" :flag_rn:"}
	{\\ud83c\\uddf7\\ud83c\\uddf4}	{" :flag_romania:"}
	{\\ud83c\\uddf7\\ud83c\\uddf5}	{" :flag_rp:"}
	{\\ud83c\\uddf7\\ud83c\\uddf6}	{" :flag_rq:"}
	{\\ud83c\\uddf7\\ud83c\\uddf7}	{" :flag_rr:"}
	{\\ud83c\\uddf7\\ud83c\\uddf8}	{" :flag_serbia:"}
	{\\ud83c\\uddf7\\ud83c\\uddf9}	{" :flag_rt:"}
	{\\ud83c\\uddf7\\ud83c\\uddfa}	{" :flag_russia:"}
	{\\ud83c\\uddf7\\ud83c\\uddfb}	{" :flag_rv:"}
	{\\ud83c\\uddf7\\ud83c\\uddfc}	{" :flag_rwanda:"}
	{\\ud83c\\uddf7\\ud83c\\uddfd}	{" :flag_rx:"}
	{\\ud83c\\uddf7\\ud83c\\uddfe}	{" :flag_ry:"}
	{\\ud83c\\uddf7\\ud83c\\uddff}	{" :flag_rz:"}
	{\\ud83c\\uddf8\\ud83c\\udde6}	{" :flag_saudi_arabia:"}
	{\\ud83c\\uddf8\\ud83c\\udde7}	{" :flag_solomon_islands:"}
	{\\ud83c\\uddf8\\ud83c\\udde8}	{" :flag_seychelles:"}
	{\\ud83c\\uddf8\\ud83c\\udde9}	{" :flag_sudan:"}
	{\\ud83c\\uddf8\\ud83c\\uddea}	{" :flag_sweden:"}
	{\\ud83c\\uddf8\\ud83c\\uddeb}	{" :flag_sf:"}
	{\\ud83c\\uddf8\\ud83c\\uddec}	{" :flag_singapore:"}
	{\\ud83c\\uddf8\\ud83c\\udded}	{" :flag_saint_helena:"}
	{\\ud83c\\uddf8\\ud83c\\uddee}	{" :flag_slovenia:"}
	{\\ud83c\\uddf8\\ud83c\\uddef}	{" :flag_svalbard_and_jan_mayen:"}
	{\\ud83c\\uddf8\\ud83c\\uddf0}	{" :flag_slovakia:"}
	{\\ud83c\\uddf8\\ud83c\\uddf1}	{" :flag_sierra_leone:"}
	{\\ud83c\\uddf8\\ud83c\\uddf2}	{" :flag_san_marino:"}
	{\\ud83c\\uddf8\\ud83c\\uddf3}	{" :flag_senegal:"}
	{\\ud83c\\uddf8\\ud83c\\uddf4}	{" :flag_somalia:"}
	{\\ud83c\\uddf8\\ud83c\\uddf5}	{" :flag_sp:"}
	{\\ud83c\\uddf8\\ud83c\\uddf6}	{" :flag_sq:"}
	{\\ud83c\\uddf8\\ud83c\\uddf7}	{" :flag_suriname:"}
	{\\ud83c\\uddf8\\ud83c\\uddf8}	{" :flag_south_sudan:"}
	{\\ud83c\\uddf8\\ud83c\\uddf9}	{" :flag_sao_tome_and_principe:"}
	{\\ud83c\\uddf8\\ud83c\\uddfa}	{" :flag_su:"}
	{\\ud83c\\uddf8\\ud83c\\uddfb}	{" :flag_el_salvador:"}
	{\\ud83c\\uddf8\\ud83c\\uddfc}	{" :flag_sw:"}
	{\\ud83c\\uddf8\\ud83c\\uddfd}	{" :flag_sint_maarten:"}
	{\\ud83c\\uddf8\\ud83c\\uddfe}	{" :flag_syria:"}
	{\\ud83c\\uddf8\\ud83c\\uddff}	{" :flag_swaziland:"}
	{\\ud83c\\uddf9\\ud83c\\udde6}	{" :flag_ta:"}
	{\\ud83c\\uddf9\\ud83c\\udde7}	{" :flag_tb:"}
	{\\ud83c\\uddf9\\ud83c\\udde8}	{" :flag_turks_and_caicos_islands:"}
	{\\ud83c\\uddf9\\ud83c\\udde9}	{" :flag_chad:"}
	{\\ud83c\\uddf9\\ud83c\\uddea}	{" :flag_te:"}
	{\\ud83c\\uddf9\\ud83c\\uddeb}	{" :flag_french_southern_territories:"}
	{\\ud83c\\uddf9\\ud83c\\uddec}	{" :flag_togo:"}
	{\\ud83c\\uddf9\\ud83c\\udded}	{" :flag_thailand:"}
	{\\ud83c\\uddf9\\ud83c\\uddee}	{" :flag_ti:"}
	{\\ud83c\\uddf9\\ud83c\\uddef}	{" :flag_tajikistan:"}
	{\\ud83c\\uddf9\\ud83c\\uddf0}	{" :flag_tokelau:"}
	{\\ud83c\\uddf9\\ud83c\\uddf1}	{" :flag_timor_leste:"}
	{\\ud83c\\uddf9\\ud83c\\uddf2}	{" :flag_turkmenistan:"}
	{\\ud83c\\uddf9\\ud83c\\uddf3}	{" :flag_tunisia:"}
	{\\ud83c\\uddf9\\ud83c\\uddf4}	{" :flag_tonga:"}
	{\\ud83c\\uddf9\\ud83c\\uddf5}	{" :flag_tp:"}
	{\\ud83c\\uddf9\\ud83c\\uddf6}	{" :flag_tq:"}
	{\\ud83c\\uddf9\\ud83c\\uddf7}	{" :flag_turkey:"}
	{\\ud83c\\uddf9\\ud83c\\uddf8}	{" :flag_ts:"}
	{\\ud83c\\uddf9\\ud83c\\uddf9}	{" :flag_trinidad_and_tobago:"}
	{\\ud83c\\uddf9\\ud83c\\uddfa}	{" :flag_tu:"}
	{\\ud83c\\uddf9\\ud83c\\uddfb}	{" :flag_tuvalu:"}
	{\\ud83c\\uddf9\\ud83c\\uddfc}	{" :flag_taiwan:"}
	{\\ud83c\\uddf9\\ud83c\\uddfd}	{" :flag_tx:"}
	{\\ud83c\\uddf9\\ud83c\\uddfe}	{" :flag_ty:"}
	{\\ud83c\\uddf9\\ud83c\\uddff}	{" :flag_tanzania:"}
	{\\ud83c\\uddfa\\ud83c\\udde6}	{" :flag_ukraine:"}
	{\\ud83c\\uddfa\\ud83c\\udde7}	{" :flag_ub:"}
	{\\ud83c\\uddfa\\ud83c\\udde8}	{" :flag_uc:"}
	{\\ud83c\\uddfa\\ud83c\\udde9}	{" :flag_ud:"}
	{\\ud83c\\uddfa\\ud83c\\uddea}	{" :flag_ue:"}
	{\\ud83c\\uddfa\\ud83c\\uddeb}	{" :flag_uf:"}
	{\\ud83c\\uddfa\\ud83c\\uddec}	{" :flag_uganda:"}
	{\\ud83c\\uddfa\\ud83c\\udded}	{" :flag_uh:"}
	{\\ud83c\\uddfa\\ud83c\\uddee}	{" :flag_ui:"}
	{\\ud83c\\uddfa\\ud83c\\uddef}	{" :flag_uj:"}
	{\\ud83c\\uddfa\\ud83c\\uddf0}	{" :flag_united_kingdom:"}
	{\\ud83c\\uddfa\\ud83c\\uddf1}	{" :flag_ul:"}
	{\\ud83c\\uddfa\\ud83c\\uddf2}	{" :flag_us_minor_outlying_islands:"}
	{\\ud83c\\uddfa\\ud83c\\uddf3}	{" :flag_un:"}
	{\\ud83c\\uddfa\\ud83c\\uddf4}	{" :flag_uo:"}
	{\\ud83c\\uddfa\\ud83c\\uddf5}	{" :flag_up:"}
	{\\ud83c\\uddfa\\ud83c\\uddf6}	{" :flag_uq:"}
	{\\ud83c\\uddfa\\ud83c\\uddf7}	{" :flag_ur:"}
	{\\ud83c\\uddfa\\ud83c\\uddf8}	{" :flag_usa:"}
	{\\ud83c\\uddfa\\ud83c\\uddf9}	{" :flag_ut:"}
	{\\ud83c\\uddfa\\ud83c\\uddfa}	{" :flag_uu:"}
	{\\ud83c\\uddfa\\ud83c\\uddfb}	{" :flag_uv:"}
	{\\ud83c\\uddfa\\ud83c\\uddfc}	{" :flag_uw:"}
	{\\ud83c\\uddfa\\ud83c\\uddfd}	{" :flag_ux:"}
	{\\ud83c\\uddfa\\ud83c\\uddfe}	{" :flag_uruguay:"}
	{\\ud83c\\uddfa\\ud83c\\uddff}	{" :flag_uzbekistan:"}
	{\\ud83c\\uddfb\\ud83c\\udde6}	{" :flag_vatican:"}
	{\\ud83c\\uddfb\\ud83c\\udde7}	{" :flag_vb:"}
	{\\ud83c\\uddfb\\ud83c\\udde8}	{" :flag_saint_vincent:"}
	{\\ud83c\\uddfb\\ud83c\\udde9}	{" :flag_vd:"}
	{\\ud83c\\uddfb\\ud83c\\uddea}	{" :flag_venezuela:"}
	{\\ud83c\\uddfb\\ud83c\\uddeb}	{" :flag_vf:"}
	{\\ud83c\\uddfb\\ud83c\\uddec}	{" :flag_virgin_islands_uk:"}
	{\\ud83c\\uddfb\\ud83c\\udded}	{" :flag_vh:"}
	{\\ud83c\\uddfb\\ud83c\\uddee}	{" :flag_virgin_islands_usa:"}
	{\\ud83c\\uddfb\\ud83c\\uddef}	{" :flag_vj:"}
	{\\ud83c\\uddfb\\ud83c\\uddf0}	{" :flag_vk:"}
	{\\ud83c\\uddfb\\ud83c\\uddf1}	{" :flag_vl:"}
	{\\ud83c\\uddfb\\ud83c\\uddf2}	{" :flag_vm:"}
	{\\ud83c\\uddfb\\ud83c\\uddf3}	{" :flag_vietnam:"}
	{\\ud83c\\uddfb\\ud83c\\uddf4}	{" :flag_vo:"}
	{\\ud83c\\uddfb\\ud83c\\uddf5}	{" :flag_vp:"}
	{\\ud83c\\uddfb\\ud83c\\uddf6}	{" :flag_vq:"}
	{\\ud83c\\uddfb\\ud83c\\uddf7}	{" :flag_vr:"}
	{\\ud83c\\uddfb\\ud83c\\uddf8}	{" :flag_vs:"}
	{\\ud83c\\uddfb\\ud83c\\uddf9}	{" :flag_vt:"}
	{\\ud83c\\uddfb\\ud83c\\uddfa}	{" :flag_vanuatu:"}
	{\\ud83c\\uddfb\\ud83c\\uddfb}	{" :flag_vv:"}
	{\\ud83c\\uddfb\\ud83c\\uddfc}	{" :flag_vw:"}
	{\\ud83c\\uddfb\\ud83c\\uddfd}	{" :flag_vx:"}
	{\\ud83c\\uddfb\\ud83c\\uddfe}	{" :flag_vy:"}
	{\\ud83c\\uddfb\\ud83c\\uddff}	{" :flag_vz:"}
	{\\ud83c\\uddfc\\ud83c\\udde6}	{" :flag_wa:"}
	{\\ud83c\\uddfc\\ud83c\\udde7}	{" :flag_wb:"}
	{\\ud83c\\uddfc\\ud83c\\udde8}	{" :flag_wc:"}
	{\\ud83c\\uddfc\\ud83c\\udde9}	{" :flag_wd:"}
	{\\ud83c\\uddfc\\ud83c\\uddea}	{" :flag_we:"}
	{\\ud83c\\uddfc\\ud83c\\uddeb}	{" :flag_wallis_and_futuna:"}
	{\\ud83c\\uddfc\\ud83c\\uddec}	{" :flag_wg:"}
	{\\ud83c\\uddfc\\ud83c\\udded}	{" :flag_wh:"}
	{\\ud83c\\uddfc\\ud83c\\uddee}	{" :flag_wi:"}
	{\\ud83c\\uddfc\\ud83c\\uddef}	{" :flag_wj:"}
	{\\ud83c\\uddfc\\ud83c\\uddf0}	{" :flag_wk:"}
	{\\ud83c\\uddfc\\ud83c\\uddf1}	{" :flag_wl:"}
	{\\ud83c\\uddfc\\ud83c\\uddf2}	{" :flag_wm:"}
	{\\ud83c\\uddfc\\ud83c\\uddf3}	{" :flag_wn:"}
	{\\ud83c\\uddfc\\ud83c\\uddf4}	{" :flag_wo:"}
	{\\ud83c\\uddfc\\ud83c\\uddf5}	{" :flag_wp:"}
	{\\ud83c\\uddfc\\ud83c\\uddf6}	{" :flag_wq:"}
	{\\ud83c\\uddfc\\ud83c\\uddf7}	{" :flag_wr:"}
	{\\ud83c\\uddfc\\ud83c\\uddf8}	{" :flag_samoa:"}
	{\\ud83c\\uddfc\\ud83c\\uddf9}	{" :flag_wt:"}
	{\\ud83c\\uddfc\\ud83c\\uddfa}	{" :flag_wu:"}
	{\\ud83c\\uddfc\\ud83c\\uddfb}	{" :flag_wv:"}
	{\\ud83c\\uddfc\\ud83c\\uddfc}	{" :flag_ww:"}
	{\\ud83c\\uddfc\\ud83c\\uddfd}	{" :flag_wx:"}
	{\\ud83c\\uddfc\\ud83c\\uddfe}	{" :flag_wy:"}
	{\\ud83c\\uddfc\\ud83c\\uddff}	{" :flag_wz:"}
	{\\ud83c\\uddfd\\ud83c\\udde6}	{" :flag_xa:"}
	{\\ud83c\\uddfd\\ud83c\\udde7}	{" :flag_xb:"}
	{\\ud83c\\uddfd\\ud83c\\udde8}	{" :flag_xc:"}
	{\\ud83c\\uddfd\\ud83c\\udde9}	{" :flag_xd:"}
	{\\ud83c\\uddfd\\ud83c\\uddea}	{" :flag_xe:"}
	{\\ud83c\\uddfd\\ud83c\\uddeb}	{" :flag_xf:"}
	{\\ud83c\\uddfd\\ud83c\\uddec}	{" :flag_xg:"}
	{\\ud83c\\uddfd\\ud83c\\udded}	{" :flag_xh:"}
	{\\ud83c\\uddfd\\ud83c\\uddee}	{" :flag_xi:"}
	{\\ud83c\\uddfd\\ud83c\\uddef}	{" :flag_xj:"}
	{\\ud83c\\uddfd\\ud83c\\uddf0}	{" :flag_xk:"}
	{\\ud83c\\uddfd\\ud83c\\uddf1}	{" :flag_xl:"}
	{\\ud83c\\uddfd\\ud83c\\uddf2}	{" :flag_xm:"}
	{\\ud83c\\uddfd\\ud83c\\uddf3}	{" :flag_xn:"}
	{\\ud83c\\uddfd\\ud83c\\uddf4}	{" :flag_xo:"}
	{\\ud83c\\uddfd\\ud83c\\uddf5}	{" :flag_xp:"}
	{\\ud83c\\uddfd\\ud83c\\uddf6}	{" :flag_xq:"}
	{\\ud83c\\uddfd\\ud83c\\uddf7}	{" :flag_xr:"}
	{\\ud83c\\uddfd\\ud83c\\uddf8}	{" :flag_xs:"}
	{\\ud83c\\uddfd\\ud83c\\uddf9}	{" :flag_xt:"}
	{\\ud83c\\uddfd\\ud83c\\uddfa}	{" :flag_xu:"}
	{\\ud83c\\uddfd\\ud83c\\uddfb}	{" :flag_xv:"}
	{\\ud83c\\uddfd\\ud83c\\uddfc}	{" :flag_xw:"}
	{\\ud83c\\uddfd\\ud83c\\uddfd}	{" :flag_xx:"}
	{\\ud83c\\uddfd\\ud83c\\uddfe}	{" :flag_xy:"}
	{\\ud83c\\uddfd\\ud83c\\uddff}	{" :flag_xz:"}
	{\\ud83c\\uddfe\\ud83c\\udde6}	{" :flag_ya:"}
	{\\ud83c\\uddfe\\ud83c\\udde7}	{" :flag_yb:"}
	{\\ud83c\\uddfe\\ud83c\\udde8}	{" :flag_yc:"}
	{\\ud83c\\uddfe\\ud83c\\udde9}	{" :flag_yd:"}
	{\\ud83c\\uddfe\\ud83c\\uddea}	{" :flag_yemen:"}
	{\\ud83c\\uddfe\\ud83c\\uddeb}	{" :flag_yf:"}
	{\\ud83c\\uddfe\\ud83c\\uddec}	{" :flag_yg:"}
	{\\ud83c\\uddfe\\ud83c\\udded}	{" :flag_yh:"}
	{\\ud83c\\uddfe\\ud83c\\uddee}	{" :flag_yi:"}
	{\\ud83c\\uddfe\\ud83c\\uddef}	{" :flag_yj:"}
	{\\ud83c\\uddfe\\ud83c\\uddf0}	{" :flag_yk:"}
	{\\ud83c\\uddfe\\ud83c\\uddf1}	{" :flag_yl:"}
	{\\ud83c\\uddfe\\ud83c\\uddf2}	{" :flag_ym:"}
	{\\ud83c\\uddfe\\ud83c\\uddf3}	{" :flag_yn:"}
	{\\ud83c\\uddfe\\ud83c\\uddf4}	{" :flag_yo:"}
	{\\ud83c\\uddfe\\ud83c\\uddf5}	{" :flag_yp:"}
	{\\ud83c\\uddfe\\ud83c\\uddf6}	{" :flag_yq:"}
	{\\ud83c\\uddfe\\ud83c\\uddf7}	{" :flag_yr:"}
	{\\ud83c\\uddfe\\ud83c\\uddf8}	{" :flag_ys:"}
	{\\ud83c\\uddfe\\ud83c\\uddf9}	{" :flag_mayotte:"}
	{\\ud83c\\uddfe\\ud83c\\uddfa}	{" :flag_yu:"}
	{\\ud83c\\uddfe\\ud83c\\uddfb}	{" :flag_yv:"}
	{\\ud83c\\uddfe\\ud83c\\uddfc}	{" :flag_yw:"}
	{\\ud83c\\uddfe\\ud83c\\uddfd}	{" :flag_yx:"}
	{\\ud83c\\uddfe\\ud83c\\uddfe}	{" :flag_yy:"}
	{\\ud83c\\uddfe\\ud83c\\uddff}	{" :flag_yz:"}
	{\\ud83c\\uddff\\ud83c\\udde6}	{" :flag_south_africa:"}
	{\\ud83c\\uddff\\ud83c\\udde7}	{" :flag_zb:"}
	{\\ud83c\\uddff\\ud83c\\udde8}	{" :flag_zc:"}
	{\\ud83c\\uddff\\ud83c\\udde9}	{" :flag_zd:"}
	{\\ud83c\\uddff\\ud83c\\uddea}	{" :flag_ze:"}
	{\\ud83c\\uddff\\ud83c\\uddeb}	{" :flag_zf:"}
	{\\ud83c\\uddff\\ud83c\\uddec}	{" :flag_zg:"}
	{\\ud83c\\uddff\\ud83c\\udded}	{" :flag_zh:"}
	{\\ud83c\\uddff\\ud83c\\uddee}	{" :flag_zi:"}
	{\\ud83c\\uddff\\ud83c\\uddef}	{" :flag_zj:"}
	{\\ud83c\\uddff\\ud83c\\uddf0}	{" :flag_zk:"}
	{\\ud83c\\uddff\\ud83c\\uddf1}	{" :flag_zl:"}
	{\\ud83c\\uddff\\ud83c\\uddf2}	{" :flag_zambia:"}
	{\\ud83c\\uddff\\ud83c\\uddf3}	{" :flag_zn:"}
	{\\ud83c\\uddff\\ud83c\\uddf4}	{" :flag_zo:"}
	{\\ud83c\\uddff\\ud83c\\uddf5}	{" :flag_zp:"}
	{\\ud83c\\uddff\\ud83c\\uddf6}	{" :flag_zq:"}
	{\\ud83c\\uddff\\ud83c\\uddf7}	{" :flag_zr:"}
	{\\ud83c\\uddff\\ud83c\\uddf8}	{" :flag_zs:"}
	{\\ud83c\\uddff\\ud83c\\uddf9}	{" :flag_zt:"}
	{\\ud83c\\uddff\\ud83c\\uddfa}	{" :flag_zu:"}
	{\\ud83c\\uddff\\ud83c\\uddfb}	{" :flag_zv:"}
	{\\ud83c\\uddff\\ud83c\\uddfc}	{" :flag_zimbabwe:"}
	{\\ud83c\\uddff\\ud83c\\uddfd}	{" :flag_zx:"}
	{\\ud83c\\uddff\\ud83c\\uddfe}	{" :flag_zy:"}
	{\\ud83c\\uddff\\ud83c\\uddff}	{" :flag_zz:"}

	{\\ud83c\\udf00}	{" :cyclone:"}
	{\\ud83c\\udf01}	{" :foggy:"}
	{\\ud83c\\udf02}	{" :umbrella_closed:"}
	{\\ud83c\\udf03}	{" :night_with_stars:"}
	{\\ud83c\\udf04}	{" :sunrise_over_mountains:"}
	{\\ud83c\\udf05}	{" :sunrise:"}
	{\\ud83c\\udf06}	{" :city_sunset:"}
	{\\ud83c\\udf07}	{" :city_sunrise:"}
	{\\ud83c\\udf08}	{" :rainbow:"}
	{\\ud83c\\udf09}	{" :bridge_at_night:"}
	{\\ud83c\\udf0a}	{" :ocean:"}
	{\\ud83c\\udf0b}	{" :volcano:"}
	{\\ud83c\\udf0c}	{" :milky_way:"}
	{\\ud83c\\udf0d}	{" :earth_africa:"}
	{\\ud83c\\udf0e}	{" :earth_americas:"}
	{\\ud83c\\udf0f}	{" :earth_asia:"}
	{\\ud83c\\udf10}	{" :globe_with_meridians:"}
	{\\ud83c\\udf11}	{" :new_moon:"}
	{\\ud83c\\udf12}	{" :waxing_crescent_moon:"}
	{\\ud83c\\udf13}	{" :first_quarter_moon:"}
	{\\ud83c\\udf14}	{" :waxing_gibbous_moon:"}
	{\\ud83c\\udf15}	{" :full_moon:"}
	{\\ud83c\\udf16}	{" :waning_gibbous_moon:"}
	{\\ud83c\\udf17}	{" :last_quarter_moon:"}
	{\\ud83c\\udf18}	{" :waning_crescent_moon:"}
	{\\ud83c\\udf19}	{" :moon_cresent:"}
	{\\ud83c\\udf1a}	{" :new_moon_with_face:"}
	{\\ud83c\\udf1b}	{" :first_quarter_moon_with_face:"}
	{\\ud83c\\udf1c}	{" :last_quarter_moon_with_face:"}
	{\\ud83c\\udf1d}	{" :full_moon_with_face:"}
	{\\ud83c\\udf1e}	{" :sun_with_face:"}
	{\\ud83c\\udf1f}	{" :glowing_star:"}
	{\\ud83c\\udf20}	{" :shooting_star:"}
	{\\ud83c\\udf21}	{" :thermometer:"}
	{\\ud83c\\udf22}	{" :black_drop:"}
	{\\ud83c\\udf23}	{" :white_sun:"}
	{\\ud83c\\udf24}	{" :sun_small_cloud:"}
	{\\ud83c\\udf25}	{" :sun_behind_cloud:"}
	{\\ud83c\\udf26}	{" :sun_rain_cloud:"}
	{\\ud83c\\udf27}	{" :cloud_rain:"}
	{\\ud83c\\udf28}	{" :cloud_snow:"}
	{\\ud83c\\udf29}	{" :cloud_lightning:"}
	{\\ud83c\\udf2a}	{" :tornado:"}
	{\\ud83c\\udf2b}	{" :fog:"}
	{\\ud83c\\udf2c}	{" :wind_blowing_face:"}
	{\\ud83c\\udf2d}	{" :hotdog:"}
	{\\ud83c\\udf2e}	{" :taco:"}
	{\\ud83c\\udf2f}	{" :burrito:"}
	{\\ud83c\\udf30}	{" :chestnut:"}
	{\\ud83c\\udf31}	{" :seedling:"}
	{\\ud83c\\udf32}	{" :evergreen_tree:"}
	{\\ud83c\\udf33}	{" :deciduous_tree:"}
	{\\ud83c\\udf34}	{" :palm_tree:"}
	{\\ud83c\\udf35}	{" :cactus:"}
	{\\ud83c\\udf36}	{" :hot_pepper:"}
	{\\ud83c\\udf37}	{" :tulip:"}
	{\\ud83c\\udf38}	{" :cherry_blossom:"}
	{\\ud83c\\udf39}	{" :rose:"}
	{\\ud83c\\udf3a}	{" :hibiscus:"}
	{\\ud83c\\udf3b}	{" :sunflower:"}
	{\\ud83c\\udf3c}	{" :blossom:"}
	{\\ud83c\\udf3d}	{" :corn:"}
	{\\ud83c\\udf3e}	{" :ear_of_rice:"}
	{\\ud83c\\udf3f}	{" :herb:"}
	{\\ud83c\\udf40}	{" :clover_four:"}
	{\\ud83c\\udf41}	{" :maple_leaf:"}
	{\\ud83c\\udf42}	{" :fallen_leaves:"}
	{\\ud83c\\udf43}	{" :leaves:"}
	{\\ud83c\\udf44}	{" :mushroom:"}
	{\\ud83c\\udf45}	{" :tomato:"}
	{\\ud83c\\udf46}	{" :aubergine:"}
	{\\ud83c\\udf47}	{" :grapes:"}
	{\\ud83c\\udf48}	{" :melon:"}
	{\\ud83c\\udf49}	{" :watermelon:"}
	{\\ud83c\\udf4a}	{" :tangerine:"}
	{\\ud83c\\udf4b}	{" :lemon:"}
	{\\ud83c\\udf4c}	{" :banana:"}
	{\\ud83c\\udf4d}	{" :pineapple:"}
	{\\ud83c\\udf4e}	{" :red_apple:"}
	{\\ud83c\\udf4f}	{" :green_apple:"}
	{\\ud83c\\udf50}	{" :pear:"}
	{\\ud83c\\udf51}	{" :peach:"}
	{\\ud83c\\udf52}	{" :cherries:"}
	{\\ud83c\\udf53}	{" :strawberry:"}
	{\\ud83c\\udf54}	{" :hamburger:"}
	{\\ud83c\\udf55}	{" :pizza_slice:"}
	{\\ud83c\\udf56}	{" :meat_on_bone:"}
	{\\ud83c\\udf57}	{" :poultry_leg:"}
	{\\ud83c\\udf58}	{" :rice_cracker:"}
	{\\ud83c\\udf59}	{" :rice_ball:"}
	{\\ud83c\\udf5a}	{" :rice_bowl:"}
	{\\ud83c\\udf5b}	{" :curry:"}
	{\\ud83c\\udf5c}	{" :noodles:"}
	{\\ud83c\\udf5d}	{" :spaghetti:"}
	{\\ud83c\\udf5e}	{" :bread:"}
	{\\ud83c\\udf5f}	{" :french_fries:"}
	{\\ud83c\\udf60}	{" :sweet_potato:"}
	{\\ud83c\\udf61}	{" :dango:"}
	{\\ud83c\\udf62}	{" :oden:"}
	{\\ud83c\\udf63}	{" :sushi:"}
	{\\ud83c\\udf64}	{" :fried_shrimp:"}
	{\\ud83c\\udf65}	{" :fish_cake:"}
	{\\ud83c\\udf66}	{" :soft_ice_cream:"}
	{\\ud83c\\udf67}	{" :shaved_ice:"}
	{\\ud83c\\udf68}	{" :ice_cream:"}
	{\\ud83c\\udf69}	{" :doughnut:"}
	{\\ud83c\\udf6a}	{" :cookie:"}
	{\\ud83c\\udf6b}	{" :chocolate_bar:"}
	{\\ud83c\\udf6c}	{" :candy:"}
	{\\ud83c\\udf6d}	{" :lollipop:"}
	{\\ud83c\\udf6e}	{" :custard:"}
	{\\ud83c\\udf6f}	{" :honey_pot:"}
	{\\ud83c\\udf70}	{" :cake:"}
	{\\ud83c\\udf71}	{" :bento_box:"}
	{\\ud83c\\udf72}	{" :stew:"}
	{\\ud83c\\udf73}	{" :frying_pan_egg:"}
	{\\ud83c\\udf74}	{" :fork_and_knife:"}
	{\\ud83c\\udf75}	{" :tea:"}
	{\\ud83c\\udf76}	{" :sake:"}
	{\\ud83c\\udf77}	{" :wine:"}
	{\\ud83c\\udf78}	{" :cocktail:"}
	{\\ud83c\\udf79}	{" :tropical_drink:"}
	{\\ud83c\\udf7a}	{" :beer:"}
	{\\ud83c\\udf7b}	{" :beers:"}
	{\\ud83c\\udf7c}	{" :baby_bottle:"}
	{\\ud83c\\udf7d}	{" :plate_with_fork_knife:"}
	{\\ud83c\\udf7e}	{" :champagne_bottle:"}
	{\\ud83c\\udf7f}	{" :popcorn:"}
	{\\ud83c\\udf80}	{" :ribbon:"}
	{\\ud83c\\udf81}	{" :present:"}
	{\\ud83c\\udf82}	{" :birthday_cake:"}
	{\\ud83c\\udf83}	{" :jack_o_lantern:"}
	{\\ud83c\\udf84}	{" :christmas_tree:"}
	{\\ud83c\\udf85}	{" :santa_claus:"}
	{\\ud83c\\udf86}	{" :fireworks:"}
	{\\ud83c\\udf87}	{" :sparkler:"}
	{\\ud83c\\udf88}	{" :balloon:"}
	{\\ud83c\\udf89}	{" :party_popper:"}
	{\\ud83c\\udf8a}	{" :confetti_ball:"}
	{\\ud83c\\udf8b}	{" :tanabata_tree:"}
	{\\ud83c\\udf8c}	{" :crossed_flags:"}
	{\\ud83c\\udf8d}	{" :pine_decoration:"}
	{\\ud83c\\udf8e}	{" :japanese_dolls:"}
	{\\ud83c\\udf8f}	{" :carp_streamer:"}
	{\\ud83c\\udf90}	{" :wind_chime:"}
	{\\ud83c\\udf91}	{" :moon_viewing_ceremony:"}
	{\\ud83c\\udf92}	{" :school_backpack:"}
	{\\ud83c\\udf93}	{" :graduation_cap:"}
	{\\ud83c\\udf94}	{" :heart_tip:"}
	{\\ud83c\\udf95}	{" :bouquet:"}
	{\\ud83c\\udf96}	{" :medal:"}
	{\\ud83c\\udf97}	{" :ribbon:"}
	{\\ud83c\\udf98}	{" :keyboard:"}
	{\\ud83c\\udf99}	{" :microphone:"}
	{\\ud83c\\udf9a}	{" :mixer_slider:"}
	{\\ud83c\\udf9b}	{" :mixer_knobs:"}
	{\\ud83c\\udf9c}	{" :music_notes_ascending:"}
	{\\ud83c\\udf9d}	{" :music_notes_descending:"}
	{\\ud83c\\udf9e}	{" :film_frames:"}
	{\\ud83c\\udf9f}	{" :admission_tickets:"}
	{\\ud83c\\udfa0}	{" :carousel_horse:"}
	{\\ud83c\\udfa1}	{" :ferris_wheel:"}
	{\\ud83c\\udfa2}	{" :roller_coaster:"}
	{\\ud83c\\udfa3}	{" :fishing_pole_and_fish:"}
	{\\ud83c\\udfa4}	{" :microphone:"}
	{\\ud83c\\udfa5}	{" :movie_camera:"}
	{\\ud83c\\udfa6}	{" :cinema:"}
	{\\ud83c\\udfa7}	{" :headphone:"}
	{\\ud83c\\udfa8}	{" :artist_palette:"}
	{\\ud83c\\udfa9}	{" :tophat:"}
	{\\ud83c\\udfaa}	{" :circus_tent:"}
	{\\ud83c\\udfab}	{" :ticket:"}
	{\\ud83c\\udfac}	{" :clapper_board:"}
	{\\ud83c\\udfad}	{" :performing_arts:"}
	{\\ud83c\\udfae}	{" :video_game:"}
	{\\ud83c\\udfaf}	{" :bullseye:"}
	{\\ud83c\\udfb0}	{" :slot_machine:"}
	{\\ud83c\\udfb1}	{" :8ball:"}
	{\\ud83c\\udfb2}	{" :dice:"}
	{\\ud83c\\udfb3}	{" :bowling:"}
	{\\ud83c\\udfb4}	{" :playing_cards:"}
	{\\ud83c\\udfb5}	{" :musical_note:"}
	{\\ud83c\\udfb6}	{" :musical_notes:"}
	{\\ud83c\\udfb7}	{" :saxophone:"}
	{\\ud83c\\udfb8}	{" :guitar:"}
	{\\ud83c\\udfb9}	{" :keyboard:"}
	{\\ud83c\\udfba}	{" :trumpet:"}
	{\\ud83c\\udfbb}	{" :violin:"}
	{\\ud83c\\udfbc}	{" :musical_score:"}
	{\\ud83c\\udfbd}	{" :running_shirt:"}
	{\\ud83c\\udfbe}	{" :tennis:"}
	{\\ud83c\\udfbf}	{" :skiing:"}
	{\\ud83c\\udfc0}	{" :basketball:"}
	{\\ud83c\\udfc1}	{" :checkered_flag:"}
	{\\ud83c\\udfc2}	{" :snowboarder:"}
	{\\ud83c\\udfc3}	{" :runner:"}
	{\\ud83c\\udfc4}	{" :surfer:"}
	{\\ud83c\\udfc5}	{" :sports_medal:"}
	{\\ud83c\\udfc6}	{" :trophy:"}
	{\\ud83c\\udfc7}	{" :horse_racing:"}
	{\\ud83c\\udfc8}	{" :american_football:"}
	{\\ud83c\\udfc9}	{" :rugby:"}
	{\\ud83c\\udfca}	{" :swimmer:"}
	{\\ud83c\\udfcb}	{" :weight_lifting:"}
	{\\ud83c\\udfcc}	{" :golfing:"}
	{\\ud83c\\udfcd}	{" :motorcycle:"}
	{\\ud83c\\udfce}	{" :racing_car:"}
	{\\ud83c\\udfcf}	{" :cricket:"}
	{\\ud83c\\udfd0}	{" :volleyball:"}
	{\\ud83c\\udfd1}	{" :hockey:"}
	{\\ud83c\\udfd2}	{" :ice_hockey:"}
	{\\ud83c\\udfd3}	{" :table_tennis:"}
	{\\ud83c\\udfd4}	{" :mountain_snow:"}
	{\\ud83c\\udfd5}	{" :camping:"}
	{\\ud83c\\udfd6}	{" :beach_parasol:"}
	{\\ud83c\\udfd7}	{" :building_construction:"}
	{\\ud83c\\udfd8}	{" :houses:"}
	{\\ud83c\\udfd9}	{" :cityscape:"}
	{\\ud83c\\udfda}	{" :derelict_house:"}
	{\\ud83c\\udfdb}	{" :roman_building:"}
	{\\ud83c\\udfdc}	{" :desert:"}
	{\\ud83c\\udfdd}	{" :desert_island:"}
	{\\ud83c\\udfde}	{" :national_park:"}
	{\\ud83c\\udfdf}	{" :stadium:"}
	{\\ud83c\\udfe0}	{" :house:"}
	{\\ud83c\\udfe1}	{" :house_with_garden:"}
	{\\ud83c\\udfe2}	{" :office:"}
	{\\ud83c\\udfe3}	{" :japanese_post_office:"}
	{\\ud83c\\udfe4}	{" :european_post_office:"}
	{\\ud83c\\udfe5}	{" :hospital:"}
	{\\ud83c\\udfe6}	{" :bank:"}
	{\\ud83c\\udfe7}	{" :atm:"}
	{\\ud83c\\udfe8}	{" :hotel:"}
	{\\ud83c\\udfe9}	{" :love_hotel:"}
	{\\ud83c\\udfea}	{" :convenience_store:"}
	{\\ud83c\\udfeb}	{" :school:"}
	{\\ud83c\\udfec}	{" :department_store:"}
	{\\ud83c\\udfed}	{" :factory:"}
	{\\ud83c\\udfee}	{" :izakaya_lantern:"}
	{\\ud83c\\udfef}	{" :japanese_castle:"}
	{\\ud83c\\udff0}	{" :european_castle:"}
	{\\ud83c\\udff1}	{" :white_pennant:"}
	{\\ud83c\\udff2}	{" :black_pennant:"}
	{\\ud83c\\udff3}	{" :white_flag:"}
	{\\ud83c\\udff4}	{" :black_flag:"}
	{\\ud83c\\udff4\\u200d\\u2620}	{"pirate_flag:"}
	{\\ud83c\\udff5}	{" :rosette:"}
	{\\ud83c\\udff6}	{" :black_rosette:"}
	{\\ud83c\\udff7}	{" :label:"}
	{\\ud83c\\udff8}	{" :badminton:"}
	{\\ud83c\\udff9}	{" :bow_and_arrow:"}
	{\\ud83c\\udffa}	{" :amphora:"}
	{\\ud83c\\udffb}	{""}
	{\\ud83c\\udffc}	{""}
	{\\ud83c\\udffd}	{""}
	{\\ud83c\\udffe}	{""}
	{\\ud83c\\udfff}	{""}
	{\\ud83d\\udc00}	{:rat:}
	{\\ud83d\\udc01}	{:mouse:}
	{\\ud83d\\udc02}	{:ox:}
	{\\ud83d\\udc03}	{:water_buffalo:}
	{\\ud83d\\udc04}	{:cow:}
	{\\ud83d\\udc05}	{:tiger:}
	{\\ud83d\\udc06}	{:leopard:}
	{\\ud83d\\udc07}	{:rabbit:}
	{\\ud83d\\udc08}	{:cat:}
	{\\ud83d\\udc09}	{:dragon:}
	{\\ud83d\\udc0a}	{:crocodile:}
	{\\ud83d\\udc0b}	{:whale:}
	{\\ud83d\\udc0c}	{:snail:}
	{\\ud83d\\udc0d}	{:snake:}
	{\\ud83d\\udc0e}	{:horse:}
	{\\ud83d\\udc0f}	{:ram:}
	{\\ud83d\\udc10}	{:goat:}
	{\\ud83d\\udc11}	{:sheep:}
	{\\ud83d\\udc12}	{:monkey:}
	{\\ud83d\\udc13}	{:rooster:}
	{\\ud83d\\udc14}	{:chicken:}
	{\\ud83d\\udc15}	{:dog:}
	{\\ud83d\\udc16}	{:pig:}
	{\\ud83d\\udc17}	{:boar:}
	{\\ud83d\\udc18}	{:elephant:}
	{\\ud83d\\udc19}	{:octopus:}
	{\\ud83d\\udc1a}	{:shell:}
	{\\ud83d\\udc1b}	{:bug:}
	{\\ud83d\\udc1c}	{:ant:}
	{\\ud83d\\udc1d}	{:bee:}
	{\\ud83d\\udc1e}	{:ladybug:}
	{\\ud83d\\udc1f}	{:fish:}
	{\\ud83d\\udc20}	{:tropical_fish:}
	{\\ud83d\\udc21}	{:blowfish:}
	{\\ud83d\\udc22}	{:turtle:}
	{\\ud83d\\udc23}	{:hatching_chick:}
	{\\ud83d\\udc24}	{:baby_chick:}
	{\\ud83d\\udc25}	{:hatched_chick:}
	{\\ud83d\\udc26}	{:bird:}
	{\\ud83d\\udc27}	{:penguin:}
	{\\ud83d\\udc28}	{:koala:}
	{\\ud83d\\udc29}	{:poodle:}
	{\\ud83d\\udc2a}	{:dromedary:}
	{\\ud83d\\udc2b}	{:camel:}
	{\\ud83d\\udc2c}	{:dolphin:}
	{\\ud83d\\udc2d}	{:mouse_face:}
	{\\ud83d\\udc2e}	{:cow_face:}
	{\\ud83d\\udc2f}	{:tiger_face:}
	{\\ud83d\\udc30}	{:rabbit_face:}
	{\\ud83d\\udc31}	{:cat_face:}
	{\\ud83d\\udc32}	{:dragon_face:}
	{\\ud83d\\udc33}	{:whale:}
	{\\ud83d\\udc34}	{:horse_face:}
	{\\ud83d\\udc35}	{:monkey_face:}
	{\\ud83d\\udc36}	{:dog_face:}
	{\\ud83d\\udc37}	{:pig_face:}
	{\\ud83d\\udc38}	{:frog_face:}
	{\\ud83d\\udc39}	{:hamster_face:}
	{\\ud83d\\udc3a}	{:wolf_face:}
	{\\ud83d\\udc3b}	{:bear_face:}
	{\\ud83d\\udc3c}	{:panda_face:}
	{\\ud83d\\udc3e}	{:paw_prints:}
	{\\ud83d\\udc3f}	{:chipmunk:}
	{\\ud83d\\udc3d}	{:pig_nose:}
	{\\ud83d\\udc40}	{:eyes:}
	{\\ud83d\\udc41}	{:eye:}
	{\\ud83d\\udc42}	{" :ear:"}
	{\\ud83d\\udc43}	{" :nose:"}
	{\\ud83d\\udc44}	{" :mouth:"}
	{\\ud83d\\udc45}	{" :tongue:"}
	{\\ud83d\\udc46}	{" :hand_pointing_up:"}
	{\\ud83d\\udc47}	{" :hand_pointing_down:"}
	{\\ud83d\\udc48}	{" :hand_pointing_left:"}
	{\\ud83d\\udc49}	{" :hand_pointing_right:"}
	{\\ud83d\\udc4a}	{" :fist:"}
	{\\ud83d\\udc4b}	{" :hand_wave:"}
	{\\ud83d\\udc4c}	{" :hand_ok:"}
	{\\ud83d\\udc4d}	{" (Y)"}
	{\\ud83d\\udc4e}	{" (N)"}
	{\\ud83d\\udc4f}	{" :hand_clap:"}
	{\\ud83d\\udc50}	{" :hands_open:"}
	{\\ud83d\\udc51}	{" :crown:"}
	{\\ud83d\\udc52}	{" :womans_hat:"}
	{\\ud83d\\udc53}	{" :spectacles:"}
	{\\ud83d\\udc54}	{" :necktie:"}
	{\\ud83d\\udc55}	{" :t_shirt:"}
	{\\ud83d\\udc56}	{" :jeans:"}
	{\\ud83d\\udc57}	{" :dress:"}
	{\\ud83d\\udc58}	{" :kimono:"}
	{\\ud83d\\udc59}	{" :bikini:"}
	{\\ud83d\\udc5a}	{" :womans_clothes:"}
	{\\ud83d\\udc5b}	{" :purse:"}
	{\\ud83d\\udc5c}	{" :handbag:"}
	{\\ud83d\\udc5d}	{" :pouch:"}
	{\\ud83d\\udc5e}	{" :mans_shoe:"}
	{\\ud83d\\udc5f}	{" :sport_shoe:"}
	{\\ud83d\\udc60}	{" :high_heeled_shoe:"}
	{\\ud83d\\udc61}	{" :womans_sandals:"}
	{\\ud83d\\udc62}	{" :womans_boots:"}
	{\\ud83d\\udc63}	{" :footprints:"}
	{\\ud83d\\udc64}	{" :silhouette:"}
	{\\ud83d\\udc65}	{" :silhouettes:"}
	{\\ud83d\\udc66}	{" :boy:"}
	{\\ud83d\\udc67}	{" :girl:"}
	{\\ud83d\\udc68}	{" :man:"}
	{\\ud83d\\udc69}	{" :woman:"}
	{\\ud83d\\udc6a}	{" :family:"}
	{\\ud83d\\udc6b}	{" :man_woman_holding_hands:"}
	{\\ud83d\\udc6c}	{" :two_men_holding_hands:"}
	{\\ud83d\\udc6d}	{" :two_women_holding_hands:"}
	{\\ud83d\\udc6e}	{" :police_officer:"}
	{\\ud83d\\udc6f}	{" :women_with_bunny_ears:"}
	{\\ud83d\\udc70}	{" :bride:"}
	{\\ud83d\\udc71}	{" :man_with_blond_hair:"}
	{\\ud83d\\udc72}	{" :man_with_gua_pi_mao:"}
	{\\ud83d\\udc73}	{" :man_with_turban:"}
	{\\ud83d\\udc74}	{" :older_man:"}
	{\\ud83d\\udc75}	{" :older_woman:"}
	{\\ud83d\\udc76}	{" :baby:"}
	{\\ud83d\\udc77}	{" :construction_worker:"}
	{\\ud83d\\udc78}	{" :princess:"}
	{\\ud83d\\udc79}	{" :japanese_ogre:"}
	{\\ud83d\\udc7a}	{" :japanese_goblin:"}
	{\\ud83d\\udc7b}	{" :ghost:"}
	{\\ud83d\\udc7c}	{" :baby_angel:"}
	{\\ud83d\\udc7d}	{" :alien:"}
	{\\ud83d\\udc7e}	{" :space_invader:"}
	{\\ud83d\\udc7f}	{" :imp:"}
	{\\ud83d\\udc80}	{" :skull:"}
	{\\ud83d\\udc81}	{" :information_desk_person:"}
	{\\ud83d\\udc82}	{" :guardsman:"}
	{\\ud83d\\udc83}	{" :female_dancer:"}
	{\\ud83d\\udc84}	{" :lipstick:"}
	{\\ud83d\\udc85}	{" :nail_polish:"}
	{\\ud83d\\udc86}	{" :face_massage:"}
	{\\ud83d\\udc87}	{" :haircut:"}
	{\\ud83d\\udc88}	{" :barber_pole:"}
	{\\ud83d\\udc89}	{" :syringe:"}
	{\\ud83d\\udc8a}	{" :pill:"}
	{\\ud83d\\udc8b}	{" :kissing_lips:"}
	{\\ud83d\\udc8c}	{" :love_letter:"}
	{\\ud83d\\udc8d}	{" :ring:"}
	{\\ud83d\\udc8e}	{" :gem:"}
	{\\ud83d\\udc8f}	{" :couple_kissing:"}
	{\\ud83d\\udc90}	{" :bouquet:"}
	{\\ud83d\\udc91}	{" :couple_heart:"}
	{\\ud83d\\udc92}	{" :wedding_chapel:"}
	{\\ud83d\\udc93}	{" :heart_pulsating:"}
	{\\ud83d\\udc94}	{" :heart_broken:"}
	{\\ud83d\\udc95}	{" :two_hearts:"}
	{\\ud83d\\udc96}	{" :heart_sparkling:"}
	{\\ud83d\\udc97}	{" :heart_beating:"}
	{\\ud83d\\udc98}	{" :heart_with_arrow:"}
	{\\ud83d\\udc99}	{" :heart_blue:"}
	{\\ud83d\\udc9a}	{" :heart_green:"}
	{\\ud83d\\udc9b}	{" :heart_yellow:"}
	{\\ud83d\\udc9c}	{" :heart_purple:"}
	{\\ud83d\\udc9d}	{" :heart_with_ribbon:"}
	{\\ud83d\\udc9e}	{" :hearts_revolving:"}
	{\\ud83d\\udc9f}	{" :heart_box:"}
	{\\ud83d\\udca0}	{" :diamond_shape_with_dot_inside:"}
	{\\ud83d\\udca1}	{" :light_bulb:"}
	{\\ud83d\\udca2}	{" :anger:"}
	{\\ud83d\\udca3}	{" :bomb:"}
	{\\ud83d\\udca4}	{" :zzz:"}
	{\\ud83d\\udca5}	{" :boom:"}
	{\\ud83d\\udca6}	{" :splash:"}
	{\\ud83d\\udca7}	{" :droplet:"}
	{\\ud83d\\udca8}	{" :dash:"}
	{\\ud83d\\udca9}	{" :poo:"}
	{\\ud83d\\udcaa}	{" :muscle:"}
	{\\ud83d\\udcab}	{" :dizzy:"}
	{\\ud83d\\udcac}	{" :speech_balloon:"}
	{\\ud83d\\udcad}	{" :thought_balloon:"}
	{\\ud83d\\udcae}	{" :white_flower:"}
	{\\ud83d\\udcaf}	{" :100_symbol:"}
	{\\ud83d\\udcb0}	{" :moneybag:"}
	{\\ud83d\\udcb1}	{" :currency_exchange:"}
	{\\ud83d\\udcb2}	{" :dollar_sign:"}
	{\\ud83d\\udcb3}	{" :credit_card:"}
	{\\ud83d\\udcb4}	{" :banknotes_yen:"}
	{\\ud83d\\udcb5}	{" :banknotes_dollar:"}
	{\\ud83d\\udcb6}	{" :banknotes_euro:"}
	{\\ud83d\\udcb7}	{" :banknotes_pound:"}
	{\\ud83d\\udcb8}	{" :banknotes_dollar_flying:"}
	{\\ud83d\\udcb9}	{" :stock_chart:"}
	{\\ud83d\\udcba}	{" :seat:"}
	{\\ud83d\\udcbb}	{" :computer:"}
	{\\ud83d\\udcbc}	{" :briefcase:"}
	{\\ud83d\\udcbd}	{" :minidisc:"}
	{\\ud83d\\udcbe}	{" :floppydisc:"}
	{\\ud83d\\udcbf}	{" :opticaldisc:"}
	{\\ud83d\\udcc0}	{" :dvd:"}
	{\\ud83d\\udcc1}	{" :file_folder:"}
	{\\ud83d\\udcc2}	{" :file_folder_open:"}
	{\\ud83d\\udcc3}	{" :page_doublesided:"}
	{\\ud83d\\udcc4}	{" :page_facing_up:"}
	{\\ud83d\\udcc5}	{" :calendar:"}
	{\\ud83d\\udcc6}	{" :tearoff_calendar:"}
	{\\ud83d\\udcc7}	{" :card_index:"}
	{\\ud83d\\udcc8}	{" :chart_upward_trend:"}
	{\\ud83d\\udcc9}	{" :chart_downward_trend:"}
	{\\ud83d\\udcca}	{" :bar_chart:"}
	{\\ud83d\\udccb}	{" :clipboard:"}
	{\\ud83d\\udccc}	{" :pushpin:"}
	{\\ud83d\\udccd}	{" :pin:"}
	{\\ud83d\\udcce}	{" :paperclip:"}
	{\\ud83d\\udccf}	{" :ruler:"}
	{\\ud83d\\udcd0}	{" :ruler_triangular:"}
	{\\ud83d\\udcd1}	{" :bookmark_tabs:"}
	{\\ud83d\\udcd2}	{" :ledger:"}
	{\\ud83d\\udcd3}	{" :notebook_black:"}
	{\\ud83d\\udcd4}	{" :notebook_white:"}
	{\\ud83d\\udcd5}	{" :book_closed:"}
	{\\ud83d\\udcd6}	{" :book_open:"}
	{\\ud83d\\udcd7}	{" :book_green:"}
	{\\ud83d\\udcd8}	{" :book_blue:"}
	{\\ud83d\\udcd9}	{" :book_orange:"}
	{\\ud83d\\udcda}	{" :books:"}
	{\\ud83d\\udcdb}	{" :name_badge:"}
	{\\ud83d\\udcdc}	{" :scroll:"}
	{\\ud83d\\udcdd}	{" :memo:"}
	{\\ud83d\\udcde}	{" :telephone_receiver:"}
	{\\ud83d\\udcdf}	{" :pager:"}
	{\\ud83d\\udce0}	{" :fax_machine:"}
	{\\ud83d\\udce1}	{" :satellite_dish:"}
	{\\ud83d\\udce2}	{" :pa_megaphone:"}
	{\\ud83d\\udce3}	{" :megaphone:"}
	{\\ud83d\\udce4}	{" :outbox:"}
	{\\ud83d\\udce5}	{" :inbox:"}
	{\\ud83d\\udce6}	{" :package:"}
	{\\ud83d\\udce7}	{" :email:"}
	{\\ud83d\\udce8}	{" :incoming_mail:"}
	{\\ud83d\\udce9}	{" :envelope_with_incoming_arrow:"}
	{\\ud83d\\udcea}	{" :mailbox_closed:"}
	{\\ud83d\\udceb}	{" :mailbox_closed_with_flag:"}
	{\\ud83d\\udcec}	{" :mailbox_open_with_flag:"}
	{\\ud83d\\udced}	{" :mailbox_open:"}
	{\\ud83d\\udcee}	{" :postbox:"}
	{\\ud83d\\udcef}	{" :postal_horn:"}
	{\\ud83d\\udcf0}	{" :newspaper:"}
	{\\ud83d\\udcf1}	{" :mobile_phone:"}
	{\\ud83d\\udcf2}	{" :mobile_phone_with_arrow:"}
	{\\ud83d\\udcf3}	{" :mobile_phone_vibrating:"}
	{\\ud83d\\udcf4}	{" :mobile_phone_off:"}
	{\\ud83d\\udcf5}	{" :no_mobile_phones:"}
	{\\ud83d\\udcf6}	{" :antenna_signal_strength:"}
	{\\ud83d\\udcf7}	{" :camera:"}
	{\\ud83d\\udcf8}	{" :camera_with_flash:"}
	{\\ud83d\\udcf9}	{" :video_camera:"}
	{\\ud83d\\udcfa}	{" :television:"}
	{\\ud83d\\udcfb}	{" :radio:"}
	{\\ud83d\\udcfc}	{" :videocassette:"}
	{\\ud83d\\udcfd}	{" :film_projector:"}
	{\\ud83d\\udcfe}	{" :portable_stereo:"}
	{\\ud83d\\udcff}	{" :prayer_beads:"}
	{\\ud83d\\udd00}	{" :play_random:"}
	{\\ud83d\\udd01}	{" :play_repeat:"}
	{\\ud83d\\udd02}	{" :play_repeat_one:"}
	{\\ud83d\\udd03}	{" :arrows_clockwise:"}
	{\\ud83d\\udd04}	{" :arrows_anticlockwise:"}
	{\\ud83d\\udd05}	{" :brightness_low:"}
	{\\ud83d\\udd06}	{" :brightness_high:"}
	{\\ud83d\\udd07}	{" :sound_off:"}
	{\\ud83d\\udd08}	{" :sound:"}
	{\\ud83d\\udd09}	{" :sound_medium:"}
	{\\ud83d\\udd0a}	{" :sound_loud:"}
	{\\ud83d\\udd0b}	{" :battery:"}
	{\\ud83d\\udd0c}	{" :powercord:"}
	{\\ud83d\\udd0d}	{" :magnifying_glass_pointing_left:"}
	{\\ud83d\\udd0e}	{" :magnifying_glass_pointing_right:"}
	{\\ud83d\\udd0f}	{" :lock_with_ink_pen:"}
	{\\ud83d\\udd10}	{" :closed_lock_with_key:"}
	{\\ud83d\\udd11}	{" :key:"}
	{\\ud83d\\udd12}	{" :padlock_locked:"}
	{\\ud83d\\udd13}	{" :padlock_unlock:"}
	{\\ud83d\\udd14}	{" :bell:"}
	{\\ud83d\\udd15}	{" :no_bell:"}
	{\\ud83d\\udd16}	{" :bookmark:"}
	{\\ud83d\\udd17}	{" :link:"}
	{\\ud83d\\udd18}	{" :radio_button:"}
	{\\ud83d\\udd19}	{" :back:"}
	{\\ud83d\\udd1a}	{" :end:"}
	{\\ud83d\\udd1b}	{" :on:"}
	{\\ud83d\\udd1c}	{" :soon:"}
	{\\ud83d\\udd1d}	{" :top:"}
	{\\ud83d\\udd1e}	{" :underage:"}
	{\\ud83d\\udd1f}	{" :keycap_ten:"}
	{\\ud83d\\udd20}	{" :capital_abcd:"}
	{\\ud83d\\udd21}	{" :abcd:"}
	{\\ud83d\\udd22}	{" :1234:"}
	{\\ud83d\\udd23}	{" :phone:"}
	{\\ud83d\\udd24}	{" :telephone_receiver:"}
	{\\ud83d\\udd25}	{" :fire:"}
	{\\ud83d\\udd26}	{" :flashlight:"}
	{\\ud83d\\udd27}	{" :wrench:"}
	{\\ud83d\\udd28}	{" :hammer:"}
	{\\ud83d\\udd29}	{" :nut_and_bolt:"}
	{\\ud83d\\udd2a}	{" :knife:"}
	{\\ud83d\\udd2b}	{" :pistol:"}
	{\\ud83d\\udd2c}	{" :microscope:"}
	{\\ud83d\\udd2d}	{" :telescope:"}
	{\\ud83d\\udd2e}	{" :crystal_ball:"}
	{\\ud83d\\udd2f}	{" :david_star:"}
	{\\ud83d\\udd30}	{" :beginner_japanese_symbol:"}
	{\\ud83d\\udd31}	{" :trident:"}
	{\\ud83d\\udd32}	{" :black_square_button:"}
	{\\ud83d\\udd33}	{" :white_square_button:"}
	{\\ud83d\\udd34}	{" :large_red_circle:"}
	{\\ud83d\\udd35}	{" :large_blue_circle:"}
	{\\ud83d\\udd36}	{" :large_orange_diamond:"}
	{\\ud83d\\udd37}	{" :large_blue_diamond:"}
	{\\ud83d\\udd38}	{" :small_orange_diamond:"}
	{\\ud83d\\udd39}	{" :small_blue_diamond:"}
	{\\ud83d\\udd3a}	{" :red_triangle_up:"}
	{\\ud83d\\udd3b}	{" :red_triangle_down:"}
	{\\ud83d\\udd3c}	{" :arrow_up_small:"}
	{\\ud83d\\udd3d}	{" :arrow_down_small:"}
	{\\ud83d\\udd3e}	{" :circle_shadow_lower_right:"}
	{\\ud83d\\udd3f}	{" :circle_shadow_upper_right:"}
	{\\ud83d\\udd40}	{" :cross_pommee_circled:"}
	{\\ud83d\\udd41}	{" :cross_pommee_with_halfcircle:"}
	{\\ud83d\\udd42}	{" :cross_pommee:"}
	{\\ud83d\\udd43}	{" :left_semicircle:"}
	{\\ud83d\\udd44}	{" :right_semicircle:"}
	{\\ud83d\\udd45}	{" :marks_chapter:"}
	{\\ud83d\\udd46}	{" :latin_cross_white:"}
	{\\ud83d\\udd47}	{" :latin_cross_black:"}
	{\\ud83d\\udd48}	{" :celtic_cross:"}
	{\\ud83d\\udd49}	{" :om:"}
	{\\ud83d\\udd4a}	{" :dove:"}
	{\\ud83d\\udd4b}	{" :kaaba:"}
	{\\ud83d\\udd4c}	{" :mosque:"}
	{\\ud83d\\udd4d}	{" :synagogue:"}
	{\\ud83d\\udd4e}	{" :menorah:"}
	{\\ud83d\\udd4f}	{" :bowl_of_hygieia:"}
	{\\ud83d\\udd50}	{" :clock_one_oclock:"}
	{\\ud83d\\udd51}	{" :clock_two_oclock:"}
	{\\ud83d\\udd52}	{" :clock_three_oclock:"}
	{\\ud83d\\udd53}	{" :clock_four_oclock:"}
	{\\ud83d\\udd54}	{" :clock_five_oclock:"}
	{\\ud83d\\udd55}	{" :clock_six_oclock:"}
	{\\ud83d\\udd56}	{" :clock_seven_oclock:"}
	{\\ud83d\\udd57}	{" :clock_eight_oclock:"}
	{\\ud83d\\udd58}	{" :clock_nine_oclock:"}
	{\\ud83d\\udd59}	{" :clock_ten_oclock:"}
	{\\ud83d\\udd5a}	{" :clock_eleven_oclock:"}
	{\\ud83d\\udd5b}	{" :clock_twelve_oclock:"}
	{\\ud83d\\udd5c}	{" :clock_one_thirty:"}
	{\\ud83d\\udd5d}	{" :clock_two_thirty:"}
	{\\ud83d\\udd5e}	{" :clock_three_thirty:"}
	{\\ud83d\\udd5f}	{" :clock_four_thirty:"}
	{\\ud83d\\udd60}	{" :clock_five_thirty:"}
	{\\ud83d\\udd61}	{" :clock_six_thirty:"}
	{\\ud83d\\udd62}	{" :clock_seven_thirty:"}
	{\\ud83d\\udd63}	{" :clock_eight_thirty:"}
	{\\ud83d\\udd64}	{" :clock_nine_thirty:"}
	{\\ud83d\\udd65}	{" :clock_ten_thirty:"}
	{\\ud83d\\udd66}	{" :clock_eleven_thirty:"}
	{\\ud83d\\udd67}	{" :clock_twelve_thirty:"}
	{\\ud83d\\udd68}	{" :volume_low:"}
	{\\ud83d\\udd69}	{" :volume_medium:"}
	{\\ud83d\\udd6a}	{" :volume_high:"}
	{\\ud83d\\udd6b}	{" :bullhorn:"}
	{\\ud83d\\udd6c}	{" :bullhorn_with_soundwaves:"}
	{\\ud83d\\udd6d}	{" :bell:"}
	{\\ud83d\\udd6e}	{" :book:"}
	{\\ud83d\\udd6f}	{" :candle:"}
	{\\ud83d\\udd70}	{" :mantelpiece_clock:"}
	{\\ud83d\\udd71}	{" :skull_and_bones:"}
	{\\ud83d\\udd72}	{" :no_piracy:"}
	{\\ud83d\\udd73}	{" :hole:"}
	{\\ud83d\\udd74}	{" :business_suit:"}
	{\\ud83d\\udd75}	{" :detective:"}
	{\\ud83d\\udd76}	{" :sunglasses:"}
	{\\ud83d\\udd77}	{" :spider:"}
	{\\ud83d\\udd78}	{" :spiderweb:"}
	{\\ud83d\\udd79}	{" :joystick:"}
	{\\ud83d\\udd7a}	{" :man_dancing:"}
	{\\ud83d\\udd7b}	{" :left_telephone_receiver:"}
	{\\ud83d\\udd7c}	{" :left_telephone_receiver_with_page:"}
	{\\ud83d\\udd7d}	{" :right_telephone_receiver:"}
	{\\ud83d\\udd7e}	{" :touchtone_telephone_white:"}
	{\\ud83d\\udd7f}	{" :touchtone_telephone_black:"}
	{\\ud83d\\udd80}	{" :telephone_with_modem:"}
	{\\ud83d\\udd81}	{" :clamshell_mobile_phone:"}
	{\\ud83d\\udd82}	{" :envelope_back:"}
	{\\ud83d\\udd83}	{" :envelope_front:"}
	{\\ud83d\\udd84}	{" :envelope_flash:"}
	{\\ud83d\\udd85}	{" :envelope_flying:"}
	{\\ud83d\\udd85}	{" :envelope_with_pen:"}
	{\\ud83d\\udd87}	{" :paperclips_linked:"}
	{\\ud83d\\udd88}	{" :pushpin_black:"}
	{\\ud83d\\udd89}	{" :pencil:"}
	{\\ud83d\\udd8a}	{" :pen:"}
	{\\ud83d\\udd8b}	{" :fountain_pen:"}
	{\\ud83d\\udd8c}	{" :paintbrush:"}
	{\\ud83d\\udd8d}	{" :crayon:"}
	{\\ud83d\\udd8e}	{" :hand_with_pen:"}
	{\\ud83d\\udd8f}	{" :hand_ok_sign:"}
	{\\ud83d\\udd90}	{" :hand_raised:"}
	{\\ud83d\\udd91}	{" :hand_palm:"}
	{\\ud83d\\udd92}	{" :thumbs_up:"}
	{\\ud83d\\udd93}	{" :thumbs_down:"}
	{\\ud83d\\udd94}	{" :hand_peace_sign:"}
	{\\ud83d\\udd95}	{" :middle_finger:"}
	{\\ud83d\\udd96}	{" :hand_vulcan:"}
	{\\ud83d\\udd97}	{" :finger_pointing_down:"}
	{\\ud83d\\udd98}	{" :finger_pointing_left:"}
	{\\ud83d\\udd99}	{" :finger_pointing_right:"}
	{\\ud83d\\udd9a}	{" :finger_pointing_left:"}
	{\\ud83d\\udd9b}	{" :finger_pointing_right:"}
	{\\ud83d\\udd9c}	{" :finger_pointing_left:"}
	{\\ud83d\\udd9d}	{" :finger_pointing_right:"}
	{\\ud83d\\udd9e}	{" :finger_pointing_up:"}
	{\\ud83d\\udd9f}	{" :finger_pointing_down:"}
	{\\ud83d\\udda0}	{" :finger_pointing_up:"}
	{\\ud83d\\udda1}	{" :finger_pointing_down:"}
	{\\ud83d\\udda2}	{" :finger_pointing_up:"}
	{\\ud83d\\udda3}	{" :finger_pointing_down:"}
	{\\ud83d\\udda4}	{" :black_heart:"}
	{\\ud83d\\udda5}	{" :desktop_computer:"}
	{\\ud83d\\udda6}	{" :keyboard_and_mouse:"}
	{\\ud83d\\udda7}	{" :networked_computers:"}
	{\\ud83d\\udda8}	{" :printer:"}
	{\\ud83d\\udda9}	{" :calculator:"}
	{\\ud83d\\uddaa}	{" :floppy_disc_black:"}
	{\\ud83d\\uddab}	{" :floppy_disc_white:"}
	{\\ud83d\\uddac}	{" :floppy_disc:"}
	{\\ud83d\\uddad}	{" :backup_tape:"}
	{\\ud83d\\uddae}	{" :keyboard:"}
	{\\ud83d\\uddaf}	{" :mouse_one_button:"}
	{\\ud83d\\uddb0}	{" :mouse_two_buttons:"}
	{\\ud83d\\uddb1}	{" :computer_mouse:"}
	{\\ud83d\\uddb2}	{" :trackball:"}
	{\\ud83d\\uddb3}	{" :pc:"}
	{\\ud83d\\uddb4}	{" :icon_harddisk:"}
	{\\ud83d\\uddb5}	{" :icon_screen:"}
	{\\ud83d\\uddb6}	{" :icon_printer:"}
	{\\ud83d\\uddb7}	{" :icon_fax:"}
	{\\ud83d\\uddb8}	{" :icon_optical_disc:"}
	{\\ud83d\\uddb9}	{" :icon_document_text:"}
	{\\ud83d\\uddba}	{" :icon_document_text_picture:"}
	{\\ud83d\\uddbb}	{" :icon_document_picture:"}
	{\\ud83d\\uddbc}	{" :framed_picture:"}
	{\\ud83d\\uddbd}	{" :framed_tiles:"}
	{\\ud83d\\uddbe}	{" :framed_x:"}
	{\\ud83d\\uddbf}	{" :icon_folder_black:"}
	{\\ud83d\\uddc0}	{" :icon_folder:"}
	{\\ud83d\\uddc1}	{" :icon_folder_opened:"}
	{\\ud83d\\uddc2}	{" :card_index_dividers:"}
	{\\ud83d\\uddc3}	{" :card_file_box:"}
	{\\ud83d\\uddc4}	{" :file_cabinet:"}
	{\\ud83d\\uddc5}	{" :empty_note:"}
	{\\ud83d\\uddc6}	{" :empty_note_page:"}
	{\\ud83d\\uddc7}	{" :empty_note_pad:"}
	{\\ud83d\\uddc8}	{" :note:"}
	{\\ud83d\\uddc9}	{" :note_page:"}
	{\\ud83d\\uddca}	{" :note_pad:"}
	{\\ud83d\\uddcb}	{" :empty_document:"}
	{\\ud83d\\uddcc}	{" :empty_page:"}
	{\\ud83d\\uddcd}	{" :empty_pages:"}
	{\\ud83d\\uddce}	{" :document:"}
	{\\ud83d\\uddcf}	{" :page:"}
	{\\ud83d\\uddd0}	{" :pages:"}
	{\\ud83d\\uddd1}	{" :wastebasket:"}
	{\\ud83d\\uddd2}	{" :spiral_notepad:"}
	{\\ud83d\\uddd3}	{" :spiral_calendar:"}
	{\\ud83d\\uddd4}	{" :desktop_window:"}
	{\\ud83d\\uddd5}	{" :minimize:"}
	{\\ud83d\\uddd6}	{" :maximize:"}
	{\\ud83d\\uddd7}	{" :overlap:"}
	{\\ud83d\\uddd8}	{" :rotate:"}
	{\\ud83d\\uddd9}	{" :close:"}
	{\\ud83d\\uddda}	{" :increase_font_size:"}
	{\\ud83d\\udddb}	{" :decrease_font_size:"}
	{\\ud83d\\udddc}	{" :clamp:"}
	{\\ud83d\\udddd}	{" :old_key:"}
	{\\ud83d\\uddde}	{" :rolled_up_newspaper:"}
	{\\ud83d\\udddf}	{" :page_with_circled_text:"}
	{\\ud83d\\udde0}	{" :stock_chart:"}
	{\\ud83d\\udde1}	{" :dagger:"}
	{\\ud83d\\udde2}	{" :lips:"}
	{\\ud83d\\udde3}	{" :speaking_head:"}
	{\\ud83d\\udde4}	{" :ray_above:"}
	{\\ud83d\\udde5}	{" :ray_below:"}
	{\\ud83d\\udde6}	{" :three_rays_left:"}
	{\\ud83d\\udde7}	{" :three_rays_right:"}
	{\\ud83d\\udde8}	{" :speech_bubble_left:"}
	{\\ud83d\\udde9}	{" :speech_bubble_right:"}
	{\\ud83d\\uddea}	{" :two_speech_bubbles:"}
	{\\ud83d\\uddeb}	{" :three_speech_bubbles:"}
	{\\ud83d\\uddec}	{" :thought_bubble_left:"}
	{\\ud83d\\udded}	{" :thought_bubble_right:"}
	{\\ud83d\\uddee}	{" :anger_bubble_left:"}
	{\\ud83d\\uddef}	{" :anger_bubble_right:"}
	{\\ud83d\\uddf0}	{" :mood_bubble:"}
	{\\ud83d\\uddf1}	{" :mood_bubble_with_flash:"}
	{\\ud83d\\uddf2}	{" :flash:"}
	{\\ud83d\\uddf3}	{" :voting_box:"}
	{\\ud83d\\uddf4}	{" :x:"}
	{\\ud83d\\uddf5}	{" :ballot_box_with_x:"}
	{\\ud83d\\uddf6}	{" :x:"}
	{\\ud83d\\uddf7}	{" :ballot_box_with_x:"}
	{\\ud83d\\uddf8}	{" :check:"}
	{\\ud83d\\uddf9}	{" :ballot_box_checked:"}
	{\\ud83d\\uddfa}	{" :world_map:"}
	{\\ud83d\\uddfb}	{" :mount_fuji:"}
	{\\ud83d\\uddfc}	{" :tokyo_tower:"}
	{\\ud83d\\uddfd}	{" :statue_of_liberty:"}
	{\\ud83d\\uddfe}	{" :silhouette_of_japan:"}
	{\\ud83d\\uddff}	{" :statue_moyai:"}

	{\\ud83d\\ude00}	{" :D"}
	{\\ud83d\\ude01}	{" :-||"}
	{\\ud83d\\ude02}	{" xD"}
	{\\ud83d\\ude03}	{" =-D"}
	{\\ud83d\\ude04}	{" |-D"}
	{\\ud83d\\ude05}	{" X-D"}
	{\\ud83d\\ude06}	{" X-D"}
	{\\ud83d\\ude07}	{" O:-)"}
	{\\ud83d\\ude08}	{" :evil_smile:"}
	{\\ud83d\\ude09}	{" ;-)"}
	{\\ud83d\\ude0a}	{" |-)"}
	{\\ud83d\\ude0b}	{" :yum:"}
	{\\ud83d\\ude0c}	{" X-D"}
	{\\ud83d\\ude0d}	{" :heart_eyes:"}
	{\\ud83d\\ude0e}	{" B-)"}
	{\\ud83d\\ude0f}	{" :smirk:"}
	{\\ud83d\\ude10}	{" :-|"}
	{\\ud83d\\ude11}	{" |-|"}
	{\\ud83d\\ude12}	{" :unamused:"}
	{\\ud83d\\ude13}	{" :coldsweat:"}
	{\\ud83d\\ude14}	{" :pensive:"}
	{\\ud83d\\ude15}	{" :confused:"}
	{\\ud83d\\ude16}	{" :confounded:"}
	{\\ud83d\\ude17}	{" :kissing:"}
	{\\ud83d\\ude18}	{" :kiss:"}
	{\\ud83d\\ude19}	{" :kissing_smiling_eyes:"}
	{\\ud83d\\ude1a}	{" :kissing_closed_eyes:"}
	{\\ud83d\\ude1b}	{" :-P"}
	{\\ud83d\\ude1c}	{" ;-P"}
	{\\ud83d\\ude1d}	{" |-P"}
	{\\ud83d\\ude1e}	{" :dissappointed:"}
	{\\ud83d\\ude1f}	{" :-(("}
	{\\ud83d\\ude20}	{" :angry:"}
	{\\ud83d\\ude21}	{" :rage:"}
	{\\ud83d\\ude22}	{" :'("}
	{\\ud83d\\ude23}	{" :persevere:"}
	{\\ud83d\\ude24}	{" :triumph:"}
	{\\ud83d\\ude25}	{" :disappointed_relieved:"}
	{\\ud83d\\ude26}	{" :frowning:"}
	{\\ud83d\\ude27}	{" :anguished:"}
	{\\ud83d\\ude28}	{" :fearful:"}
	{\\ud83d\\ude29}	{" :weary:"}
	{\\ud83d\\ude2a}	{" :sleepy:"}
	{\\ud83d\\ude2b}	{" :tired_face:"}
	{\\ud83d\\ude2c}	{" :grimacing:"}
	{\\ud83d\\ude2d}	{" :sob:"}
	{\\ud83d\\ude2e}	{" :-o"}
	{\\ud83d\\ude2f}	{" :hushed:"}
	{\\ud83d\\ude30}	{" :cold_sweat:"}
	{\\ud83d\\ude31}	{" :scream:"}
	{\\ud83d\\ude32}	{" :astonished:"}
	{\\ud83d\\ude33}	{" :8|"}
	{\\ud83d\\ude34}	{" :sleeping:"}
	{\\ud83d\\ude35}	{" :dizzy_face:"}
	{\\ud83d\\ude36}	{" :no_mouth:"}
	{\\ud83d\\ude37}	{" :mask:"}
	{\\ud83d\\ude38}	{" :smile_cat:"}
	{\\ud83d\\ude39}	{" :joy_cat:"}
	{\\ud83d\\ude3a}	{" :smining_cat:"}
	{\\ud83d\\ude3b}	{" :heart_eyes_cat:"}
	{\\ud83d\\ude3c}	{" :smirk_cat:"}
	{\\ud83d\\ude3d}	{" :kissing_cat:"}
	{\\ud83d\\ude3e}	{" :pouting_cat:"}
	{\\ud83d\\ude3f}	{" :crying_cat:"}
	{\\ud83d\\ude40}	{" :scream_cat:"}
	{\\ud83d\\ude41}	{" :-("}
	{\\ud83d\\ude42}	{" :slight_smile:"}
	{\\ud83d\\ude43}	{" )-:"}
	{\\ud83d\\ude44}	{" :rolling_eyes:"}
	{\\ud83d\\ude45}	{" :girl_signs_stop:"}
	{\\ud83d\\ude46}	{" :girl_signs_ok:"}
	{\\ud83d\\ude47}	{" :bowing:"}
	{\\ud83d\\ude48}	{" :monkey_see_no_evil:"}
	{\\ud83d\\ude49}	{" :monkey_hear_no_evil:"}
	{\\ud83d\\ude4a}	{" :monkey_speak_no_evil:"}
	{\\ud83d\\ude4b}	{" :girl_raising_hand:"}
	{\\ud83d\\ude4c}	{" :hands_in_the_air:"}
	{\\ud83d\\ude4d}	{" :girl_frowning:"}
	{\\ud83d\\ude4e}	{" :girl_pouting:"}
	{\\ud83d\\ude4f}	{" :folded_hands:"}

	{\\ud83d\\ude59}	{" :sw_vine:"}

	{\\ud83d\\ude80}	{" :rocket:"}
	{\\ud83d\\ude81}	{" :helicopter:"}
	{\\ud83d\\ude82}	{" :steam_locomotive:"}
	{\\ud83d\\ude83}	{" :railway_car:"}
	{\\ud83d\\ude84}	{" :highspeed_train:"}
	{\\ud83d\\ude85}	{" :highspeed_train_bulletnose:"}
	{\\ud83d\\ude86}	{" :train:"}
	{\\ud83d\\ude87}	{" :metro:"}
	{\\ud83d\\ude88}	{" :lightrail:"}
	{\\ud83d\\ude89}	{" :station:"}
	{\\ud83d\\ude8a}	{" :tram:"}
	{\\ud83d\\ude8b}	{" :tram_car:"}
	{\\ud83d\\ude8c}	{" :bus:"}
	{\\ud83d\\ude8d}	{" :bus_front:"}
	{\\ud83d\\ude8e}	{" :trolley:"}
	{\\ud83d\\ude8f}	{" :bus_stop:"}
	{\\ud83d\\ude90}	{" :minibus:"}
	{\\ud83d\\ude91}	{" :ambulance:"}
	{\\ud83d\\ude92}	{" :fire_truck:"}
	{\\ud83d\\ude93}	{" :police_car:"}
	{\\ud83d\\ude94}	{" :police_car_front:"}
	{\\ud83d\\ude95}	{" :taxi:"}
	{\\ud83d\\ude96}	{" :taxi_front:"}
	{\\ud83d\\ude97}	{" :car:"}
	{\\ud83d\\ude98}	{" :car_front:"}
	{\\ud83d\\ude99}	{" :car_rvu:"}
	{\\ud83d\\ude9a}	{" :delivery_truck:"}
	{\\ud83d\\ude9b}	{" :lorry:"}
	{\\ud83d\\ude9c}	{" :tractor:"}
	{\\ud83d\\ude9d}	{" :monorail:"}
	{\\ud83d\\ude9e}	{" :mountain_railway:"}
	{\\ud83d\\ude9f}	{" :suspension_railway:"}
	{\\ud83d\\udea0}	{" :mountain_cableway:"}
	{\\ud83d\\udea1}	{" :aerial_tram:"}
	{\\ud83d\\udea2}	{" :ship:"}
	{\\ud83d\\udea3}	{" :rowboat:"}
	{\\ud83d\\udea4}	{" :speedboat:"}
	{\\ud83d\\udea5}	{" :traffic_light_horizontal:"}
	{\\ud83d\\udea6}	{" :traffic_light:"}
	{\\ud83d\\udea7}	{" :construction_sign:"}
	{\\ud83d\\udea8}	{" :flashing_light:"}
	{\\ud83d\\udea9}	{" :triangular_flag_on_post:"}
	{\\ud83d\\udeaa}	{" :door:"}
	{\\ud83d\\udeab}	{" :no_entry_sign:"}
	{\\ud83d\\udeac}	{" :cigarette:"}
	{\\ud83d\\udead}	{" :no_smoking_sign:"}
	{\\ud83d\\udeae}	{" :put_litter_here:"}
	{\\ud83d\\udeaf}	{" :no_littering:"}
	{\\ud83d\\udeb0}	{" :water_potable:"}
	{\\ud83d\\udeb1}	{" :water_nonpotable:"}
	{\\ud83d\\udeb2}	{" :bicycle:"}
	{\\ud83d\\udeb3}	{" :no_bicycles:"}
	{\\ud83d\\udeb4}	{" :bicyclist:"}
	{\\ud83d\\udeb5}	{" :bicyclist_mountain:"}
	{\\ud83d\\udeb6}	{" :pedestrian:"}
	{\\ud83d\\udeb7}	{" :no_pedestrians:"}
	{\\ud83d\\udeb8}	{" :childrens_crossing:"}
	{\\ud83d\\udeb9}	{" :mens_toilet_sign:"}
	{\\ud83d\\udeba}	{" :womens_toilet_sign:"}
	{\\ud83d\\udebb}	{" :restroom_sign:"}
	{\\ud83d\\udebc}	{" :baby_sign:"}
	{\\ud83d\\udebd}	{" :toilet:"}
	{\\ud83d\\udebe}	{" :wc:"}
	{\\ud83d\\udebf}	{" :shower:"}
	{\\ud83d\\udec0}	{" :bath_with_person:"}
	{\\ud83d\\udec1}	{" :bath:"}
	{\\ud83d\\udec2}	{" :passport_control:"}
	{\\ud83d\\udec3}	{" :customs:"}
	{\\ud83d\\udec4}	{" :baggage_claim:"}
	{\\ud83d\\udec5}	{" :left_luggage:"}
	{\\ud83d\\udecb}	{" :couch:"}
	{\\ud83d\\udecc}	{" :person_in_bed:"}
	{\\ud83d\\udecd}	{" :shopping_bags:"}
	{\\ud83d\\udece}	{" :bellhop:"}
	{\\ud83d\\udecf}	{" :bed:"}
	{\\ud83d\\uded0}	{" :place_of_worship:"}
	{\\ud83d\\uded1}	{" :stop_sign:"}
	{\\ud83d\\uded2}	{" :shopping_cart:"}
	{\\ud83d\\udee0}	{" :hammer_and_wrench:"}
	{\\ud83d\\udee1}	{" :shield:"}
	{\\ud83d\\udee2}	{" :oildrum:"}
	{\\ud83d\\udee3}	{" :motorway:"}
	{\\ud83d\\udee4}	{" :railway_tracks:"}
	{\\ud83d\\udee5}	{" :motorboat:"}
	{\\ud83d\\udee9}	{" :airplane:"}
	{\\ud83d\\udeeb}	{" :airplane_departing:"}
	{\\ud83d\\udeec}	{" :airplane_arrival:"}
	{\\ud83d\\udef0}	{" :sattelite:"}
	{\\ud83d\\udef3}	{" :cruiseship:"}
	{\\ud83d\\udef4}	{" :kick_scooter:"}
	{\\ud83d\\udef5}	{" :motor_scooter:"}
	{\\ud83d\\udef6}	{" :canoe:"}
	{\\ud83d\\udef7}	{" :sled:"}
	{\\ud83d\\udef8}	{" :ufo:"}
	{\\ud83d\\udef9}	{" :skateboard:"}

	{\\ud83e\\udd10}	{" :zipper_mouth:"}
	{\\ud83e\\udd11}	{" :money_mouth:"}
	{\\ud83e\\udd12}	{" :face_with_thermometer:"}
	{\\ud83e\\udd13}	{" :nerd:"}
	{\\ud83e\\udd14}	{" :thinking:"}
	{\\ud83e\\udd15}	{" :face_with_headbandage:"}
	{\\ud83e\\udd16}	{" :robot:"}
	{\\ud83e\\udd17}	{" :hugging_face:"}
	{\\ud83e\\udd18}	{" :hands_hornsign:"}
	{\\ud83e\\udd19}	{" :hand_call_me_sign:"}
	{\\ud83e\\udd1a}	{" :raised_back_of_hand:"}
	{\\ud83e\\udd1b}	{" :fist_left:"}
	{\\ud83e\\udd1c}	{" :fist_right:"}
	{\\ud83e\\udd1d}	{" :handshake:"}
	{\\ud83e\\udd1e}	{" :hand_crossed_fingers:"}
	{\\ud83e\\udd1f}	{" :hand_i_love_you:"}
	{\\ud83e\\udd20}	{" :cowboy_hat_face:"}
	{\\ud83e\\udd21}	{" :clown:"}
	{\\ud83e\\udd22}	{" :sick_face:"}
	{\\ud83e\\udd23}	{" :rofl:"}
	{\\ud83e\\udd24}	{" :face_drooling:"}
	{\\ud83e\\udd25}	{" :face_lying:"}
	{\\ud83e\\udd26}	{" :facepalm:"}
	{\\ud83e\\udd27}	{" :face_sneezing:"}
	{\\ud83e\\udd28}	{" :face_raised_eyebrow:"}
	{\\ud83e\\udd29}	{" :face_starstruck_eyes:"}
	{\\ud83e\\udd2a}	{" :crazy_face:"}
	{\\ud83e\\udd2b}	{" :face_shushing:"}
	{\\ud83e\\udd2c}	{" :face_swearing:"}
	{\\ud83e\\udd2d}	{" :face_with_hand_over_mouth:"}
	{\\ud83e\\udd2e}	{" :vomit:"}
	{\\ud83e\\udd2f}	{" :face_exploding_mushroom_cloud:"}
	{\\ud83e\\udd30}	{" :pregnant:"}
	{\\ud83e\\udd31}	{" :breast_feeding:"}
	{\\ud83e\\udd32}	{" :handpalms_up_together:"}
	{\\ud83e\\udd33}	{" :selfie:"}
	{\\ud83e\\udd34}	{" :prince:"}
	{\\ud83e\\udd35}	{" :tuxedo:"}
	{\\ud83e\\udd36}	{" :mrs_santa_claus:"}
	{\\ud83e\\udd37}	{" :shrugging:"}
	{\\ud83e\\udd38}	{" :cartwheeling:"}
	{\\ud83e\\udd39}	{" :juggling:"}
	{\\ud83e\\udd3a}	{" :fencing:"}
	{\\ud83e\\udd3c}	{" :wrestling:"}
	{\\ud83e\\udd3d}	{" :waterpolo:"}
	{\\ud83e\\udd3e}	{" :handball:"}
	{\\ud83e\\udd40}	{" :wilted_flower:"}
	{\\ud83e\\udd41}	{" :drum:"}
	{\\ud83e\\udd42}	{" :clinking_glasses:"}
	{\\ud83e\\udd43}	{" :whiskey:"}
	{\\ud83e\\udd44}	{" :spoon:"}
	{\\ud83e\\udd45}	{" :goal_net:"}
	{\\ud83e\\udd47}	{" :gold_medal:"}
	{\\ud83e\\udd48}	{" :silver_medal:"}
	{\\ud83e\\udd49}	{" :bronze_medal:"}
	{\\ud83e\\udd4a}	{" :boxing_glove:"}
	{\\ud83e\\udd4b}	{" :martial_arts_uniform:"}
	{\\ud83e\\udd4c}	{" :curling:"}
	{\\ud83e\\udd4d}	{" :lacrosse:"}
	{\\ud83e\\udd4e}	{" :softball:"}
	{\\ud83e\\udd4f}	{" :frisbee:"}
	{\\ud83e\\udd50}	{" :croissant:"}
	{\\ud83e\\udd51}	{" :avocado:"}
	{\\ud83e\\udd52}	{" :cucumber:"}
	{\\ud83e\\udd53}	{" :bacon:"}
	{\\ud83e\\udd54}	{" :potato:"}
	{\\ud83e\\udd55}	{" :carrot:"}
	{\\ud83e\\udd56}	{" :baguette:"}
	{\\ud83e\\udd57}	{" :salad:"}
	{\\ud83e\\udd58}	{" :paella:"}
	{\\ud83e\\udd59}	{" :stuffed_flatbread:"}
	{\\ud83e\\udd5a}	{" :egg:"}
	{\\ud83e\\udd5b}	{" :milk_glass:"}
	{\\ud83e\\udd5c}	{" :peanut:"}
	{\\ud83e\\udd5d}	{" :kiwi:"}
	{\\ud83e\\udd5e}	{" :pancakes:"}
	{\\ud83e\\udd5f}	{" :dumpling:"}
	{\\ud83e\\udd60}	{" :fortune_cookie:"}
	{\\ud83e\\udd61}	{" :takeout_noodles:"}
	{\\ud83e\\udd62}	{" :chopsticks:"}
	{\\ud83e\\udd63}	{" :bowl_with_spoon:"}
	{\\ud83e\\udd64}	{" :cup_with_straw:"}
	{\\ud83e\\udd65}	{" :coconut:"}
	{\\ud83e\\udd66}	{" :broccoli:"}
	{\\ud83e\\udd67}	{" :pie:"}
	{\\ud83e\\udd68}	{" :pretzel:"}
	{\\ud83e\\udd69}	{" :steak:"}
	{\\ud83e\\udd6a}	{" :sandwich:"}
	{\\ud83e\\udd6b}	{" :canned_food:"}
	{\\ud83e\\udd6c}	{" :lettuce:"}
	{\\ud83e\\udd6d}	{" :mango:"}
	{\\ud83e\\udd6e}	{" :cake:"}
	{\\ud83e\\udd6f}	{" :bagel:"}
	{\\ud83e\\udd70}	{" :in_love_face:"}
	{\\ud83e\\udd73}	{" :party_face:"}
	{\\ud83e\\udd74}	{" :drunk_face:"}
	{\\ud83e\\udd75}	{" :hot_face:"}
	{\\ud83e\\udd76}	{" :cold_face:"}
	{\\ud83e\\udd7a}	{" :begging_face:"}
	{\\ud83e\\udd7c}	{" :lab_coat:"}
	{\\ud83e\\udd7d}	{" :goggles:"}
	{\\ud83e\\udd7e}	{" :hiking_boot:"}
	{\\ud83e\\udd7f}	{" :flat_shoe:"}
	{\\ud83e\\udd80}	{" :crab:"}
	{\\ud83e\\udd81}	{" :lion:"}
	{\\ud83e\\udd82}	{" :scorpion:"}
	{\\ud83e\\udd83}	{" :turkey:"}
	{\\ud83e\\udd84}	{" :unicorn:"}
	{\\ud83e\\udd85}	{" :eagle:"}
	{\\ud83e\\udd86}	{" :duck:"}
	{\\ud83e\\udd87}	{" :bat:"}
	{\\ud83e\\udd88}	{" :shark:"}
	{\\ud83e\\udd89}	{" :owl:"}
	{\\ud83e\\udd8a}	{" :fox:"}
	{\\ud83e\\udd8b}	{" :butterfly:"}
	{\\ud83e\\udd8c}	{" :deer:"}
	{\\ud83e\\udd8d}	{" :gorilla:"}
	{\\ud83e\\udd8e}	{" :lizard:"}
	{\\ud83e\\udd8f}	{" :rhinoceros:"}
	{\\ud83e\\udd90}	{" :shrimp:"}
	{\\ud83e\\udd91}	{" :squid:"}
	{\\ud83e\\udd92}	{" :giraffe:"}
	{\\ud83e\\udd93}	{" :zebra:"}
	{\\ud83e\\udd94}	{" :hedgehog:"}
	{\\ud83e\\udd95}	{" :brontosaurus:"}
	{\\ud83e\\udd96}	{" :tyrannosaurus:"}
	{\\ud83e\\udd97}	{" :grasshopper:"}
	{\\ud83e\\udd98}	{" :kangaroo:"}
	{\\ud83e\\udd99}	{" :llama:"}
	{\\ud83e\\udd9a}	{" :peacock:"}
	{\\ud83e\\udd9b}	{" :hippo:"}
	{\\ud83e\\udd9c}	{" :parrot:"}
	{\\ud83e\\udd9d}	{" :raccoon:"}
	{\\ud83e\\udd9e}	{" :lobster:"}
	{\\ud83e\\udd9f}	{" :mosquito:"}
	{\\ud83e\\udda0}	{" :microbe:"}
	{\\ud83e\\udda1}	{" :badget:"}
	{\\ud83e\\udda2}	{" :swan:"}
	{\\ud83e\\uddb0}	{" :red_haired:"}
	{\\ud83e\\uddb1}	{" :curly_haired:"}
	{\\ud83e\\uddb2}	{" :bald:"}
	{\\ud83e\\uddb3}	{" :white_haired:"}
	{\\ud83e\\uddb4}	{" :bone:"}
	{\\ud83e\\uddb5}	{" :leg:"}
	{\\ud83e\\uddb6}	{" :foot:"}
	{\\ud83e\\uddb7}	{" :tooth:"}
	{\\ud83e\\uddb8}	{" :superhero:"}
	{\\ud83e\\uddb9}	{" :supervillain:"}
	{\\ud83e\\uddc0}	{" :cheese:"}
	{\\ud83e\\uddc1}	{" :cupcake:"}
	{\\ud83e\\uddc2}	{" :salt:"}
	{\\ud83e\\uddd0}	{" :face_monocle:"}
	{\\ud83e\\uddd1}	{" :adult:"}
	{\\ud83e\\uddd2}	{" :child:"}
	{\\ud83e\\uddd3}	{" :older_adult:"}
	{\\ud83e\\uddd4}	{" :man_bearded:"}
	{\\ud83e\\uddd5}	{" :woman_with_headscarf:"}
	{\\ud83e\\uddd6}	{" :person_in_sauna:"}
	{\\ud83e\\uddd7}	{" :person_climbing:"}
	{\\ud83e\\uddd8}	{" :person_lotus_position:"}
	{\\ud83e\\uddd9}	{" :wizard:"}
	{\\ud83e\\uddda}	{" :fairy:"}
	{\\ud83e\\udddb}	{" :vampire:"}
	{\\ud83e\\udddc}	{" :mermaid:"}
	{\\ud83e\\udddd}	{" :elf:"}
	{\\ud83e\\uddde}	{" :genie:"}
	{\\ud83e\\udddf}	{" :zombie:"}
	{\\ud83e\\udde0}	{" :brain:"}
	{\\ud83e\\udde1}	{" :heart_orange:"}
	{\\ud83e\\udde2}	{" :baseball_cap:"}
	{\\ud83e\\udde3}	{" :scarf:"}
	{\\ud83e\\udde4}	{" :gloves:"}
	{\\ud83e\\udde5}	{" :coat:"}
	{\\ud83e\\udde6}	{" :socks:"}
	{\\ud83e\\udde7}	{" :red_envelope:"}
	{\\ud83e\\udde8}	{" :firecracker:"}
	{\\ud83e\\udde9}	{" :jigsaw:"}
	{\\ud83e\\uddea}	{" :testtube:"}
	{\\ud83e\\uddeb}	{" :petri_dish:"}
	{\\ud83e\\uddec}	{" :dna:"}
	{\\ud83e\\udded}	{" :compass:"}
	{\\ud83e\\uddee}	{" :abacus:"}
	{\\ud83e\\uddef}	{" :fire_extinguisher:"}
	{\\ud83e\\uddf0}	{" :toolbox:"}
	{\\ud83e\\uddf1}	{" :bricks:"}
	{\\ud83e\\uddf2}	{" :magnet:"}
	{\\ud83e\\uddf3}	{" :luggage:"}
	{\\ud83e\\uddf4}	{" :lotion:"}
	{\\ud83e\\uddf5}	{" :thread:"}
	{\\ud83e\\uddf6}	{" :yarn:"}
	{\\ud83e\\uddf7}	{" :safety_pin:"}
	{\\ud83e\\uddf8}	{" :teddy_bear:"}
	{\\ud83e\\uddf9}	{" :broom:"}
	{\\ud83e\\uddfa}	{" :basket:"}
	{\\ud83e\\uddfb}	{" :toiletpaper:"}
	{\\ud83e\\uddfc}	{" :soap:"}
	{\\ud83e\\uddfd}	{" :sponge:"}
	{\\ud83e\\uddfe}	{" :receipt:"}
	{\\ud83e\\uddff}	{" :amulet:"}

	{\\udbb8\\uddc4}	{" :monkey_face:"}
	{\\uddba\\udf1a}	{" :hearts:"}
	{\\uddba\\udf1c}	{" :diamonds:"}
	{\\udbba\\udf1d}	{" :clubs:"}
	{\\ufe0f}		{""}
}

# Build the translation table between UTF-8 and it's corresponsing ASCII value
foreach {escapedstring asciistring} [array get ::libunicode::escapedtable] {
	set ::libunicode::utf8table([::libunicode::escaped2utf8 $escapedstring]) $asciistring
}

# Build the translation table between UTF-16 and it's corresponsing ASCII value
foreach {escapedstring asciistring} [array get ::libunicode::escapedtable] {
	set ::libunicode::utf16table([::libunicode::escaped2utf16 $escapedstring]) $asciistring
}
