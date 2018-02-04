# ---------------------------------------------------------------------------- #
# Unicode library for Tcl - v20180202                                          #
#                                                                              #
# written by Eelco Huininga 2016-2018                                          #
# ---------------------------------------------------------------------------- #

namespace eval libunicode {}

# ---------------------------------------------------------------------------- #
# Convert escaped-Unicode characters to ASCII characters                       #
# ---------------------------------------------------------------------------- #
proc ::libunicode::escaped2ascii {txt} {
	foreach {utfstring asciistring} [array get ::libunicode::utftable] {
		set txt [string map -nocase [concat $utfstring $asciistring] $txt]
	}
	return $txt
}

# ---------------------------------------------------------------------------- #
# Convert ASCII characters to escaped-Unicode characters                       #
# ---------------------------------------------------------------------------- #
proc ::libunicode::ascii2escaped {txt} {
	foreach {utfstring asciistring} [array get ::libunicode::utftable] {
		set txt [string map [concat $asciistring $utfstring] $txt]
	}
	return $txt
}

# ---------------------------------------------------------------------------- #
# Convert escaped-Unicode characters to UTF-8 characters                       #
# ---------------------------------------------------------------------------- #
proc ::libunicode::escaped2utf8 {string} {
	set result ""

	set index1 [string first "\\u" $str]

	while {$index1 ne -1} {
		set value1 [string range $str $index1+2 $index1+5]
		scan $value1 %x hex1
		if {($hex1 >= 0xd800) && ($hex1 <= 0xdfff)} {
			set index2 [string first "\\u" $str $index1+5]
			set value2 [string range $str $index2+2 $index2+5]
			scan $value2 %x hex2
			set value [expr 0x10000 + (($hex1 - 0xd800) << 10) + ($hex2 - 0xdc00)]
			set byte1 [expr 0xf0 + (($value & 0x1c0000) >> 18)]
			set byte2 [expr 0x80 + (($value & 0x03f000) >> 12)]
			set byte3 [expr 0x80 + (($value & 0x000fc0) >> 6)]
			set byte4 [expr 0x80 + ($value & 0x00003f)]
#			set str [string map {"\\u$value1\\u$value2" "[binary decode hex [format %x $byte1][format %x $byte2][format %x $byte3][format %x $byte4]]"} $str]
			set result [string range $str 0 $index1-1]
			append result "[binary decode hex [format %x $byte1][format %x $byte2][format %x $byte3][format %x $byte4]]"
			append result [string range $str $index2+6 end]
			set str $result
		} else {
			set str [string map {"\\u$value1" $hex1} $str]
		}
		set index1 [string first "\\u" $str]
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
# Convert escaped-Unicode characters to UTF-16 characters                      #
# ---------------------------------------------------------------------------- #
proc ::libunicode::escaped2utf16 {str} {
	set result ""

	set index1 [string first "\\u" $str]

	while {$index1 ne -1} {
		set value1 [string range $str $index1+2 $index1+5]
		scan $value1 %x hex1
		if {($hex1 >= 0xd800) && ($hex1 <= 0xdfff)} {
			set index2 [string first "\\u" $str $index1+5]
			set value2 [string range $str $index2+2 $index2+5]
			scan $value2 %x hex2
			set byte1 [expr ($value1 & 0xff00) >> 8)]
			set byte2 [expr ($value1 & 0x00ff)]
			set byte3 [expr ($value2 & 0xff00) >> 8)]
			set byte4 [expr ($value2 & 0x00ff)]
#			set str [string map {"\\u$value1\\u$value2" "[binary decode hex [format %x $byte1][format %x $byte2][format %x $byte3][format %x $byte4]]"} $str]
			set result [string range $str 0 $index1-1]
			append result "[binary decode hex [format %x $byte1][format %x $byte2][format %x $byte3][format %x $byte4]]"
			append result [string range $str $index2+6 end]
			set str $result
		} else {
			set str [string map {"\\u$value1" $hex1} $str]
		}
		set index1 [string first "\\u" $str]
	}
	return $str
}

# ---------------------------------------------------------------------------- #
# Convert escaped-Unicode characters to Unicode characters                     #
# ---------------------------------------------------------------------------- #
proc ::libunicode::utf162escaped {string} {
	set result ""

	set index [string first "\\u" $string]

	while {$index ne -1} {
		set value [string range $string $index+2 $index+5]
		scan $value %x hex
		set string [string map {"\\u$value" $hex} $string]
		set index [string first "\\u" $string $index+1]	
	}
	return $string
}

