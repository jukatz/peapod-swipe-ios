//
//  ProductDetailViewController.swift
//  PeapodSwipe
//
//  Created by Xinjiang Shao on 3/4/18.
//  Copyright © 2018 Xinjiang Shao. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Alamofire
import AlamofireImage


struct ProductDetailViewUX {
    static let ProductImageHeight: CGFloat = 300
    static let NameLabelHeight: CGFloat = 40
    static let SideMargin: CGFloat = 12
    static let NavigationBarHeight: CGFloat = 50
    
}

class ProductDetailViewController: UIViewController {
    
    var product: Product!
    var productId: Int!
    var shouldShowNotifyButton: Bool!
    
    let titleLabel = UILabel()
    let imageView = UIImageView()
    let ratingLabel = UILabel()
    let detailsTextView = UITextView()
    let likeButton = UIButton()
    let placeholderImage = UIImage(named: "placeholder")
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProductDetailData(productId: productId)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    override func viewDidLoad() {
        view.backgroundColor = UIColor.white
        
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 0
        imageView.layer.masksToBounds = true
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.accessibilityIgnoresInvertColors = true
        
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(ratingLabel)
        view.addSubview(likeButton)
        view.addSubview(detailsTextView)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.layer.masksToBounds = true
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        
        detailsTextView.font = UIFont.systemFont(ofSize: 14)
        
        likeButton.setTitle("I Love this!", for: .normal)
        likeButton.setTitleColor(UIColor.white, for: .normal)
        likeButton.backgroundColor = UIColor.Defaults.pandaBlue
        likeButton.layer.cornerRadius = 5
        likeButton.layer.masksToBounds = true
        likeButton.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(ProductDetailViewController.dismissViewController)))
        
        if shouldShowNotifyButton {
            likeButton.isHidden = false
        } else {
            likeButton.isHidden = true
        }
        
        imageView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(self.view.snp.width)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.imageView.snp.bottom).offset(10)
            make.trailing.equalTo(self.view.safeAreaLayoutGuide.snp.trailingMargin).offset(-ProductDetailViewUX.SideMargin)
            make.leading.equalTo(self.view.safeAreaLayoutGuide.snp.leading).offset(ProductDetailViewUX.SideMargin)
            make.height.greaterThanOrEqualTo(ProductDetailViewUX.NameLabelHeight)
        }
        
        ratingLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.trailing.equalTo(self.view.safeAreaLayoutGuide.snp.trailingMargin).offset(-ProductDetailViewUX.SideMargin)
            make.leading.equalTo(self.view.safeAreaLayoutGuide.snp.leading).offset(ProductDetailViewUX.SideMargin)
            make.height.equalTo(ProductDetailViewUX.NameLabelHeight)
        }
        
        likeButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.ratingLabel.snp.bottom)
            make.left.right.equalTo(self.ratingLabel)
            make.height.equalTo(ProductDetailViewUX.NameLabelHeight)
        }
        
        detailsTextView.snp.makeConstraints { (make) in
            if shouldShowNotifyButton {
                make.top.equalTo(self.likeButton.snp.bottom)
            }else{
                make.top.equalTo(self.ratingLabel.snp.bottom)
            }
            
            make.trailing.equalTo(self.view.safeAreaLayoutGuide.snp.trailingMargin).offset(-ProductDetailViewUX.SideMargin)
            make.leading.equalTo(self.view.safeAreaLayoutGuide.snp.leading).offset(ProductDetailViewUX.SideMargin)
            make.bottom.equalTo(self.view)
        }
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(ProductDetailViewController.dismissViewController)))
    }
    
    @objc func dismissViewController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func loadProductDetailData(productId: Int) {
        var headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        var serviceConfig: NSDictionary?
        if let path = Bundle.main.path(forResource: "PeapodService-Info", ofType: "plist") {
            serviceConfig = NSDictionary(contentsOfFile: path)
        }
        
        let appId = serviceConfig?.object(forKey: "CLIENT_ID") as! String
        let appSecret = serviceConfig?.object(forKey: "CLIENT_SECRET") as! String
        
        if let authorizationHeader = Request.authorizationHeader(user: appId, password: appSecret) {
            headers[authorizationHeader.key] = authorizationHeader.value
        }
        
        Alamofire.request("https://www.peapod.com/api/v2.0/sessionid", method: .get, headers: headers)
            .validate(statusCode: 200..<300)
            .responseObject{ (response: DataResponse<SesssionResponse>) in
                
                if let sessionResult = response.value {
                    
                    Alamofire.request(
                        PeapodProductSearchRouter.details(sessionResult.sessionId, productId)
                        )
                        .validate()
                        .responseObject{ (response: DataResponse<ProductSearchResponseWithSessionId>) in
                            
                            if let productSearchResult = response.value {
                                //print(productSearchResult)
                                self.showItemDetail(product: productSearchResult.response.products[0])
                            }
                    }
                }
                
        }
    }
    
    func showItemDetail(product: Product) {
        self.product = product
        let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
            size: imageView.frame.size,
            radius: 0
        )
        let url = URL(string: self.product.images.xlargeImageURL.trim())!
        
        imageView.af_setImage(
            withURL: url,
            placeholderImage: placeholderImage,
            filter: filter,
            imageTransition: .crossDissolve(0.2)
        )
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = self.product.name
        imageView.accessibilityTraits = UIAccessibilityTraitImage
        
        titleLabel.text = self.product.name
        if (self.product.rating?.isLessThanOrEqualTo(0.0))! {
            ratingLabel.text = ""
            ratingLabel.isHidden = true
        }else{
            ratingLabel.text = "Rating: \(self.product.rating as! Float)"
            ratingLabel.isHidden = false
        }
        
        detailsTextView.text = self.product.extendedInfo?.detail
    }
}
