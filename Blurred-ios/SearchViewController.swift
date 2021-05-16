//
//  SecondViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Alamofire
import Nuke

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    
    // MARK: Number Of Rows In Section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case self.tableView:
            return users.count
        case self.videoTableView:
            return videos.count
        default:
            return videos.count
        }
    }
    
    
    // MARK: Lets
    private let refreshControl = UIRefreshControl()
    private let videoRefreshControl = UIRefreshControl()
    
    
    // MARK: Received Memory Warning
    override func didReceiveMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
    // MARK: Cell For Row At
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case self.tableView:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell") as? SearchCell else { return UITableViewCell() }
            let username: String? = users[indexPath.row].username
            
            cell.searchAvatar.image = nil
            
            AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/channels/\(username!).json").responseJSON { response in
                var JSON: [String: Any]?
                do {
                    JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                    let avatarUrl = JSON!["avatar_url"] as? String
                    let username = JSON!["username"] as? String
                    let name = JSON!["name"] as? String
                    let bio = JSON!["bio"] as? String
                    let followerCount = JSON!["followers_count"] as? Int
                    let followerCountString = String("\(followerCount ?? 0)")
                    guard let railsUrl = URL(string: "https://www.bartenderdogseatmuffins.xyz\(avatarUrl ?? "/assets/fallback/default-avatar-3.png")") else { return }
                    DispatchQueue.main.async {
                        Nuke.loadImage(with: railsUrl, into: cell.searchAvatar)
                        cell.searchName.text = name ?? ""
                        cell.searchUsername.text = username ?? ""
                        cell.searchBio.text = bio ?? ""
                        cell.searchFollowerCount.text = followerCountString
                    }
                    cell.avatarUrl = railsUrl.absoluteString
                } catch {
                    return
                }
                tableView.deselectRow(at: indexPath, animated: true)
            }
            return cell
        case self.videoTableView:
            guard let cell = videoTableView.dequeueReusableCell(withIdentifier: "SearchVideoCell") as? SearchVideoCell else { return UITableViewCell() }
            let Id: Int = videos[indexPath.row].id
            AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/videoinfo/\(Id).json").responseJSON { response in
                var JSON: [String: Any]?
                do {
                    JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                    guard let thumbnailUrl = JSON!["thumbnail_url"] as? String else { return }
                    guard let description = JSON!["description"] as? String else { return }
                    guard let username = JSON!["username"] as? String else { return }
                    guard let publishDate = JSON!["publishdate"] as? String else { return }
                    guard let viewCount = JSON!["viewcount"] as? Int else { return }
                    guard let railsUrl = URL(string: thumbnailUrl) else { return }
                    switch viewCount {
                    case _ where viewCount < 1000:
                        DispatchQueue.main.async {
                            cell.searchViewCount.text = "\(viewCount)"
                        }
                    case _ where viewCount > 1000 && viewCount < 100000:
                        DispatchQueue.main.async {
                            cell.searchViewCount.text = "\(viewCount/1000).\((viewCount/100)%10)k" }
                    case _ where viewCount > 100000 && viewCount < 1000000:
                        DispatchQueue.main.async {
                            cell.searchViewCount.text = "\(viewCount/1000)k"
                        }
                    case _ where viewCount > 1000000 && viewCount < 100000000:
                        DispatchQueue.main.async {
                            cell.searchViewCount.text = "\(viewCount/1000000).\((viewCount/1000)%10)M"
                        }
                    case _ where viewCount > 100000000:
                        DispatchQueue.main.async {
                            cell.searchViewCount.text = "\(viewCount/1000000)M"
                        }
                    default:
                        DispatchQueue.main.async {
                            cell.searchViewCount.text = "\(viewCount)"
                        }
                    }
                    DispatchQueue.main.async {
                        Nuke.loadImage(with: railsUrl, into: cell.searchThumbnail)
                        cell.searchDescription.text = description
                        cell.searchUsername.text = username
                        cell.searchDate.text = publishDate
                    }
                } catch {
                    return
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
            return cell
        default:
            guard let cell = videoTableView.dequeueReusableCell(withIdentifier: "SearchVideoCell") as? SearchVideoCell else { return UITableViewCell() }
            let Id: Int = videos[indexPath.row].id
            AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/videoinfo/\(Id).json").responseJSON { response in
                var JSON: [String: Any]?
                do {
                    JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                    guard let thumbnailUrl = JSON!["thumbnail_url"] as? String else { return }
                    guard let description = JSON!["description"] as? String else { return }
                    guard let username = JSON!["username"] as? String else { return }
                    guard let publishDate = JSON!["publishdate"] as? String else { return }
                    guard let viewCount = JSON!["viewcount"] as? Int else { return }
                    guard let railsUrl = URL(string: "https://www.bartenderdogseatmuffins.xyz\(thumbnailUrl)") else { return }
                    switch viewCount {
                    case _ where viewCount < 1000:
                        DispatchQueue.main.async {
                            cell.searchViewCount.text = "\(viewCount)"
                        }
                    case _ where viewCount > 1000 && viewCount < 100000:
                        DispatchQueue.main.async {
                            cell.searchViewCount.text = "\(viewCount/1000).\((viewCount/100)%10)k" }
                    case _ where viewCount > 100000 && viewCount < 1000000:
                        DispatchQueue.main.async {
                            cell.searchViewCount.text = "\(viewCount/1000)k"
                        }
                    case _ where viewCount > 1000000 && viewCount < 100000000:
                        DispatchQueue.main.async {
                            cell.searchViewCount.text = "\(viewCount/1000000).\((viewCount/1000)%10)M"
                        }
                    case _ where viewCount > 100000000:
                        DispatchQueue.main.async {
                            cell.searchViewCount.text = "\(viewCount/1000000)M"
                        }
                    default:
                        DispatchQueue.main.async {
                            cell.searchViewCount.text = "\(viewCount)"
                        }
                    }
                    DispatchQueue.main.async {
                        Nuke.loadImage(with: railsUrl, into: cell.searchThumbnail)
                        cell.searchDescription.text = description
                        cell.searchUsername.text = username
                        cell.searchDate.text = publishDate
                    }
                } catch {
                    return
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
            return cell
        }
    }
    
    // MARK: Outlets
    @IBOutlet weak var videoTableView: UITableView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBarTextField: UISearchBar!
    
    // MARK: Variables
    private var videos = [Video]()
    private var users = [User]()
    var searchString = String()
    var isItUserSearch = Bool()

    // MARK: Search Bar Did End Editing
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    
    // MARK: Cancel Button Tapped
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    
    // MARK: Search Button Tapped
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        userOrVideoSearch()
    }
    
    
    // MARK: Pass info through segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is OtherChannelViewController
        {
            if let vc = segue.destination as? OtherChannelViewController {
                if segue.identifier == "showSearchChannel" {
                    if let indexPath = tableView.indexPathForSelectedRow{
                        let selectedRow = indexPath.row
                        guard let cell = self.tableView.cellForRow(at: indexPath) as? SearchCell else { return }
                        vc.avatarUrl = cell.avatarUrl
                        vc.segueUsername = users[selectedRow].username
                        vc.segueBio = cell.searchBio.text
                        vc.segueFollowerCount = cell.searchFollowerCount.text
                        vc.segueName = cell.searchName.text
                        vc.chanelVar = users[selectedRow].username
                    }
                }
            }
        } else if let vc = segue.destination as? ChannelVideoViewController {
            if segue.identifier == "showSearchVideo" {
                if let indexPath = videoTableView.indexPathForSelectedRow {
                    let selectedRow = indexPath.row
                    vc.videoString = videos[selectedRow].id
                    vc.rowNumber = indexPath.item
                    vc.isItFromSearch = true
                }
            }
        }
    }
    
    
    // MARK: See if the search is for videos or users
    func userOrVideoSearch() {
        if searchBarTextField.text?.prefix(1) == "@" {
            if let range = searchBarTextField.text?.range(of: "@") {
                let searchh = searchBarTextField.text?[range.upperBound...]
                let search = String("\(searchh)")
                searchString = search
                isItUserSearch = true
                DispatchQueue.main.async {
                    self.videoTableView.isHidden = true
                    self.tableView.isHidden = false
                }
                self.search()
                // Display only user channels and only query for channels
            }
        } else {
            let search = searchBarTextField.text
            let replaceHashtags = search?.replacingOccurrences(of: "#", with: "%23", options: .regularExpression)
            searchString = replaceHashtags ?? ""
            isItUserSearch = false
            DispatchQueue.main.async {
                self.tableView.isHidden = true
                self.videoTableView.isHidden = false
            }
            self.search()
        }
    }
    
    
    // MARK: Submit the user's search query + loads the results
    func search() {
        // Contact api to search the query
        let search = searchBarTextField.text
        guard let replaceHashtags = search?.replacingOccurrences(of: "#", with: "%23", options: .regularExpression) else { return }
        let params = [
            "search": replaceHashtags
        ]
        AF.request("https://www.bartenderdogseatmuffins.xyz/api/v1/search/", method: .get, parameters: params).responseJSON { response in
            guard let data = response.data else {
                print("error code: asdfasf9j")
                return
            }
            do {
                let decoder = JSONDecoder()
                let downloadedResults = try decoder.decode(Users.self, from: data)
                self.videos = downloadedResults.videosearchresults
                self.users = downloadedResults.searchresults
                if self.isItUserSearch == false {
                    DispatchQueue.main.async {
                        self.videoTableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                }
            } catch {
                return
            }
        }
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // put recommended search heree (maybe?)
    }
    
    
    func textFieldShouldReturn(_ textField: UISearchBar) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: User Info From JSON
    class Users: Codable {
        let searchresults: [User]
        let videosearchresults: [Video]
        init(searchresults: [User], videosearchresults: [Video]) {
            self.searchresults = searchresults
            self.videosearchresults = videosearchresults
        }
    }
    
    class User: Codable {
        let username: String
        init(username: String) {
            self.username = username
        }
    }
    
    
    // MARK: Video Info From JSON
    class Video: Codable {
        let id: Int
        init(id: Int) {
            self.id = id
        }
    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Search"
        searchBarTextField?.delegate? = self
        tableView.refreshControl = refreshControl
        videoTableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshSearch(_:)), for: .valueChanged)
        refreshControl.addTarget(self, action: #selector(refreshVideoSearch(_:)), for: .valueChanged)
        if traitCollection.userInterfaceStyle == .light || traitCollection.userInterfaceStyle == .unspecified {
            self.view.backgroundColor = UIColor(hexString: "#eaeaea")
            self.tableView.backgroundColor = UIColor(hexString: "#eaeaea")
            self.videoTableView.backgroundColor = UIColor(hexString: "#eaeaea")
        } else {
            self.view.backgroundColor = UIColor(hexString: "#2d2d2d")
            self.tableView.backgroundColor = UIColor(hexString: "#141414")
            self.videoTableView.backgroundColor = UIColor(hexString: "#141414")
        }
    }
    
    
    // MARK: Refresh Video Search Results
    @objc private func refreshVideoSearch(_ sender: Any) {
        search()
    }
    
    
    // MARK: Refresh User Search Results
    @objc private func refreshSearch(_ sender: Any) {
        search()
    }

}
