//
//  ProductFlagCollection.swift
//  PeapodSwipe
//
//  Created by Xinjiang Shao on 3/7/18.
//  Copyright © 2018 Xinjiang Shao. All rights reserved.
//

import Foundation

public struct ProductFlagCollection: Codable {
    let dairy: ProductRichFlag?
    let egg: ProductRichFlag?
    let gluten: ProductRichFlag?
    let peanut: ProductRichFlag?
    let organic: ProductRichFlag?
    let privateLabel: ProductRichFlag?

    let kosher: Bool?

    enum CodingKeys: String, CodingKey {
        case dairy
        case egg
        case gluten
        case peanut
        case organic
        case kosher
        case privateLabel
    }
}
