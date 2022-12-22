//
//  LoginViewController.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/15/22.
//

import UIKit
import FirebaseAuth
class LoginViewController: UIViewController {

    @IBOutlet var emailText: UITextField!
    @IBOutlet var passwordView: UIView!
    @IBOutlet var emailView: UIView!
    @IBOutlet var activity: UIActivityIndicatorView!
    @IBOutlet var passwordText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordView.layer.cornerRadius = passwordView.frame.size.height/2
        emailView.layer.cornerRadius = emailView.frame.size.height/2
        // Do any additional setup after loading the view.
        
    }
    
    @IBAction func LoginPressed(_ sender: Any) {
        guard let email=emailText.text, let password=passwordText.text, !email.isEmpty, !password.isEmpty else{
            loginError(error: "Please fill in all Information")
            return
        }
        activity.startAnimating()
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                
                let err = error as NSError
                if let authErrorCode = AuthErrorCode.Code(rawValue: err.code) {
                    
                    switch authErrorCode {
                    case .wrongPassword:
                        self.loginError(error: "The password is invalid")
                    case .invalidEmail:
                        self.loginError(error: "Invalid email")
                    default:
                        print(error.localizedDescription)
                    }
                }
                return
            } else{
                self.activity.stopAnimating()
                UserDefaults.standard.set(email, forKey: "email")
                self.performSegue(withIdentifier: "loginToLog", sender: self)
            }
        }
    }
    func loginError(error: String) {
        self.activity.stopAnimating()
        let alert = UIAlertController(title: "ERROR", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}
