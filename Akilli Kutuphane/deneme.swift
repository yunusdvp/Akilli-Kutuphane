//
//  deneme.swift
//  Akilli Kutuphane
//
//  Created by Yunus Emre ÖZŞAHİN on 3.06.2023.
//
/*
import UIKit
import AVFoundation
import Firebase
import UserNotifications

class DetayViewController: UIViewController {
    
    @IBOutlet weak var masaAdLabel: UILabel!
    @IBOutlet weak var rezervasyonYapButton: UIButton!
    @IBOutlet weak var qrKoduOkutButton: UIButton!
    
    var masa: Masa?
    var timer: Timer?
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var qrCodeFrameView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        print(masa?.masa_qr)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startTimerIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }
    
    func configureUI() {
        masaAdLabel.text = masa?.masa_ad
    }
    
    @IBAction func rezervasyonYapButtonTapped(_ sender: UIButton) {
        if let selectedMasa = masa {
            guard let masaDurum = selectedMasa.masa_durum else {
                showAlert(message: "Hatalı Masa Durumu.")
                return
            }
            
            if !masaDurum {
                selectedMasa.masa_durum = true
                
                let databaseRef = Database.database().reference().child("masalar").child(selectedMasa.masa_ad ?? "")
                databaseRef.setValue(selectedMasa.toDictionary()) { (error, _) in
                    if let error = error {
                        self.showAlert(message: "Masa durumu güncellenirken hata oluştu: \(error.localizedDescription)")
                    } else {
                        self.masa?.masa_durum = true
                        
                        self.startTimerForReservation()
                        self.showAlert(message: "Masa durumu güncellendi ve kaydedildi.")
                    }
                }
            } else {
                showAlert(message: "Masa zaten rezerve edilmiş durumda.")
            }
        }
    }
    
    @IBAction func qrKoduOkutButtonTapped(_ sender: UIButton) {
        startQRCodeScanning()
    }
    
    func startQRCodeScanning() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            showAlert(message: "Kamera bulunamadı veya erişilemez.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession = AVCaptureSession()
            captureSession.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [.qr]
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer)
            
            captureSession.startRunning()
            
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
            }
        } catch {
            showAlert(message: "Kamera başlatılırken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    func stopQRCodeScanning() {
        captureSession.stopRunning()
        qrCodeFrameView?.removeFromSuperview()
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Uyarı", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func appDidEnterBackground() {
        startBackgroundTask()
    }
    
    func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "BackgroundTask") {
            [weak self] in
            self?.endBackgroundTask()
        }
        
        guard backgroundTask != .invalid else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: false) { [weak self] _ in
            self?.sendNotification(message: "Oturumunuz 5 dakika sonra sonlanacak.")
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: false) { [weak self] _ in
            self?.endReservation()
        }
        
        RunLoop.current.add(timer!, forMode: .default)
    }
    
    func endBackgroundTask() {
        timer?.invalidate()
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
    
    func startTimerIfNeeded() {
        guard let selectedMasa = masa, selectedMasa.masa_durum else { return }
        
        guard let startDate = selectedMasa.rezervasyon_tarihi, let duration = selectedMasa.rezervasyon_suresi else {
            showAlert(message: "Geçersiz rezervasyon bilgileri.")
            return
        }
        
        let currentDate = Date()
        let endDate = startDate.addingTimeInterval(duration * 60)
        
        if currentDate < endDate {
            timer = Timer.scheduledTimer(withTimeInterval: endDate.timeIntervalSince(currentDate), repeats: false) { [weak self] _ in
                self?.endReservation()
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func startTimerForReservation() {
        guard let duration = masa?.rezervasyon_suresi else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: duration * 60, repeats: false) { [weak self] _ in
            self?.endReservation()
        }
        
        RunLoop.current.add(timer!, forMode: .default)
    }
    
    func endReservation() {
        guard let selectedMasa = masa, selectedMasa.masa_durum else { return }
        
        selectedMasa.masa_durum = false
        
        let databaseRef = Database.database().reference().child("masalar").child(selectedMasa.masa_ad ?? "")
        databaseRef.setValue(selectedMasa.toDictionary()) { (error, _) in
            if let error = error {
                self.showAlert(message: "Masa durumu güncellenirken hata oluştu: \(error.localizedDescription)")
            } else {
                self.stopTimer()
                self.showAlert(message: "Oturum sonlandırıldı.")
            }
        }
    }
    
    func sendNotification(message: String) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Bildirim"
            content.body = message
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: "ReservationNotification", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Bildirim gönderilirken hata oluştu: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension DetayViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            showAlert(message: "QR kodu bulunamadı.")
            return
        }
        
        guard let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject else {
            qrCodeFrameView?.frame = CGRect.zero
            showAlert(message: "QR kodu okunamadı.")
            return
        }
        
        if metadataObj.type == .qr {
            guard let qrCodeData = metadataObj.stringValue else {
                showAlert(message: "QR kodu bilgileri alınamadı.")
                return
            }
            
            stopQRCodeScanning()
            
            // QR kod verilerini kullan
            // ...
        }
    }
}
import UIKit
import AVFoundation
import Firebase

class DetayViewController: UIViewController {
    
    @IBOutlet weak var masaAdLabel: UILabel!
    @IBOutlet weak var rezervasyonYapButton: UIButton!
    @IBOutlet weak var qrKoduOkutButton: UIButton!
    
    var masa: Masa?
    // Rezervasyon başlangıç tarihi

    var timer: Timer?
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid // Arka plan görevi tanımlayıcı
    
    // QR kodu tarama işlemleri için gerekli değişkenler
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var qrCodeFrameView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        print(masa?.masa_qr)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startTimerIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }
    
    // Arayüzü yapılandırma
    func configureUI() {
        masaAdLabel.text = masa?.masa_ad
    }
    
    // Rezervasyon Yap butonuna tıklandığında
    @IBAction func rezervasyonYapButtonTapped(_ sender: UIButton) {
        if let selectedMasa = masa {
            guard let masaDurum = selectedMasa.masa_durum else {
                showAlert(message: "Hatalı Masa Durumu.")
                return
            }
            
            if !masaDurum {
                // Masa durumunu güncelle
                selectedMasa.masa_durum = true
                
                // Realtime Database'e kaydet
                let databaseRef = Database.database().reference().child("masalar").child(selectedMasa.masa_ad ?? "")
                databaseRef.setValue(selectedMasa.toDictionary()) { (error, _) in
                    if let error = error {
                        self.showAlert(message: "Masa durumu güncellenirken hata oluştu: \(error.localizedDescription)")
                    } else {
                        // Güncellenen masa durumunu yerel olarak da güncelle
                        self.masa?.masa_durum = true
                        
                        self.showAlert(message: "Masa durumu güncellendi ve kaydedildi.")
                    }
                }
            } else {
                showAlert(message: "Masa zaten rezerve edilmiş durumda.")
            }
        }
    }
    
    // QR kodu okut butonuna tıklandığında
    @IBAction func qrKoduOkutButtonTapped(_ sender: UIButton) {
        startQRCodeScanning()
    }
    
    // QR kodu tarama işlemlerini başlatma
    func startQRCodeScanning() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            showAlert(message: "Kamera bulunamadı veya erişilemez.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession = AVCaptureSession()
            captureSession.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [.qr]
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer)
            
            captureSession.startRunning()
            
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
            }
            
        } catch {
            showAlert(message: "Kamera girişi yapılandırılamadı.")
            return
        }
    }
    func startTimerForReservation() {
        guard let selectedMasa = masa else {
            return
        }
        
        // 60 dakikalık sürenin bitiş zamanını hesapla
        let calendar = Calendar.current
        let now = Date()
        let endTime = calendar.date(byAdding: .minute, value: 60, to: now) ?? now
        
        // Timer'ı başlat
        startTimer(with: endTime)
    }

    // Timer'ı başlatma gerekiyorsa
    func startTimerIfNeeded() {
        guard let selectedMasa = masa else {
            return
        }
        
        guard let masaDurum = selectedMasa.masa_durum else {
            return
        }
        
        if masaDurum {
            let calendar = Calendar.current
            let now = Date()
            
            let rezervasyonBitis = selectedMasa.rezervasyon_baslangic?.addingTimeInterval(60 * 2)
            if now < rezervasyonBitis! {
                // 5 dakika kala hatırlatma bildirimi gönder
                let reminderTime = calendar.date(byAdding: .minute, value: -1, to: rezervasyonBitis ?? now) ?? now
                scheduleReminderNotification(at: reminderTime)
                
                // Timer'ı başlat
                startTimer(with: rezervasyonBitis ?? now)
            } else {
                showAlert(message: "Masa rezervasyon süresi dolmuştur.")
                selectedMasa.masa_durum = false
                updateMasaDurumu()
            }
        }
    }
    func sendNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Bildirim"
        content.body = message
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "reservationNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Bildirim gönderme hatası: \(error.localizedDescription)")
            }
        }
    }

    func scheduleReminderNotification(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Hatırlatma"
        content.body = "5 dakika sonra tekrar QR kodu okutmanız gerekmektedir."
        content.sound = UNNotificationSound.default
        
        let triggerDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: "reminderNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Bildirim gönderme hatası: \(error.localizedDescription)")
            }
        }
    }


    
    // Timer'ı başlatma
    func startTimer(with endTime: Date) {
        stopTimer()
        
        timer = Timer(fireAt: endTime, interval: 0, target: self, selector: #selector(timerExpired), userInfo: nil, repeats: false)
        
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    // Timer'ı durdurma
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Timer süresi dolunca yapılacak işlemler
    @objc func timerExpired() {
        // Masa durumunu false olarak güncelle
        masa?.masa_durum = false
        updateMasaDurumu()
        
        // Bildirim gönder
        sendNotification(message: "Oturumunuz sonlanmıştır. Lütfen tekrar QR kodu okutunuz.")
    }

    
    // Masa durumunu güncelle
    func updateMasaDurumu() {
        if let selectedMasa = masa {
            let databaseRef = Database.database().reference().child("masalar").child(selectedMasa.masa_ad ?? "")
            databaseRef.setValue(selectedMasa.toDictionary()) { (error, _) in
                if let error = error {
                    self.showAlert(message: "Masa durumu güncellenirken hata oluştu: \(error.localizedDescription)")
                } else {
                    self.masa?.masa_durum = false
                }
            }
        }
    }
    
    // Arka plana geçildiğinde yapılacak işlemler
    @objc func appDidEnterBackground() {
        if let selectedMasa = masa {
            guard let rezervasyonBaslangic = selectedMasa.rezervasyon_baslangic else {
                return
            }
            
            guard let masaDurum = selectedMasa.masa_durum else {
                return
            }
            
            if masaDurum {
                let calendar = Calendar.current
                let now = Date()
                
                if now < rezervasyonBaslangic {
                    // Geçerli rezervasyon süresini hesapla
                    let rezervasyonSuresi = calendar.dateComponents([.minute], from: now, to: rezervasyonBaslangic).minute
                    
                    if let rezervasyonSuresi = rezervasyonSuresi {
                        // Timer'ı güncelle
                        let newEndTime = calendar.date(byAdding: .minute, value: rezervasyonSuresi, to: now)
                        startTimer(with: newEndTime ?? rezervasyonBaslangic)
                    }
                } else {
                    showAlert(message: "Masa rezervasyon süresi dolmuştur.")
                    selectedMasa.masa_durum = false
                    updateMasaDurumu()
                }
            }
        }
        
        // Arkaplan görevini başlat
        registerBackgroundTask()
    }
    
    // Arka plan görevini başlatma
    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        assert(backgroundTask != .invalid)
    }
    
    // Arka plan görevini sonlandırma
    func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
    
    // Uyarı mesajı gösterme
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "Uyarı", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Tamam", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension DetayViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
                showAlert(message: "QR kod okunamadı.")
                return
            }
            
            guard let stringValue = readableObject.stringValue else {
                showAlert(message: "QR kod değeri boş.")
                return
            }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            processQRCode(with: stringValue)
        }
    }
    
    func processQRCode(with code: String) {
        // QR kodun işlenmesi
        print("QR kodu: \(code)")
    }
}
*/
