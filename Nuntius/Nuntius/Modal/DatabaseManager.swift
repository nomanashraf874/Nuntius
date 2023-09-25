//
//  DatabaseManager.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/18/22.
        
import Foundation
import FirebaseFirestore
import MessageKit

class DatabaseManager {
    static let base = DatabaseManager()
    private let db = Firestore.firestore()
    /// inserts user to database
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
    
    public func addOneOnOneChat(_ memberEmails: [String],_ chatName: String) {
        var name = UserDefaults.standard.value(forKey: "name") as! String
        let chatId = getChatID(memberEmails,chatName)
        let docRef = db.collection("Emails").document(memberEmails[0])
        if memberEmails.count==1{
            let docRef = db.collection("Emails").document(memberEmails[0])
            let newChatData: [String: Any] = [
                "id": chatId,
                "name": name
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
        db.collection("Chats").document(chatId).setData([
            "messages": [[String:Any]]()
        ])
    }
    
    public func joinGroupChat(email: String, id:String){
        let docRef = db.collection("Emails").document(email)
        var  name = id.split(separator: "_")[1]
        let newChatData: [String: Any] = [
            "id": id,
            "name": name
        ]
        docRef.updateData([
            "Chats": FieldValue.arrayUnion([newChatData])
        ])
    }
    
    func getName(email:String){
        let docRef = db.collection("Emails").document(email)
        var ret = ""
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                ret=document.data()?["Username"] as! String
                print(ret)
                UserDefaults.standard.set(ret,forKey: "name")
            } else {
                print("ERROR2")
            }
        }
    }
    
    public func deleteChat(id: String, otherEmail: String, name: String){
        let email = UserDefaults.standard.value(forKey: "email")as! String
        let ChatData: [String: Any] = [
            "id": id,
            "other_user_email": otherEmail,
            "name": name
        ]
        let docRef = db.collection("Emails").document(email)
        docRef.updateData([
            "Chats": FieldValue.arrayRemove([ChatData])
        ])
        db.collection("Chats").document(id).delete()
    }
    
    public func addMessage(chatID: String, email: String,content:Message,name: String){
        //let message = Message(sender: testSender, messageId: "3", sentDate: Date(), kind: .text("really testin up in here"))
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
        // Reference the user's document within the "Emails" collection
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

    public func getChatID(_ memberEmails: [String],_ chatName: String) -> String {
        if memberEmails.count == 1 {
            let email = memberEmails[0]
            let timestamp = Int(Date().timeIntervalSince1970) // Convert timestamp to an integer
            let uniqueCode = UUID(uuidString: "\(email)_\(timestamp)")?.uuidString ?? ""
            return uniqueCode+"_"+chatName
        } else {
            let sortedEmails = memberEmails.sorted()
            return sortedEmails.joined(separator: "_")
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
                        // photo
                        guard let imageUrl = URL(string: content),
                              let placeHolder = UIImage(systemName: "plus") else {
                                  return
                              }
                        print(imageUrl)
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
                let messages=document.data()!["messages"] as! [[String : Any]]
                if messages.count > 0 {
                    let lastMessage = messages[messages.count-1]
                    completionHandler(.success(lastMessage))
                }
                else{
                    completionHandler(.failure(CustomError.noLastMessage))
                }
            }
        }
    }
    
    
}
enum CustomError: Error {
    case noLastMessage
}
