//
//  GDPRAgreeAlertViewController.swift
//  HSAppFramework
//
//  Created by kai.sun on 2019/10/16.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//

import UIKit

func makeImageWithSolidColor(color:UIColor) -> UIImage? {
    let size = CGSize.init(width: 1, height: 1)
    UIGraphicsBeginImageContext(size)
    let currentContext = UIGraphicsGetCurrentContext()
    guard let context = currentContext else {
        return nil
    }
    context.setFillColor(color.cgColor)
    context.fill(CGRect.init(x: 0, y: 0, width: size.width, height: size.height))

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

class GDPRAgreeAlertViewController: GDPRBasicAlertViewController {

    private(set) var strings : [String : String] = [:]
    
    override init(style: GdprAssentAlertStyle, moreURL: URL?, completion: @escaping (Bool) -> Void) {
        super.init(style: style, moreURL: moreURL, completion: completion)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let buttonHeight = 40
        let buttonWidth = 242
        
        self.okButton = {
            let button = UIButton.init(type: UIButton.ButtonType.custom)
            button.addTarget(self, action: #selector(touchUpContinue), for: UIControl.Event.touchUpInside)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            button.setTitleColor(UIColor.white, for: UIControl.State.normal)
            button.setBackgroundImage(makeImageWithSolidColor(color: button.tintColor ?? self.view.tintColor), for: UIControl.State.normal)
            button.layer.cornerRadius = CGFloat(buttonHeight / 2)
            button.layer.masksToBounds = true
            return button
        }()
        self.buttonsView.addSubview(self.okButton)
        
        let buttonsMetrics = ["height" : buttonHeight]
        let buttonsCollection : [String : UIButton] = ["ok": self.okButton /*, "cancel":cancelButton*/]
        
        for button in buttonsCollection.values {
            button.contentEdgeInsets = UIEdgeInsets.init(top: 20, left: 8, bottom: 20, right: 8)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addConstraint(NSLayoutConstraint.init(item: button, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: CGFloat(buttonWidth)))
            self.buttonsView.addConstraint(NSLayoutConstraint.init(item: button, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.buttonsView, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0))
        }
        self.buttonsView .addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[ok(height)]-12-|", options: [], metrics: buttonsMetrics, views: buttonsCollection))
        
        let localStrings =
                [ "t": "Privacy Policy Updates",
                    "m_c": "We’ve embraced a few changes in our Privacy Policy to make it even easier to understand what data we collect, how it’s processed and the controls you have. You can find more details about our updates for new European data protection laws (GDPR) by reading our Privacy Policy, and keep in mind that by using our app on or after May 25, 2018, you agree to our revisions. By continuing, you are confirming that you are over the age of 16 or under guidance of the holder of your parental responsibility.",
                    "m_a": "We’ve embraced a few changes in our Privacy Policy to make it even easier to understand what data we collect, how it’s processed and the controls you have. You can find more details about our updates for new European data protection laws (GDPR) by reading our Privacy Policy. By continuing, you are confirming that you are over the age of 16 or under guidance of the holder of your parental responsibility and agree to our revisions.",
                    "more": "Read",
                    "ok": "CONTINUE",
                    "c": "No, thank you",
                 ]

        self.strings = localStrings
        self.titleView.text = self.strings["t"]
        
        let paraStyle = NSMutableParagraphStyle.init()
        paraStyle.lineSpacing = 4
        paraStyle.alignment = NSTextAlignment.center
        let attributes : [NSAttributedString.Key : Any] = [.font : self.messageView.font!, .foregroundColor : self.messageView.textColor!, .paragraphStyle : paraStyle]
        
        let messageText : String
        switch self.style {
            case .Agree:
                messageText = self.strings["m_a"]!
                break
            case .Continue:
                messageText = self.strings["m_c"]!
                break
        }
        
        let attributeText = NSMutableAttributedString.init(string: messageText.appending(" (\(self.strings["more"] ?? "More"))"), attributes: attributes)
        let linkRange = NSRange.init(location: attributeText.length - String(self.strings["more"]!).count - 1, length: String(self.strings["more"]!).count)
        attributeText.addAttribute(.link, value: self.moreURL!, range: linkRange)

        self.messageView.attributedText = attributeText
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(recognizeTapMessageView(tap:)))
        self.messageView.addGestureRecognizer(recognizer)
        
        self.okButton.setTitle(self.strings["ok"], for: UIControl.State.normal)
    }
    
    @objc private func touchUpContinue() {
        self.didComplete(granted: true)
    }

    @objc private func recognizeTapMessageView(tap:UITapGestureRecognizer) {
        let textView = self.messageView!
        let tapLocation = tap.location(in: textView)
        // we need to get two positions since attributed links only apply to ranges with a length > 0
        var positionStart = textView.closestPosition(to: tapLocation)
        var positionEnd : UITextPosition?
        if (positionStart != nil) {
            positionEnd = textView.position(from: positionStart!, offset: 1)
            // check if we're beyond the max length and go back by one
            if positionEnd == nil {
                positionStart = textView.position(from: positionStart!, offset: -1)
                positionEnd = textView.position(from: positionStart!, offset: 1)
            }
            if positionEnd == nil {
                return
            }
        }
        
        // get the offset range of the character we tapped on
        let range = textView.textRange(from: positionStart!, to: positionEnd!)
        let startOffset = textView.offset(from: textView.beginningOfDocument, to: range!.start)
        let endOffset = textView.offset(from: textView.beginningOfDocument, to: range!.end)
        var offsetRange = NSRange.init(location: startOffset, length: endOffset - startOffset)
        if offsetRange.location == NSNotFound || offsetRange.length == 0 || NSMaxRange(offsetRange) > textView.attributedText.length {
            return
        }
        
        // now grab the link from the string
        let attributeSubString : NSAttributedString = textView.attributedText.attributedSubstring(from: offsetRange)
        let link = attributeSubString.attribute(NSAttributedString.Key.link, at: 0, effectiveRange: &offsetRange)
        if link == nil {
            return
        }
        self.touchedReadPrivacyPolicy()
    }
    
    override func okButtonText() -> String? {
        return self.strings["ok"]
    }
    
    override func cancelButtonText() -> String? {
        return self.strings["c"]
    }
}
