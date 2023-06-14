//
//  AuthenticationViewController.swift
//  Akilli Kutuphane
//
//  Created by Yunus Emre ÖZŞAHİN on 1.06.2023.
//

import UIKit
import Firebase
import FirebaseAuth

class AuthenticationViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var rememberMeSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        

        let backgroundImage = UIImage(named: "backgroundImageName")
        let backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.image = backgroundImage
        backgroundImageView.contentMode = .scaleAspectFill
        view.insertSubview(backgroundImageView, at: 0)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        if rememberMeSwitch.isOn {
                if let savedEmail = UserDefaults.standard.string(forKey: "SavedEmail"),
                   let savedPassword = UserDefaults.standard.string(forKey: "SavedPassword") {
                    emailTextField.text = savedEmail
                    passwordTextField.text = savedPassword
                }
            }

        let rememberMeSwitchValue = UserDefaults.standard.bool(forKey: "RememberMeSwitch")
        rememberMeSwitch.isOn = rememberMeSwitchValue

        if rememberMeSwitchValue {
            fillLoginCredentials()
        }
        
    }

    @IBAction func switchValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "RememberMeSwitch")

        if !sender.isOn {
            clearLoginCredentials()
        }
    }

    func signUp() {
        
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            return
        }

        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)

        Auth.auth().currentUser?.link(with: credential, completion: { (authResult, error) in
            if let error = error {
                print("Kullanıcı kaydedilirken hata oluştu: \(error.localizedDescription)")
                return
            }

            print("Kullanıcı kaydedildi. Kullanıcı ID: \(authResult?.user.uid ?? "")")
        })
    }


    func signIn() {
        guard let email = emailTextField.text, !email.isEmpty,
                  let password = passwordTextField.text, !password.isEmpty else {
                return
            }

        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            // Giriş işlemi kontrolü...
            
            // Eğer Remember Me switch'i açıksa, e-posta ve şifreyi kaydet
            if self.rememberMeSwitch.isOn {
                UserDefaults.standard.set(email, forKey: "SavedEmail")
                UserDefaults.standard.set(password, forKey: "SavedPassword")
            } else {
                // Remember Me switch'i kapalı ise, kaydedilen e-posta ve şifreyi sil
                UserDefaults.standard.removeObject(forKey: "SavedEmail")
                UserDefaults.standard.removeObject(forKey: "SavedPassword")
            }
        }
        

        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                let alertController = UIAlertController(title: "Hata", message: "Email veya Parola yanlış!", preferredStyle: .alert)
                print("Kullanıcı girişinde hata oluştu: \(error.localizedDescription)")
                let cancelAction = UIAlertAction(title: "İptal", style: .cancel) { (_) in
                    print("İptal butonuna basıldı")
                }

                alertController.addAction(cancelAction)

                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissAlert))
                alertController.view.superview?.subviews[0].addGestureRecognizer(tapGesture)

                self.present(alertController, animated: true, completion: nil)
            } else {
                self.performSegue(withIdentifier: "AuthSegue", sender: nil)
            }
            return
        }

        print("Giriş başarılı.")
    }

    func resetPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            if let error = error {
                print("Parola sıfırlama hatası: \(error.localizedDescription)")
                return
            }

            print("Parola sıfırlama e-postası gönderildi.")
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        
        signUp()
    }
    

    @IBAction func signInButtonTapped(_ sender: UIButton) {
        signIn()
    }

    @IBAction func resetPasswordTapped(_ sender: Any) {
        guard let email = emailTextField.text else { return }
        resetPassword(email: email)
    }

    @objc func dismissAlert() {
        dismiss(animated: true, completion: nil)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func fillLoginCredentials() {
        if let email = UserDefaults.standard.string(forKey: "LastLoggedInEmail"),
           let password = UserDefaults.standard.string(forKey: "LastLoggedInPassword") {
            emailTextField.text = email
            passwordTextField.text = password
        }
    }

    func clearLoginCredentials() {
        emailTextField.text = ""
        passwordTextField.text = ""
        UserDefaults.standard.removeObject(forKey: "LastLoggedInEmail")
        UserDefaults.standard.removeObject(forKey: "LastLoggedInPassword")
    }
}

