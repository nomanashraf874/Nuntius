//
//  LogCell.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/23/22.
//

import UIKit
import SDWebImage

class LogCell: UITableViewCell {

    @IBOutlet var dateLabe: UILabel!
    @IBOutlet var lastMessage: UILabel!
    @IBOutlet var logImage: UIImageView!
    @IBOutlet var logLabel: UILabel!
    var imageUrl : URL? = nil
    override func awakeFromNib() {
        super.awakeFromNib()
        logImage.layer.cornerRadius = logImage.frame.size.width/2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func configure(_ log: [String: Any]){
        logLabel.text = log["name"] as? String
        let id = log["id"] as? String
        DatabaseManager.base.getLastMessage(id: id!) { result in
            switch result{
            case .success(let lastMessage):
                let controller = ChatViewController()
                let lastm = lastMessage["Content"] as! String
                if(lastm.prefix(5)=="https"){
                    self.lastMessage.text="Image"
                }else{
                    self.lastMessage.text=lastMessage["Content"] as! String
                }
                let date = lastMessage["Date"] as! String
                let tdate = controller.formatter.string(from: Date())
                var d = date.prefix(8)
                let td = tdate.prefix(8)
                if(d==td){
                    d=date.suffix(7)
                }
                self.dateLabe.text = String(d)
            case .failure(_):
                self.lastMessage.text=nil
                self.dateLabe.text = nil
                
            }
            if let email = log["other_user_email"] as? String{
                let path = "profileImages/" + email + "_profilePicture.png"
                StorageMangager.base.getURL(for: path) { url in
                    self.imageUrl=url
                    DispatchQueue.main.async {
                        self.logImage.sd_setImage(with: url)
                    }
                }
            }
            else{
                DispatchQueue.main.async {
                    self.logImage.image=UIImage(named: "gc")!
                }
            }
            self.logImage.layer.masksToBounds = true
        }
    }

}
