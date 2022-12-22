//
//  ChatViewController.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/23/22.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseFirestore

class ChatViewController: MessagesViewController {
    private var messages = [Message]()
    var id = ""
    var name = ""
    var otherUserEmail = ""
    var otherUserName = ""
    let email = (UserDefaults.standard.value(forKey: "email") as? String)!
    let url = UserDefaults.standard.value(forKey: "profilePicture") as? URL
    let selfSender = Sender(profileImageURL: "", senderId: (UserDefaults.standard.value(forKey: "email") as? String)!, displayName: "Me")
    public let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
      }()
    /*
     let formatter2 = DateFormatter()
     formatter2.timeStyle = .medium
     print(formatter2.string(from: today))
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationItem.title=name
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingAvatarPosition(AvatarPosition(horizontal: .natural, vertical: .messageCenter))
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingAvatarPosition(AvatarPosition(horizontal: .natural, vertical: .messageCenter))
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.setMessageIncomingMessagePadding(UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 50))
        layout?.setMessageOutgoingMessagePadding(UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 4))
        fetchMessages()

        
    }
    func fetchMessages(){
        
        DatabaseManager.base.getMessages(chatID: id) { result in
            switch result{
            case .success(let messageList):
                self.messages=messageList
            default:
                print("ERROR Getting Chats")
            }
            DispatchQueue.main.async {
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToLastItem(animated: false)
            }
        }
    }
    
}
extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate, MessageCellDelegate {
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let sender = message.sender
        
        if sender.senderId == selfSender.senderId {
            let imageFile = email+"_profilePicture.png"
            let path = "images/"+imageFile
            StorageMangager.base.getURL(for: path) { results in
                switch results{
                case .success(let otherUrl):
                    avatarView.sd_setImage(with: otherUrl, completed: nil)
                case .failure(let error):
                    print("profilePictureHeader\(error)")
                }
            }
        }
        else {
            let imageFile = otherUserEmail+"_profilePicture.png"
            let path = "images/"+imageFile
            StorageMangager.base.getURL(for: path) { results in
                switch results{
                case .success(let otherUrl):
                    avatarView.sd_setImage(with: otherUrl, completed: nil)
                case .failure(let error):
                    print("profilePictureHeader\(error)")
                }
            }
        }
        
    }
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 7 == 0 {
            print(message.sentDate)
            var editedDate = MessageKitDateFormatter.shared.string(from: message.sentDate)
            if editedDate[0]=="T"{
                editedDate = String(editedDate.prefix(5))
            }
            else{
                editedDate = String(editedDate.prefix(8))
            }
            return NSAttributedString(
                string: editedDate,
                attributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                    NSAttributedString.Key.foregroundColor: UIColor.darkGray,
                ])
        }
        return nil
    }
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        var editedDate = MessageKitDateFormatter.shared.string(from: message.sentDate)
        if editedDate[0]=="T"{
            editedDate = String(editedDate.suffix(7))
        }
        return NSAttributedString(
            string: editedDate,
            attributes: [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                NSAttributedString.Key.foregroundColor: UIColor.darkGray,
            ])
    }
    
}
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty
        else {
            return
        }
        let selfSender = self.selfSender
        print("Sending: \(text)")
        
        let message = Message(sender: selfSender,
                              messageId: "",
                              sentDate: Date(),
                              kind: .text(text))
        
        
        DatabaseManager.base.addMessage(chatID: id, email: email, content: message, name: name)
        self.messageInputBar.inputTextView.text = nil
        fetchMessages()
    }
    
    
    
}
extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

