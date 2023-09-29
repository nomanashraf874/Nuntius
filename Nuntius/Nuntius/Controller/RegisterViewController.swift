//
//  RegisterViewController.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/15/22.
//update database update search cause it goes too back. update ui
import UIKit
import FirebaseAuth
class RegisterViewController: UIViewController {
    
    @IBOutlet var passwordView: UIView!
    @IBOutlet var emailView: UIView!
    @IBOutlet var nameView: UIView!
    @IBOutlet var activity: UIActivityIndicatorView!
    @IBOutlet var passwordText: UITextField!
    @IBOutlet var userText: UITextField!
    @IBOutlet var emailText: UITextField!
    @IBOutlet var profileImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordView.layer.cornerRadius = passwordView.frame.size.height/2.5
        emailView.layer.cornerRadius = emailView.frame.size.height/2.5
        nameView.layer.cornerRadius = nameView.frame.size.height/2.5
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped))
        profileImage.addGestureRecognizer(tapGR)
        profileImage.isUserInteractionEnabled = true
        profileImage.layer.masksToBounds = true
        profileImage.layer.cornerRadius = profileImage.frame.size.width/2
    }
    @objc func imageTapped(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            presentChoice()
        }
    }
    @IBAction func registerPressed(_ sender: Any) {
        guard let email=emailText.text, let password=passwordText.text, let username = userText.text, !email.isEmpty, !password.isEmpty,!username.isEmpty else{
            regError(error: "Please fill in all Information")
            return
        }
        UserDefaults.standard.set(email, forKey: "email")
        activity.startAnimating()
        FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                
                let err = error as NSError
                if let authErrorCode = AuthErrorCode.Code(rawValue: err.code) {
                    
                    switch authErrorCode {
                        
                    case .emailAlreadyInUse:
                        self.regError(error: "The email address is already in use by another account.")
                    case .invalidEmail:
                        self.regError(error: "The email address is badly formatted")
                    case .weakPassword:
                        self.regError(error: "The password must be 6 characters long or more")
                    default:
                        print(error.localizedDescription)
                    }
                }
                return
            } else{
            let currUser=User(username: username, email: email)
            DatabaseManager.base.userToData(with: currUser, completionHandler: {success in
                if success {
                        if let image = self.profileImage.image, let data = image.pngData(){
                            let imageFile = "\(currUser.email)_profilePicture.png"
                            StorageMangager.base.storePicture(with: data, fileName: imageFile) { url in
                                UserDefaults.standard.set(url, forKey: "profilePicture")
                            }
                        } else{
                            
                        }
                        self.activity.stopAnimating()
                        self.performSegue(withIdentifier: "registerToLog", sender: self)
                    }
                    else{
                        print("Error in registering user into Database")
                    }
                    
                })
                
            }
        }
    }
    func regError(error: String) {
        let alert = UIAlertController(title: "ERROR", message:error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

}
extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func presentChoice(){
        let choice = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        choice.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        choice.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: {[weak self]_ in
            self?.presentCamera()
        }))
        choice.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: {[weak self]_ in
            self?.presentPhotoPicker()
        }))
        present(choice, animated: true)
        
    }
    func presentCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
        
    }
    func presentPhotoPicker(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage =  info[UIImagePickerController.InfoKey.editedImage] as? UIImage else{
            return
        }
        self.profileImage.image = selectedImage
        
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
