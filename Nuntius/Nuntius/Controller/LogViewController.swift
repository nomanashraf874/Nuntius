//
//  LogViewController.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/15/22.
//

import UIKit
let notificationKey = "nuntius.addchat"
class LogViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var emptyChat: UILabel!
    var chatLog: [[String: Any]]=[]
    let email = (UserDefaults.standard.value(forKey: "email") as? String)!
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate=self
        tableView.dataSource=self
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: notificationKey), object: nil, queue: .main) { _ in
            self.fetchChats()
        }
        self.tableView.register(UINib(nibName: "LogCell", bundle: nil), forCellReuseIdentifier: "LogCell")
        DatabaseManager.base.getName(email: email)
        fetchChats()
    }
    func fetchChats(){
        DatabaseManager.base.getChats(email: email) { chats in
            self.chatLog=chats
            self.tableView.reloadData()
        }
        tableView.isHidden=false
    }
    @IBAction func addChat(_ sender: Any) {
        let alertController = UIAlertController(title: "Chat Type", message: "Choose chat type", preferredStyle: .actionSheet)

        let oneOnOneAction = UIAlertAction(title: "One-on-One Chat", style: .default) { _ in
            self.performSegue(withIdentifier: "searchChat", sender: self)
        }

        let groupChatAction = UIAlertAction(title: "Group Chat", style: .default) { _ in            self.showGroupChatOptions()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(oneOnOneAction)
        alertController.addAction(groupChatAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
    func showGroupChatOptions() {
        let groupChatOptionsController = UIAlertController(title: "Group Chat Options", message: "Choose an option", preferredStyle: .actionSheet)
        
        let joinGroupAction = UIAlertAction(title: "Join Group Chat", style: .default) { _ in
            self.askForChatCode()
        }
        
        let createGroupAction = UIAlertAction(title: "Create Group Chat", style: .default) { _ in
            self.askForChatName()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        groupChatOptionsController.addAction(joinGroupAction)
        groupChatOptionsController.addAction(createGroupAction)
        groupChatOptionsController.addAction(cancelAction)
        
        self.present(groupChatOptionsController, animated: true, completion: nil)
    }

    func askForChatName() {
        let alertController = UIAlertController(title: "Create Group Chat", message: "Enter chat name", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Chat Name"
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [self] _ in
            if let chatName = alertController.textFields?.first?.text {
                DatabaseManager.base.addChat([self.email], chatName)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(createAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

    func askForChatCode() {
        let alertController = UIAlertController(title: "Join Group Chat", message: "Enter chat code", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Chat Code"
        }
        
        let joinAction = UIAlertAction(title: "Join", style: .default) { _ in
            if let chatCode = alertController.textFields?.first?.text {
                DatabaseManager.base.joinGroupChat(self.email,chatCode)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(joinAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}
extension LogViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return chatLog.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogCell", for: indexPath) as! LogCell
        cell.configure(chatLog[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // begin delete
            let id = chatLog[indexPath.row]["id"] as! String
            let name = chatLog[indexPath.row]["name"] as! String
            if let email=chatLog[indexPath.row]["other_user_email"] as? String{
                DatabaseManager.base.deleteChat(id: id,otherEmail: email,name: name)
            }
            else{
                DatabaseManager.base.deleteChat(id: id,otherEmail: nil,name: name)
            }
            tableView.beginUpdates()
            self.chatLog.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            DatabaseManager.base.deleteChat(id: id,otherEmail: email,name: name)
            tableView.endUpdates()
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedCell = tableView.cellForRow(at: indexPath) {
                self.performSegue(withIdentifier: "showChat", sender: selectedCell)
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let cell = sender as? LogCell else{
            return
        }
        let url = cell.imageUrl
        UserDefaults.standard.set(url, forKey: "profilePicture")
        let indexPath = tableView.indexPath(for:cell)!
        let otherEmail = chatLog[indexPath.row]["other_user_email"] as? String
        let id = chatLog[indexPath.row]["id"] as? String
        let name = chatLog[indexPath.row]["name"] as? String
        let chatViewController = segue.destination as! ChatViewController
        if let otherEmail = chatLog[indexPath.row]["other_user_email"] as? String{
            chatViewController.otherUserEmail=otherEmail
        }
        chatViewController.id=id!
        chatViewController.name=name!
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
}
