//
//  ProfileViewController.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/15/22.
//

import UIKit
import FirebaseAuth
import SDWebImage
class ProfileViewController: UIViewController {
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var BG: UIView!
    @IBOutlet var emailLabel: UILabel!
    let email = (UserDefaults.standard.value(forKey: "email") as? String)!
    override func viewDidLoad() {
        super.viewDidLoad()
        let name = (UserDefaults.standard.value(forKey: "name") as? String)!
        // Do any additional setup after loading the view.
        nameLabel.text=name
        emailLabel.text=email
        profilePictureHeader()
        BG.layer.cornerRadius = BG.frame.size.width/5
        profileImage.layer.cornerRadius = profileImage.frame.size.width/2
        
    }
    func profilePictureHeader() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            print("ERORR in profilePictureHeader")
            return
        }
        let imageFile = email+"_profilePicture.png"
        let path = "profileImages/"+imageFile
        profileImage.layer.borderColor=UIColor.myCustomColor.cgColor
        profileImage.layer.borderWidth = 3
        profileImage.layer.masksToBounds = true
        StorageMangager.base.getURL(for: path) { url in
            self.profileImage.sd_setImage(with: url)
        }
    }
    @IBAction func logoutPressed(_ sender: Any) {
        let alert = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
            do{
                try FirebaseAuth.Auth.auth().signOut()
                self.performSegue(withIdentifier: "logout", sender: self)
            }catch{
                print("Failed to log out")
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert,animated: true)
    }
    
}
extension UIColor {

    static let myCustomColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)

}
