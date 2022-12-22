//
//  DatabaseManager.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/18/22.
//
//user
  //[User]
//chat
  //messages
//email
   //username
   //coversations
        //
           //
   //
/* TESTERS
 //let testSender = Sender(profileImageURL: "", senderId: "testa@gmail.com", displayName: "Test A")
 let message = Message(sender: testSender, messageId: "3", sentDate: Date(), kind: .text("really testin up in here"))
 //DatabaseManager.base.addChat(otherUserEmail: "testa@gmail.com", name: "testb", email: "testb@gmail.com")
 //DatabaseManager.base.addMessage(otherUserEmail: "testb@gmail.com", email: "testa@gmail.com", content: message, name: "testa")
 /*DatabaseManager.base.getChats(email: "testb@gmail.com") { result in
     switch result{
     case .success(let chats):
         print(chats.count)
     case .failure(_):
         print("ERROR 102")
     }
 }*/
 DatabaseManager.base.getMessages(otherUserEmail: "testa@gmail.com", email: "testb@gmail.com") { result in
     switch result{
     case .success(let chats):
         print(chats.count)
     case .failure(_):
         print("ERROR 103")
     }
 }
 */
        
import Foundation
import FirebaseFirestore
import MessageKit

class DatabaseManager {
    static let base = DatabaseManager()
    private let db = Firestore.firestore()
    /// inserts user to database
    public func userToData(with user: User, completionHandler: @escaping (Bool) -> Void)
    {
        let chats: [[String: Any]]=[]
        db.collection(user.email).document("Username").setData([
            "Username": user.username
        ])
        db.collection(user.email).document("Chats").setData([
            "Chats": chats
        ])
        db.collection("Users").addDocument(data: [
            "Username": user.username,
            "Email": user.email
        ])
        completionHandler(true)
    }
    public func getUsers(completionHandler: @escaping(Result<[User], Error>)->Void){
        var ret = [User]()
        db.collection("Users").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    ret.append(User(username: document.data()["Username"] as! String, email: document.data()["Email"] as! String))
                }
                completionHandler(.success(ret))
            }
        }
    }
    public func addChat(otherUserEmail: String, otherName: String,email: String){
        var name = "ERROR"
        name = UserDefaults.standard.value(forKey: "name") as! String
        let chatId = getChatID(with: otherUserEmail, email: email)
        let docRef = db.collection(email).document("Chats")
        let otherChatData: [String: Any] = [
            "id": chatId,
            "other_user_email": otherUserEmail,
            "name": otherName
            
        ]
        let newChatData: [String: Any] = [
            "id": chatId,
            "other_user_email": email,
            "name": name
        ]
        let otherDocRef = db.collection(otherUserEmail).document("Chats")
        docRef.updateData([
            "Chats": FieldValue.arrayUnion([otherChatData])
        ])
        otherDocRef.updateData([
            "Chats": FieldValue.arrayUnion([newChatData])
        ])
        let messages: [[String:Any]]=[]
        db.collection("Chats").document(chatId).setData([
            "messages":messages
        ])
        
    }
    func getName(email:String){
        let docRef = db.collection(email).document("Username")
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
        let docRef = db.collection(email).document("Chats")
        docRef.updateData([
            "Chats": FieldValue.arrayRemove([ChatData])
        ])
        db.collection("Chats").document(id).delete()
    }
    public func addMessage(chatID: String, email: String,content:Message,name: String){
        //let message = Message(sender: testSender, messageId: "3", sentDate: Date(), kind: .text("really testin up in here"))
        let docRef = db.collection("Chats").document(chatID)
        var message = ""
        switch content.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
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
            "Content":message,
            "Name":name,
            "SenderEmail":email
        ]
        docRef.updateData([
            "messages":FieldValue.arrayUnion([newMessageData])
        ])
    }
    public func getChats(email: String,completionHandler: @escaping(Result<[[String: Any]], Error>)->Void){
        let docRef = db.collection(email).document("Chats")
        var chats: [[String: Any]]=[]
        docRef.addSnapshotListener { (document, error) in
            if let document = document, document.exists {
                chats=document.data()!["Chats"] as! [[String : Any]]
                completionHandler(.success(chats))
            } else {
                print("Error Getting Chats")
            }
        }

    }
    public func getMessages(chatID: String, completionHandler: @escaping(Result<[Message], Error>)->Void){
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
                          let date = controller.formatter.date(from: dateString)
                          else {
                              print("ERR2")
                              return
                          }
                    var kind: MessageKind?
                    kind = .text(content)
                    
                    guard let finalKind = kind else {
                        return
                    }
                    
                    let sender = Sender(profileImageURL: "",
                                        senderId: senderEmail,
                                        displayName: name)
                    
                    messageFinal.append(Message(sender: sender,
                                   messageId: "",
                                   sentDate: date,
                                   kind: finalKind))
                }
                completionHandler(.success(messageFinal))
            } else {
                print("Error Getting Chats")
            }
        }
    }
    
    public func getChatID(with otherUserEmail:String, email: String)->String{
        var result = ""
        if(otherUserEmail>email){
            result = otherUserEmail + email
        }else{
            result = email + otherUserEmail
        }
        return result
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
    case failedToStore
    case failedToGetURL
    case failedToGetURL2
    case noLastMessage
}
