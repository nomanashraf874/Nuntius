//
//  WelcomeViewController.swift
//  Nuntius
//
//  Created by Noman Ashraf on 11/16/22.
//image
/*
 to fix:
bane
 lastmessage autoload
 */

import UIKit
import FirebaseAuth
class WelcomeViewController: UIViewController {

    @IBOutlet var titleLabel: UILabel!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //checkIfLoggedIn()
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

    private func checkIfLoggedIn(){
        if FirebaseAuth.Auth.auth().currentUser != nil{
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "already")
            self.present(vc,animated: true)
        }
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {

    }

}
