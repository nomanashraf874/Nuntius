//
//  Message.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/24/22.
//

import Foundation
import MessageKit

struct Message: MessageType{
    var sender: SenderType
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKind
}
struct ImageMediaItem: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}
