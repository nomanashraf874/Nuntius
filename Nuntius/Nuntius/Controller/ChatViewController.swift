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
import SDWebImage

class ChatViewController: MessagesViewController{
    private var messages = [Message]()
    var id = ""
    var name = ""
    var otherUserEmail: String? = nil
    var chatName = ""
    let email = (UserDefaults.standard.value(forKey: "email") as? String)!
    let url = UserDefaults.standard.value(forKey: "profilePicture") as? URL
    let selfSender = Sender(profileImageURL: "", senderId: (UserDefaults.standard.value(forKey: "email") as? String)!, displayName: "Me")
    let db = DatabaseManager()
    public let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
      }()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationItem.title=name
        let chatCode = UIBarButtonItem(title: "Code", style: .plain, target: self, action: #selector(getCode))
        navigationItem.rightBarButtonItems = [chatCode]
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
        let inputButton = InputBarButtonItem()
        inputButton.setSize(CGSize(width: 40, height: 40), animated: false)
        inputButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        inputButton.onTouchUpInside { _ in
            self.photoActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([inputButton], forStack: .left, animated: false)
    }
    
    @objc func getCode() {
        let alertController = UIAlertController(title: "chatCode", message: "\(id)", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func fetchMessages(){
        db.getMessages(chatID: id) { messageList in
            self.messages=messageList
            DispatchQueue.main.async {
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToLastItem(animated: false)
            }
        }
    }
    
}
extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate, MessageCellDelegate {
    var currentSender: MessageKit.SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            DispatchQueue.main.async {
                imageView.sd_setImage(with: imageUrl)
            }
        default:
            break
        }
    }
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let imageFile = message.sender.senderId+"_profilePicture.png"
        let path = "profileImages/"+imageFile
        StorageMangager.base.getURL(for: path) { otherUrl in
            DispatchQueue.main.async {
                avatarView.sd_setImage(with: otherUrl)
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
            var editedDate = MessageKitDateFormatter.shared.string(from: message.sentDate)
            //fix
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
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func photoActionSheet(){
        let option = UIAlertController(title: "Add Photo",
                                            message: "From where?",
                                            preferredStyle: .actionSheet)
        option.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true)
            
        }))
        option.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .photoLibrary
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true)
            
        }))
        option.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(option, animated: true)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let messageId = email+"_"+formatter.string(from: Date())
        if let image = info[.editedImage] as? UIImage, let imageData =  image.pngData() {
            let fileName = "photoMessage" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            StorageMangager.base.storeImage(with: imageData, fileName: fileName, completionHandler: { urlString in
                print("Uploaded Message Photo: \(urlString)")
                
                let url = URL(string: urlString)
                let media = ImageMediaItem(url: url,
                                           image: nil,
                                           placeholderImage: UIImage(systemName: "photo.artframe")!,
                                           size: .zero)
                
                let message = Message(sender: self.selfSender,
                                      messageId: messageId,
                                      sentDate: Date(),
                                      kind: .photo(media))
                var id = ""
                if let otherUserEmail = self.otherUserEmail{
                    id = DatabaseManager.base.getChatID([otherUserEmail, self.email])
                }
                else{
                    id = DatabaseManager.base.getChatID([self.email])
                }
                DatabaseManager.base.addMessage(chatID: id, email: self.email, content: message, name: self.name)
            })
        }
    }
}
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty
        else {
            return
        }
        let selfSender = self.selfSender
        
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

