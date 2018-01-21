//
//  AboutMeViewController.swift
//  InstagramMagic
//
//  Created by Jerry on 2017/10/16.
//  Copyright © 2017年 Jerry. All rights reserved.
//

import UIKit

extension ViewController {
    
    @objc func popAboutMe() {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = NSTextAlignment.center
        
        let title = NSAttributedString(string: NSLocalizedString("aboutme.title", comment: ""), attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 24), NSAttributedStringKey.paragraphStyle: paragraphStyle])
        
        let lineOne = NSAttributedString(string: NSLocalizedString("aboutme.subtitle", comment: ""), attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18), NSAttributedStringKey.paragraphStyle: paragraphStyle])
        let lineTwo = NSAttributedString(string: NSLocalizedString("aboutme.github", comment: ""), attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18), NSAttributedStringKey.foregroundColor: UIColor(red: 0.46, green: 0.8, blue: 1.0, alpha: 1.0), NSAttributedStringKey.paragraphStyle: paragraphStyle])
        
        
        let button = CNPPopupButton.init(frame: CGRect(x: 0, y: 0, width: 200, height: 60))
        button.setTitleColor(UIColor.white, for: UIControlState())
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitle(NSLocalizedString("aboutme.suggest", comment: ""), for: UIControlState())
        
        button.backgroundColor = UIColor(red: 0.46, green: 0.8, blue: 1.0, alpha: 1.0)
        
        button.layer.cornerRadius = 4;
        button.selectionHandler = { (button) -> Void in
            //跳转评论
            if UIApplication.shared.canOpenURL(URL(string: "https://itunes.apple.com/us/app/igmagic/id1297906812?l=zh&ls=1&mt=8")!){
                UIApplication.shared.openURL(URL(string: "https://itunes.apple.com/us/app/igmagic/id1297906812?l=zh&ls=1&mt=8")!)
            }
        }
        
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0;
        titleLabel.attributedText = title
        
        let lineOneLabel = UILabel()
        lineOneLabel.numberOfLines = 0;
        lineOneLabel.attributedText = lineOne;
        
        let imageView = UIImageView.init(image: UIImage.init(named: "yang"))
        //计算图片的长宽比
        imageView.bounds = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 200, height: (UIScreen.main.bounds.width - 200) * 1440.0 / 1080.0)
        imageView.isUserInteractionEnabled = true
        let baiPhotoTapGestureRecognizer = UITapGestureRecognizer { (sender) in
            if UIApplication.shared.canOpenURL(URL(string: "instagram://user?username=sailormoon__11")!) {
                UIApplication.shared.openURL(URL(string: "instagram://user?username=sailormoon__11")!)
            }else{
                if UIApplication.shared.canOpenURL(URL(string: "https://www.instagram.com/sailormoon__11/")!) {
                    UIApplication.shared.openURL(URL(string: "https://www.instagram.com/sailormoon__11/")!)
                }
            }
        }
        imageView.addGestureRecognizer(baiPhotoTapGestureRecognizer)
        
        let lineTwoLabel = UILabel()
        lineTwoLabel.numberOfLines = 0;
        lineTwoLabel.attributedText = lineTwo;
        lineTwoLabel.isUserInteractionEnabled = true
        let githubTapGestureRecognizer = UITapGestureRecognizer { (sender) in
            if UIApplication.shared.canOpenURL(URL(string: "https://github.com/JerrySir/InstagramMagic")!) {
                UIApplication.shared.openURL(URL(string: "https://github.com/JerrySir/InstagramMagic")!)
            }
        }
        lineTwoLabel.addGestureRecognizer(githubTapGestureRecognizer)
        
        let popupController = CNPPopupController(contents:[titleLabel, lineOneLabel, imageView, lineTwoLabel, button])
        popupController.theme = CNPPopupTheme.default()
        popupController.theme.popupStyle = CNPPopupStyle.actionSheet
        popupController.delegate = self
        self.popupController = popupController
        popupController.present(animated: true)
    }
}

extension ViewController : CNPPopupControllerDelegate {
    
    func popupControllerWillDismiss(_ controller: CNPPopupController) {
        print("Popup controller will be dismissed")
    }
    
    func popupControllerDidPresent(_ controller: CNPPopupController) {
        print("Popup controller presented")
    }
    
}
