//
//  AuthenticationViewController.swift
//  Akilli Kutuphane
//
//  Created by Yunus Emre ÖZŞAHİN on 1.06.2023.
//

import UIKit
import Firebase
import FirebaseAuth

class AuthenticationViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var rememberMeSwitch: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // Kullanıcı kaydı işlemi
    func signUp() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // TextField'ler boş ise veya geçerli bir değer içermiyorsa işlemi durdur
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                print("Kullanıcı kaydedilirken hata oluştu: \(error.localizedDescription)")
                return
            }
            
            // Kullanıcı başarıyla kaydedildi, isterseniz burada başka işlemler yapabilirsiniz
            print("Kullanıcı kaydedildi. Kullanıcı ID: \(authResult?.user.uid ?? "")")
        }
    }
    
    // Kullanıcı girişi işlemi
    func signIn() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // TextField'ler boş ise veya geçerli bir değer içermiyorsa işlemi durdur
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                let alertController = UIAlertController(title: "Hata",message:"Email veya Parola yanlış!", preferredStyle: .alert)
                print("Kullanıcı girişinde hata oluştu: \(error.localizedDescription)")
                let cancelAction = UIAlertAction(title: "İptal", style: .cancel) { (_) in
                    // İptal butonuna basıldığında gerçekleştirilecek aksiyon
                    print("İptal butonuna basıldı")
                }
                
                alertController.addAction(cancelAction)
                
                // Dışarıya tıklanınca kapatma aksiyonu
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissAlert))
                alertController.view.superview?.subviews[0].addGestureRecognizer(tapGesture)
                
                self.present(alertController, animated: true, completion: nil)
            }else{
                self.performSegue(withIdentifier: "AuthSegue", sender: nil)
            }
            return
        }
        
        // Kullanıcı başarıyla giriş yaptı, isterseniz burada başka işlemler yapabilirsiniz
        print("G")
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
    
    
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
            // Switch'in yeni durumunu kaydet
            UserDefaults.standard.set(sender.isOn, forKey: "RememberMeSwitch")
        print("Switch konumu değiştirildi")
        }
    // Kayıt ol butonuna basıldığında çağrılır
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        
        signUp()
    }
    
    // Giriş yap butonuna basıldığında çağrılır
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        signIn()
    }
    
    @IBAction func resetPasswordTapped(_ sender: Any) {
        guard let email = emailTextField.text else { return print("Hata") }
        resetPassword(email: email)
        
    }
    @objc func dismissAlert() {
        dismiss(animated: true, completion: nil)
    }
    
    
}
