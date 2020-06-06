# Changelog
## Unreleased
* Changed scale factor of avatar image in channel view.
* Added description field
* Moved upload to another controller
* Added thumbnail view of video in upload details controller.
* Added back button to upload details.
* Added channel video controller for videos on channels.
* Added collection view to channel view controller
* Added collection view to other channel view controller (doesn't play video yet)
* Moved profile divider line down by 5px
* Added thumbnails to videos on your own channel
* Updated api request for avatar urls.
* Added thumbnails to videos on others' channels 
* Video playback controller for channel videos plays videos (still needs some minor imporvements)
* Fixed other channel's avatars (forgot to update the api)
* You can now playback other channels' videos.
* Removed dismiss from record view controller (possible bug)
* Some minor design changes (fixed size for all back arrows, change size of lists, set static position for all back arrows and other buttons)
* Fixed back button
* Made it so that if your device is silented you can still hear video audio.
* Added dropdown menu in other channel view (work in progress)
* Dropdown menu is now hidden on load and can be opened.
* Fixed view will appear and view will dissapear.
* Dropdown menu will now disappear when clicked off of it.
## v0.2.5 (PRERELEASE)
* Account settings editing now works (actually contacts the api)
* Fixed bug where timer would stop forever and load any user info until app restart
* Fixed bug where timer would go one last cycle after logging out.
* Added some navigation improvments.
* Avatar changes now go through the api (and actually change. wow!)
* Added record feature to record view controller (doesn't contact api yet.)
* Changed timer time on some view controllers
* Added other profiles.
* Added follower list to other user's profiles.
* Made profile divider change to white if user's theme is set to dark mode.
* Improved error handling (haha again!)
* Added following list to other user's profiles. (You can view them and stuff)
* Minor design changes
* Improvements (ah yes so specific)
* Fixed bug where if bio was empty app would crash.
* Video player now loops
* Fixed bug where edited image wouldn't save
* Fixed bug where video would keep looping even when you dismissed the screen.
* Fixed bug where user's bio would overlap with profile divider line.
* Uploading videos now works! 
* Added feature where when user dismissed the view, it will invalidate the timer, and when the view appeared again it validated the timer.
## v0.2 (PRERELEASE)
* Added more error handling
* Some more constraints
* Removed extra cells from follower and following list
* Added acitvity indicator
* Improved error handling
* Signing up now works through the app
* Fixed the default avatar
* Fixed api url
* Added api fetching (10 second interval)
* Changed SwiftKeychainWrapper to Valet (Should fix the keychain issue)
* Fixed bug where timer would continue when user would log out.
* Added "nothing here" on follower list and following list when a user doesn't have any followers or any one they are following.
* Added account settings view controller (Doesn't actually contact the api. Just placeholder for now.)
* Moved Nuke dependency from Swift Package Manger to Cocoapods.
* Gallery for record page works now (but doesn't send any file anywhere)
* Added bio to channel page.
* Some design changes
* Added most channel attrbitues that update (except followers and following)
* Fixed some bugs with token and id not being saved to keychain
* Fixed login page bug (not being able to login and keyboard not going down)
* Added functioning follower list (except being able to click on a user's profile picture to bring them to their profile)
* Added functioning following list (Except being able to click on a user's profile picture to bring them to their profile)
* Made the back arrow dismiss the page for every page (except the record page).
* Fixed a login page bug on ios 13 where the spinner kept spinning and did nothing else when someone tried to login
* Changed project back to ios 13 only (Follower list screwed ios 12.4 over)
## v0.1.5 (PRERELEASE)
* Added more authentication controllers 
* Logout feature (with keychain)
* Sign in api and keychain feature
* Alamofire + cocoapods
* Added support for iOS 12.4 (only for development purposes)
* Fixed some bugs (including the alert box one)
## v0.1.1 (PRERELEASE)
* Added part 1 of videos
* Added more controllers (settings, gallery, and authenticate)
* Added search bar to search page
* Labeled each tab bar page (for development purposes)
* Added some more buttons and icons

##  v0.1 (PRERELEASE)
* Added icons
* remade the project in storyboard.
* Added the initial pages
