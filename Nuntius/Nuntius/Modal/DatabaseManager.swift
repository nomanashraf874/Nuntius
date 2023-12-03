//
//  DatabaseManager.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/18/22.
        
import Foundation
import FirebaseFirestore
import MessageKit
import CoreData
import CryptoKit
import Network

class DatabaseManager {
    
    static let base = DatabaseManager()
    private let db = Firestore.firestore()
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "NetworkMonitor")
    var persistentContainer: NSPersistentCloudKitContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
      }()
    func userToData(with user: User, completionHandler: @escaping (Bool) -> Void) {
        let chats: [[String: Any]] = []
        let context = self.persistentContainer.viewContext
        let userData = UserData(context: context)
        userData.name = user.username
        userData.email = user.email

        do {
            try context.save()
        } catch {
            print("Error saving user data to Core Data: \(error.localizedDescription)")
            completionHandler(false)
            return
        }
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

    func getUsers(completionHandler: @escaping([User])->Void){
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
    
    func addChat(_ memberEmails: [String],_ chatName: String) async{
        let context = persistentContainer.viewContext
        let newChat = ChatData(context: context)
        let chatId = getChatID(memberEmails)
        let name = await getName(email: memberEmails[0])
        newChat.chatID=chatId
        newChat.chatName=chatName
        let docRef = db.collection("Emails").document(memberEmails[0])
        let fetchRequest: NSFetchRequest<UserData> = UserData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email == %@", memberEmails[0])
        do {
            let user = try context.fetch(fetchRequest)
            if memberEmails.count==1{
                let docRef = db.collection("Emails").document(memberEmails[0])
                let newChatData: [String: Any] = [
                    "id": chatId,
                    "name": chatName
                ]
                try await docRef.updateData([
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
                try await docRef.updateData([
                    "Chats": FieldValue.arrayUnion([otherChatData])
                ])
                try await otherDocRef.updateData([
                    "Chats": FieldValue.arrayUnion([newChatData])
                ])
                newChat.otherUserEmail=memberEmails[1]
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
            newChat.user=user.first
            try context.save()
        } catch {
            print("Error saving chat: \(error.localizedDescription)")
        }
    }
    
    func joinGroupChat(_ email: String,_ id:String){
        let fetchRequest: NSFetchRequest<UserData> = UserData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        let docRef = db.collection("Emails").document(email)
        let context = persistentContainer.viewContext
        let newChat = ChatData(context: context)
        getChatName(chatId: id) { name in
            let newChatData: [String: Any] = [
                "id": id,
                "name": name
            ]
            docRef.updateData([
                "Chats": FieldValue.arrayUnion([newChatData])
            ])
            newChat.chatID=id
            newChat.chatName=name
            do {
                let user = try context.fetch(fetchRequest)
                newChat.user = user.first
                try context.save()
            } catch {
                print("Error saving chat: \(error.localizedDescription)")
            }
        }
    }
    
    func getName(email:String, completion: @escaping (String) -> Void){
        monitor.start(queue: queue)
        let currentPath = monitor.currentPath
        if currentPath.status == .satisfied {
            let docRef = self.db.collection("Emails").document(email)
            var ret = ""
            docRef.getDocument { document, error in
                if let document = document, document.exists {
                    ret=document.data()?["Username"] as! String
                    completion(ret)
                } else {
                    print("Username Not Set")
                }
            }
        } else{
            let request: NSFetchRequest<UserData> = UserData.fetchRequest()
            request.predicate = NSPredicate(format: "email == %@", email)
            let context = self.persistentContainer.viewContext
            do {
                let users = try context.fetch(request)
                if let user = users.first {
                    completion(user.name ?? "No name")
                } else {
                    print("No user found")
                }
            } catch {
                print("Error fetching user: \(error.localizedDescription)")
            }
        }
    }
    
    func getName(email: String) async -> String{
        await withCheckedContinuation { continuation in
            getName(email: email) { name in
                continuation.resume(returning: name)
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
    
    func deleteChat(id: String, otherEmail: String?, name: String){
        let email = UserDefaults.standard.value(forKey: "email")as! String
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<ChatData> = ChatData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chatID == %@", id)
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
        do {
            let chats = try context.fetch(fetchRequest)
            if let chatToDelete = chats.first {
                context.delete(chatToDelete)
                try context.save()
            } else {
                print("Chat not found with ID: \(id)")
            }
        } catch {
            print("Error deleting chat: \(error.localizedDescription)")
        }
    }
    
    func addMessage(chatID: String, email: String,content:Message,name: String){
        var kind = ""
        let docRef = db.collection("Chats").document(chatID)
        var message = ""
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<ChatData> = ChatData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chatID == %@", chatID)
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
        default:
            break
        }
        let messageDate = formatter.string(from: content.sentDate)
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
        do {
            let chats = try context.fetch(fetchRequest)
            if let chat = chats.first {
                let newMessage = MessageData(context: context)
                newMessage.time = formatter.string(from: content.sentDate)
                newMessage.textContent=message
                newMessage.chat=chat
                newMessage.senderName=name
                newMessage.senderEmail=email
                chat.lastMessage=newMessage
                try context.save()
            }else {
                print("Chat not found with ID: \(chatID)")
            }
        } catch {
            print("Error adding message: \(error.localizedDescription)")
        }
    }

    func getChats(email: String, completionHandler: @escaping ([[String: Any]]) -> Void) {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                let docRef = self.db.collection("Emails").document(email)
                
                docRef.addSnapshotListener { document, error in
                    if let document = document, document.exists {
                        if let chatData = document.data()?["Chats"] as? [[String: Any]] {
                            Task{
                                await self.syncChatsWithCoreData(chatData,email)
                            }
                            completionHandler(chatData)
                        } else {
                            print("Chats data not found")
                        }
                    } else {
                        print("Error getting user document: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            } else {
                let context = self.persistentContainer.viewContext
                let fetchRequest: NSFetchRequest<UserData> = UserData.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "email == %@", email)
                do {
                    let fetchedChats = try context.fetch(fetchRequest)
                    if let user = fetchedChats.first {
                        if let chats = user.chats{
                            var chatData: [[String: Any]] = []
                            for xchat in chats{
                                if let chat = xchat as? ChatData{
                                    var chatDict: [String: Any] = [:]
                                    chatDict["id"] = chat.chatID
                                    chatDict["name"] = chat.chatName
                                    chatDict["otherUserEmail"] = chat.otherUserEmail
                                    chatData.append(chatDict)
                                } else{
                                    print("ComeonYIMB")
                                }
                            }
                            completionHandler(chatData)
                        }
                    }
                    else{
                        print("User does not exit")
                        completionHandler([])
                    }
                } catch {
                    print("Error fetching chats from CoreData: \(error.localizedDescription)")
                    completionHandler([])
                }
            }
        }
        monitor.start(queue: queue)
    }

    func getChatID(_ memberEmails: [String]) -> String {
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

    
    func getMessages(chatID: String, completionHandler: @escaping([Message])->Void){
        monitor.pathUpdateHandler = { [self] path in
            if path.status == .satisfied {
                let docRef = self.db.collection("Chats").document(chatID)
                docRef.addSnapshotListener { (document, error) in
                    if let document = document, document.exists {
                        let messages=document.data()!["messages"] as! [[String : Any]]
                        var messageFinal: [Message] = []
                        for message in messages{
                            guard let name = message["Name"] as? String,
                                  let content = message["Content"] as? String,
                                  let senderEmail = message["SenderEmail"] as? String,
                                  let dateString = message["Date"] as? String,
                                  let item = message["kind"] as? String,
                                  let date = self.formatter.date(from: dateString)
                            else {
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
                        self.syncMessagesWithCoreData(messages,chatID)
                        completionHandler(messageFinal)
                    } else {
                        print("Error Getting Chats")
                    }
                }
                
            } else {
                let context = self.persistentContainer.viewContext
                let fetchRequest: NSFetchRequest<ChatData> = ChatData.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "chatID == %@", chatID)
                do {
                    let fetchedChats = try context.fetch(fetchRequest)
                    if let chat = fetchedChats.first {
                        if let messages = chat.messages {
                            var res = [Message]()
                            for message in messages{
                                if let mes = message as? MessageData {
                                    let content = mes.textContent ?? "Image Not Loaded"
                                    let sender = Sender(profileImageURL: "",
                                                        senderId: mes.senderEmail!,
                                                        displayName: mes.senderName!)
                                    let curr = Message(sender: sender, messageId: "", sentDate: formatter.date(from: mes.time!)! , kind: .text(content))
                                    res.append(curr)
                                }
                            }
                            completionHandler(res)
                        }
                        else{
                            print("ComeonYIMB")
                        }
                        
                    } else {
                        print("Chat not found for ID: \(chatID)")
                        completionHandler([])
                    }
                } catch {
                    print("Error fetching chat from CoreData: \(error.localizedDescription)")
                    completionHandler([])
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    func getLastMessage(id: String, completionHandler: @escaping(Result<[String : Any], Error>)->Void){
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                let docRef = self.db.collection("Chats").document(id)
                docRef.addSnapshotListener { document, error in
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
            } else {
                let context = self.persistentContainer.viewContext
                let fetchRequest: NSFetchRequest<ChatData> = ChatData.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "chatID == %@", id)
                do {
                    let fetchedChats = try context.fetch(fetchRequest)
                    if let chat = fetchedChats.first {
                        if let mes = chat.lastMessage{
                            let curr: [String:Any] = [
                                "Content":mes.textContent ?? "Image not Loaded",
                                "Date":mes.time!
                            ]
                            completionHandler(.success(curr))
                            
                        }
                        else{
                            completionHandler(.failure(CustomError.noLastMessage))
                        }
                    }
                    else{
                        print("Chat not found for ID: \(id)")
                        completionHandler(.failure(CustomError.noLastMessage))
                    }
                    
                }catch {
                    print("Error fetching chat from CoreData: \(error.localizedDescription)")
                    completionHandler(.failure(CustomError.noLastMessage))
                }
            }
        }
        monitor.start(queue: queue)
    }
    func syncChatsWithCoreData(_ chatsFromFirebase: [[String: Any]],_ email:String)async {
        let context = persistentContainer.viewContext
        let fetchUser: NSFetchRequest<UserData> = UserData.fetchRequest()
        fetchUser.predicate = NSPredicate(format: "email == %@", email)
        var user = UserData(context: context)
        do{
            let userRequest = try context.fetch(fetchUser)
            if let userData = userRequest.first{
                user=userData
            } else{
                user.name = await getName(email: email)
                user.email = email
                try context.save()
                await syncChatsWithCoreData(chatsFromFirebase, email)
                return
            }
            for chatData in chatsFromFirebase {
                let chatID = chatData["id"] as? String ?? ""
                
                let fetchRequest: NSFetchRequest<ChatData> = ChatData.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "chatID == %@", chatID)
                let fetchedChats = try context.fetch(fetchRequest)
                if fetchedChats.isEmpty {
                    let newChat = ChatData(context: context)
                    newChat.chatID = chatID
                    newChat.chatName = chatData["name"] as? String ?? ""
                    if let otherUserEmail = chatData["otherUserEmail"] as? String{
                        newChat.otherUserEmail = otherUserEmail
                    }
                    newChat.user=user
                    try context.save()
                }
            }
        }catch {
            print("Error fetching or updating chat data in CoreData: \(error.localizedDescription)")
        }
    }
    func syncMessagesWithCoreData(_ messagesFromFirebase: [[String: Any]],_ chatID: String) {
        let context = persistentContainer.viewContext
        let fetchChat: NSFetchRequest<ChatData> = ChatData.fetchRequest()
        fetchChat.predicate = NSPredicate(format: "chatID == %@", chatID)
        var chat = ChatData(context: context)
        do{
            let chats = try context.fetch(fetchChat)
            if let chatData=chats.first{
                chat=chatData
            }
        }catch{
            print("Error in fetch request in sync message func: \(error.localizedDescription)")
        }
        for messageData in messagesFromFirebase {
            guard let name = messageData["Name"] as? String,
                  let content = messageData["Content"] as? String,
                  let senderEmail = messageData["SenderEmail"] as? String,
                  let dateString = messageData["Date"] as? String,
                  let item = messageData["kind"] as? String
            else {
                print("error")
                return
            }
            let fetchRequest: NSFetchRequest<MessageData> = MessageData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "senderEmail == %@ AND time == %@", senderEmail,dateString)
            do {
                let fetchedMessages = try context.fetch(fetchRequest)
                
                if fetchedMessages.isEmpty {
                    let newMessage = MessageData(context: context)
                    newMessage.time = dateString
                    newMessage.textContent = item == "photo" ? "Image" : content
                    newMessage.chat=chat
                    newMessage.senderName=name
                    newMessage.senderEmail=senderEmail
                    chat.lastMessage=newMessage
                    try context.save()
                }
            } catch {
                print("Error fetching or updating message data in CoreData: \(error.localizedDescription)")
            }
        }
    }


    
    
}
enum CustomError: Error {
    case noLastMessage
}
