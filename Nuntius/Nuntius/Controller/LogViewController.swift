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
    //find email
    let email = (UserDefaults.standard.value(forKey: "email") as? String)!
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    override func viewDidLoad() {

        super.viewDidLoad()
        DatabaseManager.base.getName(email: email)
        tableView.delegate=self
        tableView.dataSource=self
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: notificationKey), object: nil, queue: .main) { _ in
            self.fetchChats()
        }
        
        fetchChats()

        // Do any additional setup after loading the view.
    }
    func fetchChats(){
        DatabaseManager.base.getChats(email: email) { chats in
            self.chatLog=chats
            self.tableView.reloadData()
        }
        tableView.isHidden=false
    }
    
}
extension LogViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return chatLog.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogCell", for: indexPath) as! LogCell
        cell.logLabel.text = chatLog[indexPath.row]["name"] as? String
        print(chatLog[indexPath.row]["name"] as? String)
        let email=(chatLog[indexPath.row]["other_user_email"] as? String)!
        let imageFile = email+"_profilePicture.png"
        let id = chatLog[indexPath.row]["id"] as? String
        let path = "profileImages/"+imageFile
        DatabaseManager.base.getLastMessage(id: id!) { result in
            switch result{
            case .success(let lastMessage):
                let controller = ChatViewController()
                let lastm = lastMessage["Content"] as! String
                if(lastm.prefix(5)=="https"){
                    cell.lastMessage.text="Image"
                }else{
                    cell.lastMessage.text=lastMessage["Content"] as! String
                }
                let date = lastMessage["Date"] as! String
                let tdate = controller.formatter.string(from: Date())
                var d = date.prefix(8) // Hello
                let td = tdate.prefix(8)
                if(d==td){
                    d=date.suffix(7)
                }
                cell.dateLabe.text = String(d)
            case .failure(_):
                cell.lastMessage.text=nil
                cell.dateLabe.text = nil
                
            }
        }
        cell.logImage.layer.masksToBounds = true
        StorageMangager.base.getURL(for: path) { url in
            cell.logImage.sd_setImage(with: url)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // begin delete
            let id = chatLog[indexPath.row]["id"] as! String
            let name = chatLog[indexPath.row]["name"] as! String
            let email=chatLog[indexPath.row]["other_user_email"] as! String
            tableView.beginUpdates()
            self.chatLog.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            
            DatabaseManager.base.deleteChat(id: id,otherEmail: email,name: name)
            
            tableView.endUpdates()
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let cell = sender as? LogCell else{
            return
        }
        let url = cell.logImage.sd_imageURL
        UserDefaults.standard.set(url, forKey: "profilePicture")
        let indexPath = tableView.indexPath(for:cell)!
        //other_user_email
        let otherEmail = chatLog[indexPath.row]["other_user_email"] as? String
        let id = chatLog[indexPath.row]["id"] as? String
        let name = chatLog[indexPath.row]["name"] as? String
        let chatViewController = segue.destination as! ChatViewController
        chatViewController.otherUserEmail=otherEmail!
        chatViewController.id=id!
        chatViewController.name=name!
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
}
