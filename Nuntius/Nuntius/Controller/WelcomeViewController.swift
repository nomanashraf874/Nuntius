//
//  WelcomeViewController.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/16/22.
//fix bugs
 //chat date
 //inncorrect passcode
 //loading
 //trial
//profile design
//chat controller design

import UIKit
import FirebaseAuth
class WelcomeViewController: UIViewController {

    @IBOutlet var titleLabel: UILabel!
    //Before view appear if you want to add special animations to view
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfLoggedIn()
        // Do any additional setup after loading the view.
        //Make the title apper word by word
        titleLabel.text=""
        var index = 0;
        let titleText = "꒰ঌNuntius໒꒱"
        for letter in titleText {
            Timer.scheduledTimer(withTimeInterval: 0.1*Double(index), repeats: false) { timer in
                self.titleLabel.text?.append(letter)
            }
            index = index+1;
        }
    }
    //reverse the special animations you did in viewWillAppear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    private func checkIfLoggedIn(){
        if FirebaseAuth.Auth.auth().currentUser != nil{
            let vc = storyboard?.instantiateViewController(withIdentifier: "already") as! UITabBarController
            self.present(vc,animated: true, completion:nil)
        }
    }
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {

    }

}
