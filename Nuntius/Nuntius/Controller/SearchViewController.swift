//
//  SearchViewController.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/15/22.
//

import UIKit

class SearchViewController: UIViewController {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var emptyLabel: UILabel!

    var allUsers = [User]()
    var results = [User]()
    let email = UserDefaults.standard.value(forKey: "email") as! String
    var searchDone = false
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.titleView=searchBar
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        tableView.delegate=self
        tableView.dataSource=self
        
    }

}
extension SearchViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    //create cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell",for: indexPath) as! SearchCell
        cell.searchLabel.text=results[indexPath.row].username
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetUser = results[indexPath.row]
        DatabaseManager.base.addChat([email,targetUser.email], targetUser.username)
        NotificationCenter.default.post(name: Notification.Name(rawValue: notificationKey), object: self)
        self.navigationController?.popViewController(animated: true)
        
    }
}
extension SearchViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard var text = searchBar.text,!text.isEmpty else{
            return
        }
        text = text.lowercased()
        searchBar.resignFirstResponder()
        results.removeAll()
        self.findUsers(text: text)
    }
    func findUsers(text:String){
        if searchDone{
            searchUsers(with: text)
        }
        else{
            DatabaseManager.base.getUsers(completionHandler: {users in
                self.searchDone=true
                self.allUsers=users.filter { $0.email != self.email }
                self.searchUsers(with: text)
                    
            })
        }
    }
    func searchUsers(with text: String){
        let result = allUsers.filter { user in
            let name = user.username.lowercased()
            return name.hasPrefix(text)
        }
        self.results=result
        if results.isEmpty {
            self.emptyLabel.isHidden = false
            self.tableView.isHidden = true
        }
        else {
            self.emptyLabel.isHidden = true
            self.tableView.isHidden = false
            tableView.reloadData()
        }
    }
}
