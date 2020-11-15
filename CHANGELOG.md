# Changelog
## Unreleased (PRERELEASE)
* Channel Videos
    * Fixed urls to match new api
* Comments
    * Changed thumbs up icon to heart icon
    * Added functionality for like count to update
    * Added liking to comments
    * Added read more button to comments
    * Replying to comments
    * You can now delete comments
    * Edit comments
* UI Tests
    * Updated method that tested the app launch time.
* Authentication
    * Fixed bug where you couldn't log in after logging out recently.
* Misc.
    * Fixed some pod bugs
## v0.3.5 (PRERELEASE)
* ChannelVideoView
    * Fixed bug where liking video would first go +2 and then correct itself half of a second later.
    * Added liking to videos (+ like count)
    * Ad 4ded comments to videos
    * Tap on any part of the video preview to pause or play the video.
    * Added description label.
    * Videos play sound even if you are on silent (fixed it for reals now.)
    * You can share videos and download them (a couple bugs still work in progress.)
    * Fixed the url api so loading the video thumbnails doens't count as a view.
    * Added view count
    * Added publish date.
    * Made it so that after the view count it says Views (or view if it only has one view)
    * Added better optimization (instead of `if, if else, if else, if else` instead it now uses switch and case)
    * Removed timer from refreshing video (what?)
    * Fixed bug where if you watched enough videos the app would crash due to memory leak.
    * Changed video aspect resize from resizeaspectfill to resizeaspect.
    * Added video scrolling (with texture tableview + cell node)
    * Moved all overlays to seperate class
    * Temporarily removed the share functionality.
    * Removed gradient
* Channel Video Overlay View
    * Made  `else if` statements into switches.
    * Channel icon and comment button now function as intended
    * Added channel video overlay view delegate to tell parent view controller to present other view controllers.
    * Added throttling to liking/unliking a video (so sever doesn't get spammed + better ui)
*  Description Overlay View
    * This view shows the description
    * Added delegate to fetch the description, views, and publish date from ChannelVideoOverlayview
* Channel Dropdown View Controller 
    * Removed. All the functions have been move to the other channel view controller.
* Channel Views
    * Made it so if its over 1000 it turns into 1.0k, then if over 10,000 it will be 10k, and so on. It's limit is about 1 billion. (following + followers)
    * Optimized channel thumbnail
    * Made it so you can't show the other channel dropdown menu if the uesr if you.
    * Made it so if you are viewing your own channel in other channel view then you can change your profile picture.
    * Made follower/following count bigger to fit results up to 4 digits
    * Made video thumbnails show gray box if loading
    * Fixed bug where anything over 1000 followers or following would show up with the .0k tag. (ex. 1032.2k)
    * Added better optimization (instead of `if, if else, if else, if else` instead it now uses switch and case)
    * Removed timer from refreshing the channel.
    * Added pull to refresh.
    * Updated url for video thumbnails to match api.
    * Added dropdown menu
    * Follow people with the dropdown menu
    * Unfollow people with the dropdown menu.
    * Fixed bug where user's would get dropdown menu even if the profile was theirs.
    * Added new video scrolling functionality to other channel view controller.
* Channel Followers + following
    * Fixed warning in following whereit would be comparing nil would always return false
    * Removed timer for refreshing the list.
    * Added pull to refresh
    * Removed follower + follow list (to leave other follow and follower list) for better optimization.
* Camera Views
    * Going to camera will return it to the last position you left it at.
    * Fixed bug where first frame of video would be black making thumbnails completly black.
    * Changed default camera to rear camera
    * Fixed bug where if you tried going to the front camera and record the app would crash
    * Fixed bug where mic would not work when recording if you flipped the camera.
    * Pinch to zoom now works.
    * Uploading from gallery now works.
    * You can now flip the camera.
    * Fixed bug where done button in upload details would take you to the details of the previous video you uploaded.
    * Fixed bug where app would crash if you recorded video, went to playback, and went back to video it would crash the app.
* Authentication
    * If you are already logged in it actually skips the login page (got it to work finally)
    * If you were already logged in before it checks with the api if your token and username are valid.
    * Made it so the app checks if you are valid once you have loaded the home page.
    * Made it so app doesn't crash when you try and sign out too quicky.
    * Fixed bug where app would crash when you would sign out
* Home View Controller 
    * Changed if else statements to switch
    * Removed showInvalidSession (as it wasn't working anyway)
    * App actually kicks you into the login screen if your user token is invalid
    * Added status code check (to check 401 if user is unauthorized)
    * Fixed bug where app would crash if your user was invalid
    * Added home feed (Shows random videos across the platform)
    * Added batch fetching to home feed
* Storyboards
    * Changed the flip icon to the none deprecated one in the record view.
    * Added second storyboard
    * Removed view from video view controller (it is no longer needed)
* Settings
    * Change sign out button color to red
    * Added clear cache button.
* Design
    * Added back the record icon in tab bar.
    * Minor design changes
* Search
    * Pressing return on search bar will now make the keyboard disppear
    * Removed following from search results.
    * When you see a user in the search you can now click on it to bring you to their channel.
    * User searching works as intented
    * Added pull to fetch new search results
    * Added video search
    * Made tableview hidden with "isHidden" instead of removing it and adding it to the super view.
    * Updated search to work with the new video playback.
* Recording
    * Added zooming on front camera
    * Thumbnail is now correctly rotated in upload details.
    * Changed from custom camera method to using NextLevel
* Other
    * Added more error handling.
    * Added groups for better sorting
    * Organized changelog
    * Migrated to new version of Nuke, Alamofire, and Valet
    * Removed some old code that was causing warnings
    * Changed minimum ios version to ios 14.
    * Added more and better mark comments.
    * Changed name of some groups.
    * Added video group
    * Added bridging header (to support gradient node objective c files)
    * Cleaned up code
    * Added showMessage function instead of having whole new function for every different alert message.
## v0.3 (PRERELEASE)
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
* Made it so that if your device is silented you can still hear video audio. (works)
* Added dropdown menu in other channel view (work in progress)
* Dropdown menu is now hidden on load and can be opened.
* Fixed view will appear and view will dissapear.
* Dropdown menu will now disappear when clicked off of it.
* Dropdown menu fully closes when clicking on avatar.
* Added setting to settings bundle.
* Adjusted design of app to fit on 4.7inch displays (for development)
* Recording playback stops when you exit from the playback view controller.
* Optimized code to run less on the main thread.
* Made thumbnail of video 108 x 192 to fit the portrait aspect ratio of most videos.
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
