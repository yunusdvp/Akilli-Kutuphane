//
//  ViewController.swift
//  Akilli Kutuphane
//
//  Created by Yunus Emre ÖZŞAHİN on 1.06.2023.
//

import UIKit
import Firebase
import FirebaseAuth

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var masalar: [Masa] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Firebase yapılandırması
       
        
        // Realtime Database referansı
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
}


