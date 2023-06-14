import UIKit
import Firebase
import FirebaseAuth
import CoreLocation

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CLLocationManagerDelegate,UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var masalar: [Masa] = []
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundImage = UIImage(named: "backgroundImageName")
        let backgroundImageView = UIImageView(frame: collectionView.bounds)
        backgroundImageView.image = backgroundImage
        backgroundImageView.contentMode = .scaleAspectFill
        view.insertSubview(backgroundImageView, at: 0)

        // CLLocationManagerDelegate'i ayarla
        locationManager.delegate = self
        
        // Konum izinlerini iste
        locationManager.requestWhenInUseAuthorization()
        
        // Kullanıcının konumunu izlemeye başla
        locationManager.startUpdatingLocation()
        
        // Firebase yapılandırması
        let databaseRef = Database.database().reference().child("masalar")
        let queryDatabase = databaseRef.queryOrdered(byChild: "masa_ad")

        // Verileri çekme
        queryDatabase.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let self = self else { return }

            if let masalarData = snapshot.value as? [String: [String: Any]] {
                let sortedMasalarData = masalarData.sorted(by: { $0.key < $1.key })

                self.masalar = sortedMasalarData.compactMap { (_, masaData) in
                    let masa = Masa(
                        masa_ad: masaData["masa_ad"] as? String,
                        masa_qr: masaData["masa_qr"] as? String,
                        masa_durum: masaData["masa_durum"] as? Bool
                    )
                    return masa
                }

                self.collectionView.reloadData()
            }
        }

        collectionView.delegate = self
        collectionView.dataSource = self
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            
        let width = (collectionView.bounds.width/3)-20
            let height = width
            
            return CGSize(width: width, height: height)
        }
    

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return masalar.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MasaCell", for: indexPath) as? MasaCell else {
            return UICollectionViewCell()
        }
        
        let masa = masalar[indexPath.item]
        cell.configure(with: masa)
        
        return cell
    }



    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedMasa = masalar[indexPath.row]
        
        if !isUserAtLibraryLocation() {
            showAlert(message: "Kütüphane konumunda değilsiniz.")
            return
        }
        
        performSegue(withIdentifier: "DetaySegue", sender: selectedMasa)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DetaySegue" {
            if let detayViewController = segue.destination as? DetayViewController {
                if let selectedMasa = sender as? Masa {
                    detayViewController.masa = selectedMasa
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            // Konum izni verildi, konum güncellemelerini başlat
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else {
            return
        }
        
        if !isUserInLibrary(currentLocation) {
            showAlert(message: "Kütüphane konumunda değilsiniz.")
        }
        
        locationManager.stopUpdatingLocation()
    }
    
    func isUserInLibrary(_ location: CLLocation) -> Bool {
        let libraryLocation = CLLocation(latitude: 40.7416971, longitude: 30.332471
        )
        let distance = location.distance(from: libraryLocation)
        let isInLibrary = distance < 15 // 15 metre mesafe kontrolü yapılıyor
        
        return isInLibrary
    }

    func isUserAtLibraryLocation() -> Bool {
        guard let userLocation = locationManager.location else {
            return false
        }

        return isUserInLibrary(userLocation)
    }

    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Uyarı", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func updateMasaDurum() {
        let databaseRef = Database.database().reference().child("masalar")
        let queryDatabase = databaseRef.queryOrdered(byChild: "masa_ad")
        
        queryDatabase.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let self = self else { return }
            
            if let masalarData = snapshot.value as? [String: [String: Any]] {
                let sortedMasalarData = masalarData.sorted(by: { $0.key < $1.key })
                
                self.masalar = sortedMasalarData.compactMap { (_, masaData) in
                    let masa = Masa(
                        masa_ad: masaData["masa_ad"] as? String,
                        masa_qr: masaData["masa_qr"] as? String,
                        masa_durum: masaData["masa_durum"] as? Bool
                    )
                    return masa
                }
                
                self.collectionView.reloadData()
            }
        }
    }
}
