//
//  Ogrenci.swift
//  Akilli Kutuphane
//
//  Created by Yunus Emre ÖZŞAHİN on 1.06.2023.
//

import Foundation
class Ogrenci{
    var ogrenci_id :String?
    var ogrenci_mail:String?
    var ogrenci_sifre:String?
    init(ogrenci_id: String? = nil, ogrenci_mail: String? = nil, ogrenci_sifre: String? = nil) {
        self.ogrenci_id = ogrenci_id
        self.ogrenci_mail = ogrenci_mail
        self.ogrenci_sifre = ogrenci_sifre
    }
}
