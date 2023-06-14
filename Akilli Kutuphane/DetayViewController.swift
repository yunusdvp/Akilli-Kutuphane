//
//  deneme.swift
//  Akilli Kutuphane
//
//  Created by Yunus Emre ÖZŞAHİN on 3.06.2023.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseAuth

class DetayViewController: UIViewController {

    @IBOutlet weak var uyariMetni: UITextView!
    @IBOutlet weak var masaAdLabel: UILabel!
    @IBOutlet weak var rezervasyonYapButton: UIButton!
    @IBOutlet weak var qrKoduOkutButton: UIButton!

    var masa: Masa?
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var qrCodeFrameView: UIView!
    var captureQueue = DispatchQueue(label: "com.example.captureQueue")

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        

    }

    /*override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startQRCodeScanning()
    }*/

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopQRCodeScanning()
    }
    func getCurrentUserID(){
        if let user = Auth.auth().currentUser {
            let userID = user.uid
            self.masa?.masadaki_kullanici = userID
        }
    }

    func configureUI() {
        masaAdLabel.text = masa?.masa_ad
    }

    @IBAction func oturumuKapatButtonTapped(_ sender: UIButton) {
        logOut()
    }

    func stopQRCodeScanning() {
        DispatchQueue.main.async { [self] in
            captureSession?.stopRunning()
            videoPreviewLayer?.removeFromSuperlayer()
            qrCodeFrameView?.removeFromSuperview()
        }
    }
    func logOut() {
        if let selectedMasa = self.masa {
            guard let masaDurum = selectedMasa.masa_durum else {
                showAlert(message: "Hatalı Masa Durumu.")
                return
            }

            if masaDurum {
                if let currentUserID = Auth.auth().currentUser?.uid,
                   let masadakiKullaniciID = selectedMasa.masadaki_kullanici,
                   currentUserID == masadakiKullaniciID {
                    selectedMasa.masa_durum = false
                    selectedMasa.masadaki_kullanici = nil
                    selectedMasa.son_guncelleme = nil // veya uygun bir değer atayın

                    let databaseRef = Database.database().reference().child("masalar").child(selectedMasa.masa_ad ?? "")
                    databaseRef.setValue(selectedMasa.toDictionary()) { (error, _) in
                        DispatchQueue.main.async {
                            if let error = error {
                                self.showAlert(message: "Masa durumu güncellenirken hata oluştu: \(error.localizedDescription)")
                            } else {
                                self.showAlert(message: "Oturumunuz başarıyla sonlandırıldı.")
                            }
                        }
                    }
                } else {
                    showAlert(message: "Başkasının oturumunu sonlandıramazsınız.")
                }
            }
        }
    }


    @IBAction func qrKoduOkutButtonTapped(_ sender: UIButton) {
        startQRCodeScanning()
    }

    @objc func appDidEnterBackground() {
        stopQRCodeScanning()
    }

    func startQRCodeScanning() {
        DispatchQueue.main.async{ [self] in
            
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
                captureMetadataOutput.setMetadataObjectsDelegate(self, queue: captureQueue)
                captureMetadataOutput.metadataObjectTypes = [.qr]

                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                videoPreviewLayer.videoGravity = .resizeAspectFill
                videoPreviewLayer.frame = view.layer.bounds
                view.layer.addSublayer(videoPreviewLayer)

                qrCodeFrameView = UIView()

                if let qrCodeFrameView = qrCodeFrameView {
                    qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                    qrCodeFrameView.layer.borderWidth = 2
                    view.addSubview(qrCodeFrameView)
                    view.bringSubviewToFront(qrCodeFrameView)
                }

                captureSession.startRunning()
            } catch {
                showAlert(message: "Kamera başlatılırken hata oluştu: \(error.localizedDescription)")
            }
            
        }
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Uyarı", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension DetayViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            showAlert(message: "QR kod okunamadı.")
            return
        }
        
        stopQRCodeScanning()
        processQRCode(with: stringValue)
    }
    
    func processQRCode(with code: String) {
        // QR kodunun işlenmesi
        print("QR kodu: \(code)")
        
        DispatchQueue.main.async {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                self.showAlert(message: "Oturumunuz açık değil.")
                return
            }
            
            let databaseRef = Database.database().reference().child("masalar")
            databaseRef.observeSingleEvent(of: .value) { (snapshot) in
                guard let masalarSnapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                    self.showAlert(message: "Masalar alınırken hata oluştu.")
                    return
                }
                
                var isOpenSession = false
                for masaSnapshot in masalarSnapshot {
                    if let masaDict = masaSnapshot.value as? [String: Any] {
                        if let masadakiKullaniciID = masaDict["masadaki_kullanici"] as? String, masadakiKullaniciID == currentUserID {
                            isOpenSession = true
                            break
                        }
                    }
                }
                
                if isOpenSession {
                    self.showAlert(message: "Zaten açık bir oturumunuz bulunmaktadır.")
                } else {
                    // Masa QR kodu doğru, diğer işlemlere geçebilirsiniz.
                    guard let selectedMasa = self.masa else {
                        self.showAlert(message: "Seçili masa bulunamadı.")
                        return
                    }
                    
                    guard let masaQR = selectedMasa.masa_qr else {
                        self.showAlert(message: "Hatalı Masa QR Kodu.")
                        return
                    }
                    
                    if masaQR == code {
                        guard let masaDurum = selectedMasa.masa_durum else {
                            self.showAlert(message: "Hatalı Masa Durumu.")
                            return
                        }
                        
                        if !masaDurum {
                            selectedMasa.masadaki_kullanici = currentUserID
                            selectedMasa.son_guncelleme = Date()
                            selectedMasa.masa_durum = true
                            
                            let databaseRef = Database.database().reference().child("masalar").child(selectedMasa.masa_ad ?? "")
                            databaseRef.setValue(selectedMasa.toDictionary()) { (error, _) in
                                DispatchQueue.main.async {
                                    if let error = error {
                                        self.showAlert(message: "Masa durumu güncellenirken hata oluştu: \(error.localizedDescription)")
                                    } else {
                                        self.showAlert(message: "Oturum başarıyla açıldı.")
                                    }
                                }
                            }
                        } else {
                            self.showAlert(message: "Masa zaten rezerve edilmiş durumda.")
                        }
                    } else {
                        self.showAlert(message: "Yanlış QR kodu.")
                    }
                }
            }
        }
    }



}









