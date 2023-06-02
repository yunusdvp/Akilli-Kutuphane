//
//  MasaCell.swift
//  Akilli Kutuphane
//
//  Created by Yunus Emre ÖZŞAHİN on 2.06.2023.
//

import UIKit

class MasaCell: UICollectionViewCell {
    @IBOutlet weak var masaAdLabel: UILabel!
    
    func configure(with masa: Masa) {
        if let masaAd = masa.masa_ad, let masaDurum = masa.masa_durum {
            masaAdLabel.text = masaAd
            
            if masaDurum {
                backgroundColor = UIColor.green
            } else {
                backgroundColor = UIColor.red
            }
        }
    }
}
