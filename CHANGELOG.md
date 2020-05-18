# Changelog
## Unrelease
* Account settings editing now works (actually contacts the api)
* Fixed bug where timer would stop forever and load any user info until app restart
* Fixed bug where timer would go one last cycle after logging out.
* Added some navigation improvments.
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
