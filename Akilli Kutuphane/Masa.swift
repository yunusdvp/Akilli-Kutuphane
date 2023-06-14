//
//  Masa.swift
//  Akilli Kutuphane
//
//  Created by Yunus Emre ÖZŞAHİN on 2.06.2023.
//

import Foundation
class Masa {
    var masa_ad: String?
    var masa_qr: String?
    var masa_durum: Bool?
    var masadaki_kullanici:String?
    var rezervasyon_suresi: Int? // Rezervasyon süresi (in minutes)
    var rezervasyon_baslangic: Date?
    var son_guncelleme: Date?
    init(masa_ad: String? = nil, masa_qr: String? = nil, masa_durum: Bool? = nil, rezervasyon_suresi: Int? = nil, rezervasyon_baslangic: Date? = nil) {
        self.masa_ad = masa_ad
        self.masa_qr = masa_qr
        self.masa_durum = masa_durum
        self.rezervasyon_suresi = rezervasyon_suresi
        self.rezervasyon_baslangic = rezervasyon_baslangic
    }
    init(masa_ad: String? = nil, masa_qr: String? = nil, masa_durum: Bool? = nil) {
        self.masa_ad = masa_ad
        self.masa_qr = masa_qr
        self.masa_durum = masa_durum
    }
    init(masa_ad: String? = nil, masa_qr: String? = nil, masa_durum: Bool? = nil, rezervasyon_suresi: Int? = nil, rezervasyon_baslangic: Date? = nil, son_guncelleme: Date? = nil,masadaki_kullanici: String? = nil) {
            self.masa_ad = masa_ad
            self.masa_qr = masa_qr
            self.masa_durum = masa_durum
            self.rezervasyon_suresi = rezervasyon_suresi
            self.rezervasyon_baslangic = rezervasyon_baslangic
            self.son_guncelleme = son_guncelleme
            self.masadaki_kullanici = masadaki_kullanici
        }
    init() {
        
    }
    func toDictionary() -> [String: Any] {
            var dictionary: [String: Any] = [:]
            dictionary["masa_ad"] = masa_ad
            dictionary["masa_qr"] = masa_qr
            dictionary["masa_durum"] = masa_durum
            dictionary["son_guncelleme"] = son_guncelleme?.timeIntervalSince1970
            dictionary["masadaki_kullanici"] = masadaki_kullanici
            return dictionary
        }
}
