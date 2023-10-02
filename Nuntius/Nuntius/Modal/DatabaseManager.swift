//
//  DatabaseManager.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/18/22.
        
import Foundation
import FirebaseFirestore
import MessageKit
import CryptoKit

class DatabaseManager {
    static let base = DatabaseManager()
    private let db = Firestore.firestore()
    public func userToData(with user: User, completionHandler: @escaping (Bool) -> Void) {
        let chats: [[String: Any]] = []
        let emailDocumentRef = db.collection("Emails").document(user.email)
        emailDocumentRef.setData([
            "Username": user.username,
            "Chats": chats
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
                completionHandler(false)
            } else {
                print("Document added successfully")
                completionHandler(true)
            }
        }
        db.collection("Users").addDocument(data: [
            "Username": user.username,
            "Email": user.email
        ])
    }

    public func getUsers(completionHandler: @escaping([User])->Void){
        var ret = [User]()
        db.collection("Users").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    ret.append(User(username: document.data()["Username"] as! String, email: document.data()["Email"] as! String))
                }
                completionHandler(ret)
            }
        }
    }
    
    public func addChat(_ memberEmails: [String],_ chatName: String) {
        var name = UserDefaults.standard.value(forKey: "name") as! String
        let chatId = getChatID(memberEmails)
        let docRef = db.collection("Emails").document(memberEmails[0])
        if memberEmails.count==1{
            let docRef = db.collection("Emails").document(memberEmails[0])
            let newChatData: [String: Any] = [
                "id": chatId,
                "name": chatName
            ]
            docRef.updateData([
                "Chats": FieldValue.arrayUnion([newChatData])
            ])
        }
        else{
            let otherDocRef = db.collection("Emails").document(memberEmails[1])
            let otherChatData: [String: Any] = [
                "id": chatId,
                "other_user_email": memberEmails[1],
                "name": chatName
            ]
            let newChatData: [String: Any] = [
                "id": chatId,
                "other_user_email": memberEmails[0],
                "name": name
            ]
            docRef.updateData([
                "Chats": FieldValue.arrayUnion([otherChatData])
            ])
            otherDocRef.updateData([
                "Chats": FieldValue.arrayUnion([newChatData])
            ])
        }
        let data: [String: Any] = [
            "chatName":chatName,
            "messages": [[String: Any]]()
        ]
        let chatRef = db.collection("Chats").document(chatId)
        chatRef.getDocument { (document, error) in
            if let document = document, document.exists {
                print("Document already exists, not updated.")
            } else {
                chatRef.setData(data)
            }
        }
    }
    
    public func joinGroupChat(_ email: String,_ id:String){
        let docRef = db.collection("Emails").document(email)
        getChatName(chatId: id) { name in
            let newChatData: [String: Any] = [
                "id": id,
                "name": name
            ]
            docRef.updateData([
                "Chats": FieldValue.arrayUnion([newChatData])
            ])
        }
    }
    
    func getName(email:String){
        let docRef = db.collection("Emails").document(email)
        var ret = ""
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                ret=document.data()?["Username"] as! String
                UserDefaults.standard.set(ret,forKey: "name")
            } else {
                print("Username Not Set")
            }
        }
    }
    
    func getChatName(chatId:String,completionHandler:@escaping(String)->Void){
        let docRef = db.collection("Chats").document(chatId)
        var ret = ""
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                ret=document.data()?["chatName"] as! String
                completionHandler(ret)
            } else {
                print("Chat Name Not Set")
            }
        }
    }
    
    public func deleteChat(id: String, otherEmail: String?, name: String){
        let email = UserDefaults.standard.value(forKey: "email")as! String
        var ChatData = [String: Any]()
        if let otherEmail = otherEmail {
            ChatData = [
                "id": id,
                "other_user_email": otherEmail,
                "name": name
            ]
            db.collection("Chats").document(id).delete()
        }
        else{
            ChatData = [
                "id": id,
                "name": name
            ]
        }
        let docRef = db.collection("Emails").document(email)
        docRef.updateData([
            "Chats": FieldValue.arrayRemove([ChatData])
        ])
    }
    
    public func addMessage(chatID: String, email: String,content:Message,name: String){
        var kind = ""
        let docRef = db.collection("Chats").document(chatID)
        var message = ""
        switch content.kind {
        case .text(let messageText):
            kind = "text"
            message = messageText
        case .attributedText(_):
            break
        case .photo(let photoUrl):
            kind = "photo"
            if let photoUrlString = photoUrl.url?.absoluteString {
                message = photoUrlString
            }
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        let controller = ChatViewController()
        let messageDate = controller.formatter.string(from: content.sentDate)
        let newMessageData: [String: Any] = [
            "Date":messageDate,
            "kind": kind,
            "Content":message,
            "Name":name,
            "SenderEmail":email
        ]
        docRef.updateData([
            "messages":FieldValue.arrayUnion([newMessageData])
        ])
    }

    public func getChats(email: String, completionHandler: @escaping ([[String: Any]]) -> Void) {
        let docRef = db.collection("Emails").document(email)
        
        docRef.addSnapshotListener { document, error in
            if let document = document, document.exists {
                if let chatData = document.data()?["Chats"] as? [[String: Any]] {
                    completionHandler(chatData)
                } else {
                    print("Chats data not found")
                }
            } else {
                print("Error getting user document: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    public func getChatID(_ memberEmails: [String]) -> String {
        if memberEmails.count == 1 {
            let email = memberEmails[0]
            let timestamp = String(Date().timeIntervalSince1970)
            let uniqueCode = generateUniqueCode(email, timestamp)
            return uniqueCode
        } else {
            let sortedEmails = memberEmails.sorted()
            return sortedEmails.joined(separator: "_")
        }
    }
    
    private func generateUniqueCode(_ email: String, _ timestamp: String) -> String {
        let combinedString = "\(email)_\(timestamp)"
        if let inputData = combinedString.data(using: .utf8) {
                let hashedData = SHA256.hash(data: inputData)
                let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
                let truncatedHash = String(hashString.prefix(6))
                return truncatedHash
            } else {
                return ""
            }
    }

    
    public func getMessages(chatID: String, completionHandler: @escaping([Message])->Void){
        let docRef = db.collection("Chats").document(chatID)
        docRef.addSnapshotListener { (document, error) in
            if let document = document, document.exists {
                let messages=document.data()!["messages"] as! [[String : Any]]
                let controller = ChatViewController()
                var messageFinal: [Message] = []
                for message in messages{
                    guard let name = message["Name"] as? String,
                          let content = message["Content"] as? String,
                          let senderEmail = message["SenderEmail"] as? String,
                          let dateString = message["Date"] as? String,
                          let item = message["kind"] as? String,
                          let date = controller.formatter.date(from: dateString)
                    else {
                        print("ERR2")
                        return
                    }
                    var kind: MessageKind?
                    if item == "photo" {
                        guard let imageUrl = URL(string: content),
                              let placeHolder = UIImage(systemName: "plus") else {
                                  return
                              }
                        let media = ImageMediaItem(url: imageUrl,
                                          image: nil,
                                          placeholderImage: placeHolder,
                                          size: CGSize(width: 300, height: 300))
                        kind = .photo(media)
                    }
                    else{
                        kind = .text(content)
                    }
                    
                    let sender = Sender(profileImageURL: "",
                                        senderId: senderEmail,
                                        displayName: name)
                    
                    messageFinal.append(Message(sender: sender,
                                                messageId: "",
                                                sentDate: date,
                                                kind: kind!))
                }
                completionHandler(messageFinal)
            } else {
                print("Error Getting Chats")
            }
        }
    }
    
    func getLastMessage(id: String, completionHandler: @escaping(Result<[String : Any], Error>)->Void){
        let docRef = db.collection("Chats").document(id)
        docRef.getDocument{ (document, error) in
            if let document = document, document.exists {
                if let messages = document.data()?["messages"] as? [[String: Any]], !messages.isEmpty {
                    let lastMessage = messages.last!
                    completionHandler(.success(lastMessage))
                }
                else{
                    completionHandler(.failure(CustomError.noLastMessage))
                }
            }else{
                completionHandler(.failure(CustomError.noLastMessage))
            }
        }
    }
    
    
}
enum CustomError: Error {
    case noLastMessage
}
