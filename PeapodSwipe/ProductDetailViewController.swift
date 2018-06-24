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
    static let titleLabelHeight: CGFloat = 32 * 2
    static let NameLabelHeight: CGFloat = 50
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
    let productInformationScrollView = ProductInformationScrollView()
    let likeButton = UIButton()
    let placeholderImage = UIImage(named: "placeholder")
    let loadingStateView = LoadingStateView()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadingStateView.isHidden = false
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

        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.layer.masksToBounds = true
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0

        likeButton.setTitle("I Love this!", for: .normal)
        likeButton.setTitleColor(UIColor.white, for: .normal)
        likeButton.backgroundColor = UIColor.Defaults.waterBlue
        likeButton.layer.cornerRadius = 5
        likeButton.layer.masksToBounds = true
        likeButton.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(ProductDetailViewController.likeProductFromItemDetail)
            )
        )
        if shouldShowNotifyButton {
            likeButton.isHidden = false
        } else {
            likeButton.isHidden = true
        }

        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(ProductDetailViewController.dismissViewController)
            )
        )
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(ProductDetailViewController.dismissViewController))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        imageView.addGestureRecognizer(swipeDown)
        
        productInformationScrollView.showsVerticalScrollIndicator = false
        setContentSize()

        view.addSubview(loadingStateView)
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(likeButton)
        view.addSubview(productInformationScrollView)

        imageView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(self.view.snp.width)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.imageView.snp.bottom).offset(10)
            make.trailing.equalTo(self.view.safeAreaLayoutGuide.snp.trailingMargin).offset(-ProductDetailViewUX.SideMargin)
            make.leading.equalTo(self.view.safeAreaLayoutGuide.snp.leading).offset(ProductDetailViewUX.SideMargin)
            make.height.greaterThanOrEqualTo(ProductDetailViewUX.titleLabelHeight)
        }

        likeButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(ProductDetailViewUX.SideMargin)
            make.left.right.equalTo(self.titleLabel)
            make.height.equalTo(ProductDetailViewUX.NameLabelHeight)
        }

        productInformationScrollView.snp.makeConstraints { (make) in
            if shouldShowNotifyButton {
                make.top.equalTo(self.likeButton.snp.bottom)
            } else {
                make.top.equalTo(self.titleLabel.snp.bottom)
            }

            make.left.right.bottom.equalTo(self.view)
        }

        loadingStateView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }

    }

    @objc func dismissViewController() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func likeProductFromItemDetail() {
        Alamofire.request(
            ProductRouter.postVote(self.productId, true)
            )
            .validate()
            .responseString { (response: DataResponse<String>) in
                print("Love \(self.productId)")
                if let voteResult = response.value {
                    print(voteResult)
                    self.dismiss(animated: true, completion: nil)
                }
        }
    }

    func loadProductDetailData(productId: Int) {
        Alamofire.request(
            ProductRouter.details(productId)
            )
            .validate()
            .responseObject { (response: DataResponse<Product>) in
                print("ProductId: \(productId)")
                if let productSearchResult = response.value {
                    self.showItemDetail(product: productSearchResult)
                    self.loadingStateView.isHidden = true
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

        addProductQuickFacts()

        productInformationScrollView.addNutritionLabels(
            calorieTotal: self.product.nutrition?.totalCalories,
            saturatedFatTotal: self.product.nutrition?.saturatedFat,
            sodiumTotal: self.product.nutrition?.sodium,
            sugarTotal: self.product.nutrition?.sugar
        )

    }

    func addProductQuickFacts() {
        var labels = [String]()
        let flags = self.product.productFlags
        if (flags?.dairy) != nil && (flags?.dairy)! {
            labels.append("Dairy-free")
        }

        if (flags?.gluten) != nil && (flags?.gluten)! {
            labels.append("Gluten-free")
        }

        if (flags?.peanut) != nil && (flags?.peanut)! {
            labels.append("Peanut-free")
        }

        if (flags?.egg) != nil && (flags?.egg)! {
            labels.append("Egg-free")
        }

        if (flags?.privateLabel?.flag) != nil && (flags?.privateLabel?.flag)! {
            labels.append("Store Brand")
        }

        if (flags?.organic?.flag) != nil && (flags?.organic?.flag)! {
            labels.append("Organic")
        }

        if (flags?.kosher) != nil && (flags?.kosher)! {
            labels.append("Kosher")
        }
        productInformationScrollView.addProductFlags(labels: labels)
    }
    //This is the method that allows the content to scroll the first time
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setContentSize()
    }
    //This is the method that allows the content to scroll after the
    //content was previously displayed
    override func viewDidAppear(_ animated: Bool) {
        setContentSize()
    }
    //I added 30 to the height to allow the user to "bounce"
    //the scroll at the end of the content
    private func setContentSize() {
        productInformationScrollView.contentSize = CGSize(width: view.frame.size.width, height: productInformationScrollView.getTotalHeight() + 30)
    }
}
