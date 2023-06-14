//
//  BackgroundTaskManager.swift
//  Akilli Kutuphane
//
//  Created by Yunus Emre ÖZŞAHİN on 4.06.2023.
//

//
//  BackgroundTaskManager.swift
//  Akilli Kutuphane
//
//  Created by Yunus Emre ÖZŞAHİN on 4.06.2023.
//
import BackgroundTasks
import Firebase
import FirebaseCore
import UIKit
import Foundation
import UIKit
import Firebase
import FirebaseCore

class BackgroundTaskManager:NSObject {
    static let shared = BackgroundTaskManager()
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var timer: Timer?
    
    func startBackgroundTask() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Bildirim izni istenirken hata oluştu: \(error.localizedDescription)")
            }
        }
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }

        // Görev süresini uzat
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            print("30 saniye uzatıldı")
            self?.checkAndUpdateTables()
        }
        
        // Timer'ı 2 dakika sonra başlat
        DispatchQueue.main.asyncAfter(deadline: .now() + 2 * 60) { [weak self] in
            self?.checkAndUpdateTables()
        }
    }

    func endBackgroundTask() {
        timer?.invalidate()
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
    
    func checkAndUpdateTables() {
        let databaseRef = Database.database().reference().child("masalar")
        let currentTime = Date().timeIntervalSince1970
        
        databaseRef.observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists() else {
                self.endBackgroundTask()
                return
            }
            
            if let masalarData = snapshot.value as? [String: Any] {
                for (masaId, masaData) in masalarData {
                    if let masaDict = masaData as? [String: Any],
                       let sonGuncelleme = masaDict["son_guncelleme"] as? TimeInterval,
                       let masaDurum = masaDict["masa_durum"] as? Bool {
                        let elapsedTime = currentTime - sonGuncelleme
                        if elapsedTime >= 2700 {
                            // Bildirim gönder
                            self.sendNotification()
                        }
                        
                        if elapsedTime >= 3600 {
                            let updatedMasaData = ["masa_durum": false,
                                                   "son_guncelleme": NSNull(),
                                                   "masadaki_kullanici": NSNull()]
                            databaseRef.child(masaId).updateChildValues(updatedMasaData)
                        }
                    }
                }
            }
            
            self.endBackgroundTask()
        }
    }

    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Oturumunuz Sonlanmak Üzere"
        content.body = "Lütfen QR kodunu tekrar okutun."
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "SessionEndNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Bildirim gönderirken hata oluştu: \(error.localizedDescription)")
            }
        }
    }

}
extension BackgroundTaskManager: UNUserNotificationCenterDelegate {
    // Bildirim ayarları
    

    // UNUserNotificationCenterDelegate yöntemleri burada
}