# ---------------------------------------------------------------------------- #
# Convert Unicode characters to ASCII characters                               #
# ---------------------------------------------------------------------------- #
proc ::libunicode::unicode2ascii {string} {
	foreach {unicodestring asciistring} [array get ::libunicode::unicodetable] {
		set txt [string map -nocase [concat $unicodestring $asciistring] $txt]
	}
	return $txt
}

# ---------------------------------------------------------------------------- #
# Convert ASCII characters to Unicode characters                               #
# ---------------------------------------------------------------------------- #
proc ::libunicode::ascii2unicode {string} {
	foreach {unicodestring asciistring} [array get ::libunicode::unicodetable] {
		set txt [string map [concat $asciistring $unicodestring] $txt]
	}
	return $txt
}

# http://www.charbase.com/
# http://www.charbase.com/block/emoticons
# http://www.charbase.com/block/miscellaneous-symbols-and-pictographs

array set ::libunicode::utftable {
	{\\u00a1}	{¡}
	{\\u00a2}	{¢}
	{\\u00a3}	{£}
	{\\u00a4}	{€}
	{\\u00a5}	{¥}
	{\\u00a6}	{Š}
	{\\u00a7}	{§}
	{\\u00a8}	{š}
	{\\u00a9}	{©}
	{\\u00aa}	{ª}
	{\\u00ab}	{«}
	{\\u00ac}	{¬}
	{\\u00ae}	{®}
	{\\u00af}	{¯}
	{\\u00b0}	{°}
	{\\u00b1}	{±}
	{\\u00b2}	{²}
	{\\u00b3}	{³}
	{\\u00b4}	{Ž}
	{\\u00b5}	{µ}
	{\\u00b6}	{¶}
	{\\u00b7}	{·}
	{\\u00b8}	{ž}
	{\\u00b9}	{¹}
	{\\u00ba}	{º}
	{\\u00bb}	{»}
	{\\u00bc}	{Œ}
	{\\u00bd}	{œ}
	{\\u00be}	{Ÿ}
	{\\u00bf}	{¿}
	{\\u00c0}	{À}
	{\\u00c1}	{Á}
	{\\u00c2}	{Â}
	{\\u00c3}	{Ã}
	{\\u00c4}	{Ä}
	{\\u00c5}	{Å}
	{\\u00c6}	{Æ}
	{\\u00c7}	{Ç}
	{\\u00c8}	{È}
	{\\u00c9}	{É}
	{\\u00ca}	{Ê}
	{\\u00cb}	{Ë}
	{\\u00cc}	{Ì}
	{\\u00cd}	{Í}
	{\\u00ce}	{Î}
	{\\u00cf}	{Ï}
	{\\u00e0}	{à}
	{\\u00e1}	{á}
	{\\u00e2}	{â}
	{\\u00e3}	{ã}
	{\\u00e4}	{ä}
	{\\u00e5}	{å}
	{\\u00e6}	{æ}
	{\\u00e7}	{ç}
	{\\u00e8}	{è}
	{\\u00e9}	{é}
	{\\u00ea}	{ê}
	{\\u00eb}	{ë}
	{\\u00ec}	{ì}
	{\\u00ed}	{í}
	{\\u00ee}	{î}
	{\\u00ef}	{ï}
	{\\u00f0}	{ð}
	{\\u00f1}	{ñ}
	{\\u00f2}	{ò}
	{\\u00f3}	{ó}
	{\\u00f4}	{ô}
	{\\u00f5}	{õ}
	{\\u00f6}	{ö}
	{\\u00f7}	{÷}
	{\\u00f8}	{ø}
	{\\u00f9}	{ù}
	{\\u00fa}	{ú}
	{\\u00fb}	{û}
	{\\u00fc}	{ü}
	{\\u00fd}	{ý}
	{\\u00fe}	{þ}
	{\\u00ff}	{ÿ}
	{\\u0e3f}	{"฿"}
	{\\u2019}	{"'"}
	{\\u203c}	{" !!"}
	{\\u2049}	{" !?"}
	{\\u20a8}	{"₨"}
	{\\u20a9}	{"₩"}
	{\\u20aa}	{"₪"}
	{\\u20ab}	{"₫"}
	{\\u20ac}	{"€"}
	{\\u20b1}	{"₱"}
	{\\u20b9}	{"₹"}
	{\\u2105}	{" c/o"}
	{\\u2117}	{"℗"}
	{\\u2120}	{"℠"}
	{\\u2122}	{"™"}
	{\\u2139}	{" :information_source:"}
	{\\u2194}	{" :left_right:"}
	{\\u2195}	{" :up_down:"}
	{\\u2196}	{" :northwest:"}
	{\\u2197}	{" :northeaast:"}
	{\\u2198}	{" :southeast:"}
	{\\u2199}	{" :southwest:"}
	{\\u21a9}	{" :back_left:"}
	{\\u21aa}	{" :back_right:"}
	{\\u231a}	{" :watch:"}
	{\\u231b}	{" :hourglass:"}
	{\\u23ec}	{" :arrow_double_down:"}
	{\\u24c2}	{" :m:"}
	{\\u25aa}	{" :black_small_square:"}
	{\\u25ab}	{" :white_small_square:"}
	{\\u25c0}	{" :arrow_backward:"}
	{\\u25fb}	{" :white_medium_square:"}
	{\\u25fc}	{" :black_medium_square:"}
	{\\u25fd}	{" :white_medium_small_square:"}
	{\\u2600}	{" :sunny:"}
	{\\u2601}	{" :cloud:"}
	{\\u2602}	{" :umbrella:"}
	{\\u2614}	{" :umbrella_rain:"}
	{\\u2615}	{" :coffee:"}
	{\\u2648}	{" :aries:"}
	{\\u2649}	{" :taurus:"}
	{\\u264a}	{" :gemini:"}
	{\\u264b}	{" :cancer:"}
	{\\u264d}	{" :virgo:"}
	{\\u264e}	{" :libra:"}
	{\\u2650}	{" :sagittarius:"}
	{\\u2651}	{" :capricorn:"}
	{\\u2652}	{" :aquarius:"}
	{\\u2653}	{" :pisces:"}
	{\\u2660}	{" :spades:"}
	{\\u2663}	{" :clubs:"}
	{\\u2665}	{" :hearts:"}
	{\\u2668}	{" :warning_hot:"}
	{\\u267b}	{" :recycle:"}
	{\\u267f}	{" :wheelchair:"}
	{\\u2693}	{" :anchor:"}
	{\\u26a0}	{" :warning:"}
	{\\u26a1}	{" :zap:"}
	{\\u26aa}	{" :white_circle:"}
	{\\u26ab}	{" :black_circle:"}
	{\\u26b0}	{" :coffin:"}
	{\\u26bd}	{" :soccer:"}
	{\\u26d4}	{" :no_entry:"}
	{\\u26ea}	{" :church:"}
	{\\u26f2}	{" :fountain:"}
	{\\u26f3}	{" :golf:"}
	{\\u26f5}	{" :sailboat:"}
	{\\u26fa}	{" :tent:"}
	{\\u26fb}	{" :gaspump:"}
	{\\u2702}	{" :scissors:"}
	{\\u2705}	{" :check_mark:"}
	{\\u2708}	{" :airplane:"}
	{\\u2709}	{" :envelope:"}
	{\\u270a}	{" :raised_fist:"}
	{\\u270c}	{" :v:"}
	{\\u270f}	{" :pencil:"}
	{\\u2712}	{" :ink_pen:"}
	{\\u2716}	{" :heavy_multiplication_x:"}
	{\\u2728}	{" :sparkles:"}
	{\\u2734}	{" :eight_pointed_black_star:"}
	{\\u2744}	{" :snowflake:"}
	{\\u2753}	{" :?_black:"}
	{\\u2754}	{" :?_grey:"}
	{\\u2755}	{" :!_grey:"}
	{\\u2757}	{" :!:"}
	{\\u2763}	{" :heart_exclamation_mark:"}
	{\\u2764}	{" :heart:"}
	{\\u2797}	{" :heavy_division_sign:"}
	{\\u27b0}	{" :curly_loop:"}
	{\\u2935}	{" :arrow_heading_down:"}
	{\\u2b05}	{" :arrow_left:"}
	{\\u2b1b}	{" :black_large_square:"}
	{\\u2b1c}	{" :white_large_square:"}
	{\\u2b50}	{" :star:"}
	{\\u2b55}	{" :circle:"}
	{\\u3030}	{" :wavy_dash:"}
	{\\ud83c\\udd8e}	{" :bloodtype_ab:"}
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
	{\\ud83c\\udf92}	{" :school_satchel:"}
	{\\ud83c\\udf93}	{" :graduation_cap:"}
	{\\ud83c\\udf94}	{" :heart_tip:"}
	{\\ud83c\\udf95}	{" :bouquet:"}
	{\\ud83c\\udf96}	{" :medal:"}
	{\\ud83c\\udf97}	{" :ribbon:"}
	{\\ud83c\\udf98}	{" :keyboard:"}
	{\\ud83c\\udf99}	{" :microphone:"}
	{\\ud83c\\udf9a}	{" :mixer_slider:"}
	{\\ud83c\\udf9b}	{" :mixer_knobs:"}
	{\\ud83c\\udf9c}	{" :music_note:"}
	{\\ud83c\\udfa9}	{" :tophat:"}
	{\\ud83c\\udfaa}	{" :circus_tent:"}
	{\\ud83c\\udfae}	{" :video_game:"}
	{\\ud83c\\udfc6}	{" :trophy:"}
	{\\ud83c\\udffb}	{""}
	{\\ud83c\\udffc}	{""}
	{\\ud83d\\udc00}	{" :rat:"}
	{\\ud83d\\udc01}	{" :mouse:"}
	{\\ud83d\\udc02}	{" :ox:"}
	{\\ud83d\\udc03}	{" :water_buffalo:"}
	{\\ud83d\\udc04}	{" :cow:"}
	{\\ud83d\\udc05}	{" :tiger:"}
	{\\ud83d\\udc06}	{" :leopard:"}
	{\\ud83d\\udc07}	{" :rabbit:"}
	{\\ud83d\\udc08}	{" :cat:"}
	{\\ud83d\\udc09}	{" :dragon:"}
	{\\ud83d\\udc0a}	{" :crocodile:"}
	{\\ud83d\\udc0b}	{" :whale:"}
	{\\ud83d\\udc0c}	{" :snail:"}
	{\\ud83d\\udc0d}	{" :snake:"}
	{\\ud83d\\udc0e}	{" :horse:"}
	{\\ud83d\\udc0f}	{" :ram:"}
	{\\ud83d\\udc10}	{" :goat:"}
	{\\ud83d\\udc11}	{" :sheep:"}
	{\\ud83d\\udc12}	{" :monkey:"}
	{\\ud83d\\udc13}	{" :rooster:"}
	{\\ud83d\\udc14}	{" :dog:"}
	{\\ud83d\\udc15}	{" :chicken:"}
	{\\ud83d\\udc16}	{" :pig:"}
	{\\ud83d\\udc17}	{" :boar:"}
	{\\ud83d\\udc18}	{" :elephant:"}
	{\\ud83d\\udc19}	{" :octopus:"}
	{\\ud83d\\udc1a}	{" :shell:"}
	{\\ud83d\\udc1b}	{" :bug:"}
	{\\ud83d\\udc1c}	{" :ant:"}
	{\\ud83d\\udc1d}	{" :bee:"}
	{\\ud83d\\udc1e}	{" :ladybug:"}
	{\\ud83d\\udc1f}	{" :fish:"}
	{\\ud83d\\udc20}	{" :tropical_fish:"}
	{\\ud83d\\udc21}	{" :blowfish:"}
	{\\ud83d\\udc22}	{" :turtle:"}
	{\\ud83d\\udc23}	{" :hatching_chick:"}
	{\\ud83d\\udc24}	{" :baby_chick:"}
	{\\ud83d\\udc25}	{" :hatched_chick:"}
	{\\ud83d\\udc26}	{" :bird:"}
	{\\ud83d\\udc27}	{" :penguin:"}
	{\\ud83d\\udc28}	{" :koala:"}
	{\\ud83d\\udc29}	{" :poodle:"}
	{\\ud83d\\udc2a}	{" :dromedary:"}
	{\\ud83d\\udc2b}	{" :camel:"}
	{\\ud83d\\udc2c}	{" :dolphin:"}
	{\\ud83d\\udc2d}	{" :mouse_face:"}
	{\\ud83d\\udc2e}	{" :cow_face:"}
	{\\ud83d\\udc2f}	{" :tiger_face:"}
	{\\ud83d\\udc30}	{" :rabbit_face:"}
	{\\ud83d\\udc31}	{" :cat_face:"}
	{\\ud83d\\udc32}	{" :dragon_face:"}
	{\\ud83d\\udc33}	{" :whale:"}
	{\\ud83d\\udc34}	{" :horse_face:"}
	{\\ud83d\\udc35}	{" :monkey_face:"}
	{\\ud83d\\udc36}	{" :dog_face:"}
	{\\ud83d\\udc37}	{" :pig_face:"}
	{\\ud83d\\udc38}	{" :frog_face:"}
	{\\ud83d\\udc39}	{" :hamster_face:"}
	{\\ud83d\\udc3a}	{" :wolf_face:"}
	{\\ud83d\\udc3b}	{" :bear_face:"}
	{\\ud83d\\udc3c}	{" :panda_face:"}
	{\\ud83d\\udc3d}	{" :pig_nose:"}
	{\\ud83d\\udc40}	{" :eyes:"}
	{\\ud83d\\udc41}	{" :eye:"}
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
	{\\ud83d\\udc7d}	{" :alien:"}
	{\\ud83d\\udc8b}	{" :kissing_lips:"}
	{\\ud83d\\udc8d}	{" :ring:"}
	{\\ud83d\\udc8e}	{" :gem:"}
	{\\ud83d\\udc93}	{" :heart_pulsating:"}
	{\\ud83d\\udc94}	{" :heart_broken:"}
	{\\ud83d\\udc95}	{" :two_hearts:"}
	{\\ud83d\\udc96}	{" :heart_sparkling:"}
	{\\ud83d\\udc97}	{" :heart_beating:"}
	{\\ud83d\\udc99}	{" :heart_blue:"}
	{\\ud83d\\udc9a}	{" :heart_green:"}
	{\\ud83d\\udc9b}	{" :heart_yellow:"}
	{\\ud83d\\udca0}	{" :diamond_shape_with_a_dot_inside:"}
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
	{\\ud83d\\udcb0}	{" :moneybag:"}
	{\\ud83d\\udcc0}	{" :dvd:"}
	{\\ud83d\\udcdd}	{" :memo:"}
	{\\ud83d\\udcf0}	{" :newspaper:"}
	{\\ud83d\\udcfb}	{" :radio:"}
	{\\ud83d\\udcfc}	{" :vhs:"}
	{\\ud83d\\udc38}	{" :frogface:"}
	{\\ud83d\\udd0a}	{" :loud_sound:"}
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
	{\\ud83d\\udd2a}	{" :knife:"}
	{\\ud83d\\udd32}	{" :black_square_button:"}
	{\\ud83d\\udd33}	{" :white_square_button:"}
	{\\ud83d\\udd34}	{" :red_circle:"}
	{\\ud83d\\udd35}	{" :large_blue_circle:"}
	{\\ud83d\\udd38}	{" :small_orange_diamond:"}
	{\\ud83d\\udd3b}	{" :small_red_triangle_down:"}
	{\\ud83d\\udd3c}	{" :arrow_up_small:"}
	{\\ud83d\\udd3d}	{" :arrow_down_small:"}
	{\\ud83d\\udd43}	{" :left_semicircle:"}
	{\\ud83d\\udd90}	{" :hand_raised:"}
	{\\ud83d\\udd95}	{" :middle_finger:"}
	{\\ud83d\\udde5}	{" :ray_below:"}
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
	{\\ud83d\\ude59}	{" :sw_vine:"}
	{\\ud83d\\ude95}	{" :car:"}
	{\\ud83d\\udea0}	{" :mountain_cableway:"}
	{\\ud83d\\udea9}	{" :triangular_flag_on_post:"}
	{\\ud83d\\udeab}	{" :no_entry_sign:"}
	{\\ud83d\\udeac}	{" :cigarette:"}
	{\\ud83d\\udeb2}	{" :bicycle:"}
	{\\ud83d\\udeb5}	{" :cyclist:"}
	{\\ud83d\\udebf}	{" :shower:"}
	{\\ud83d\\udf44}	{" :mushroom:"}
	{\\ud83d\\udf7a}	{" :beer:"}
	{\\ud83d\\udffb}	{" "}
	{\\ud83e\\udd10}	{" :zipper_mouth:"}
	{\\ud83e\\udd11}	{" :money_mouth:"}
	{\\ud83e\\udd13}	{" :nerd:"}
	{\\ud83e\\udd14}	{" :thinking:"}
	{\\ud83e\\udd17}	{" :hugging_face:"}
	{\\ud83e\\udd18}	{" :hands_hornsign:"}
	{\\ud83e\\udd21}	{" :clown:"}
	{\\ud83e\\udd2a}	{" :crazy_face:"}
	{\\ud83e\\udd23}	{" :rofl:"}
	{\\ud83e\\udd43}	{" :whiskey:"}
	{\\udbb8\\uddc4}	{" :monkey_face:"}
	{\\uddba\\udf1a}	{" :hearts:"}
	{\\uddba\\udf1c}	{" :diamonds:"}
	{\\udbba\\udf1d}	{" :clubs:"}
	{\\ufe0f}		{""}
}

# Build the translation table between UTF-8 and it's corresponsing ASCII value
foreach {escapedstring asciistring} [array get ::libunicode::utftable] {
	set utf8table([::libunicode::escaped2utf8 $escapedstring]) $asciistring
}

# Build the translation table between UTF-16 and it's corresponsing ASCII value
foreach {escapedstring asciistring} [array get ::libunicode::utftable] {
	set utf16table([::libunicode::escaped2utf16 $escapedstring]) $asciistring
}
