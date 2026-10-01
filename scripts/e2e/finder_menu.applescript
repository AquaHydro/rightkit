-- 用法：osascript finder_menu.applescript <folder> <items a|b 或 ""> <菜单路径 A>B>C 或 "?" 只读顶层>
on run argv
	set folderPath to item 1 of argv
	set sel to item 2 of argv
	set menuPath to item 3 of argv
	tell application "Finder"
		activate
		set w to front window
		set target of w to (POSIX file folderPath as alias)
		set current view of w to list view
		delay 0.4
		if sel is "" then
			select {}
		else
			set AppleScript's text item delimiters to "|"
			set names to text items of sel
			set AppleScript's text item delimiters to ""
			set picks to {}
			repeat with n in names
				set end of picks to (item (n as text) of (POSIX file folderPath as alias))
			end repeat
			select picks
		end if
	end tell
	delay 0.5
	tell application "System Events" to tell process "Finder"
		set frontmost to true
		set theOutline to outline 1 of scroll area 1 of splitter group 1 of splitter group 1 of front window
		if sel is "" then keystroke "a" using {command down, option down}
		delay 0.3
		perform action "AXShowMenu" of theOutline
		delay 1.5
		set m to menu 1 of theOutline
		if menuPath is "?" then
			set out to {}
			repeat with mi in (every menu item of m)
				try
					set t to value of attribute "AXTitle" of mi
					if t is not "" then set end of out to t
				end try
			end repeat
			key code 53
			return out
		end if
		set AppleScript's text item delimiters to ">"
		set parts to text items of menuPath
		set AppleScript's text item delimiters to ""
		repeat with i from 1 to (count of parts)
			set target to missing value
			repeat with mi in (every menu item of m)
				try
					if (value of attribute "AXTitle" of mi) is (item i of parts) then
						set target to mi
						exit repeat
					end if
				end try
			end repeat
			if target is missing value then
				key code 53
				delay 0.2
				key code 53
				return "not found: " & (item i of parts)
			end if
			if i < (count of parts) then
				perform action "AXPress" of target
				delay 0.4
				set m to menu 1 of target
			else
				perform action "AXPress" of target
			end if
		end repeat
		return "pressed " & menuPath
	end tell
end run
