-- Org Protocol.app: macOS hands org-protocol:// URLs from the browser to this
-- applet, which passes them to Emacs through emacsclient, starting Emacs first
-- if its server isn't up. Built and registered by install.sh, which fills in
-- the emacsclient path below.

property emacsclient : "/Applications/Emacs.app/Contents/MacOS/bin/emacsclient"

on open location theURL
	if not serverUp() and application id "org.gnu.Emacs" is not running then
		-- Start Emacs (its init must call server-start) and give it up to 30s.
		tell application id "org.gnu.Emacs" to launch
		repeat 60 times
			delay 0.5
			if serverUp() then exit repeat
		end repeat
	end if
	try
		do shell script quoted form of emacsclient & " -n " & quoted form of theURL
	on error errorMessage
		activate
		display alert "Org capture failed" message errorMessage as critical
		return
	end try
	if theURL starts with "org-protocol://reason-capture" then
		-- Org Reason files the capture itself, so stay in the browser.
		display notification "Captured to the Org Reason inbox" with title "Org capture"
	else if theURL contains "template=L&" or theURL starts with "org-protocol://capture:/L/" then
		display notification "Link filed in your Org inbox" with title "Org capture"
	else
		-- Other captures open a capture buffer to finish in Emacs.
		tell application id "org.gnu.Emacs" to activate
	end if
end open location

on serverUp()
	try
		do shell script quoted form of emacsclient & " -e t"
		return true
	on error
		return false
	end try
end serverUp
