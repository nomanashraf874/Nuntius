//
//  LogCell.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/23/22.
//

import UIKit

class LogCell: UITableViewCell {

    @IBOutlet var dateLabe: UILabel!
    @IBOutlet var lastMessage: UILabel!
    @IBOutlet var logImage: UIImageView!
    @IBOutlet var logLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        logImage.layer.cornerRadius = logImage.frame.size.width/2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
