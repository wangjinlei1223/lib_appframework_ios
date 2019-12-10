//
//  GDPRBasicAlertViewController.swift
//  HSAppFramework
//
//  Created by kai.sun on 2019/10/15.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//

import UIKit
//import GDPRAssent

class GDPRBasicAlertViewController: UIViewController {
    
    private(set) var style : GdprAssentAlertStyle
    private(set) var moreURL : URL?
    private(set) var completion : ((_ granted : Bool) -> Void)
    
    private(set) var titleView : UITextView!
    private(set) var messageView : UITextView!
    private(set) var buttonsView: UIView!
    var okButton : UIButton!
    
    private var panelView : UIView

    //MARK: lifeCycle callBack methods
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        self.view.addSubview(self.panelView)
        self.titleView = {
            let view = UITextView.init(frame: CGRect.zero)
            view.isEditable = false;
            view.isSelectable = false;
            view.isScrollEnabled = false;
            view.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            view.textAlignment = NSTextAlignment.center
            view.textColor = UIColor.black
            view.textContainerInset = UIEdgeInsets.init(top: 22, left: 10, bottom: 0, right: 10);
            return view
        }()
        self.messageView = {
            let view = UITextView.init(frame: CGRect.zero)
            view.isEditable = false;
            view.isSelectable = false;
            view.isScrollEnabled = false;
            view.font = UIFont.systemFont(ofSize: 14)
            view.textAlignment = NSTextAlignment.justified
            view.textColor = UIColor.gray
            view.textContainerInset = UIEdgeInsets.init(top: 16, left: 10, bottom: 24, right: 20);
            return view
        }()
        self.buttonsView = {
            let view = UIView.init(frame: CGRect.zero)
            return view
        }()
        
        self.panelView.addSubview(self.titleView)
        self.panelView.addSubview(self.messageView)
        self.panelView.addSubview(self.buttonsView)
        
        for subView:UIView in [self.panelView, self.titleView, self.messageView, self.buttonsView] {
            subView.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let screenSize = UIScreen.main.bounds.size
        let screenMinSize = screenSize.width < screenSize.height ? screenSize.width : screenSize.height
        let isPad = screenMinSize >= 768
        self.view.addConstraint(NSLayoutConstraint.init(item: self.panelView, attribute:NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint.init(item: self.panelView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint.init(item: self.panelView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: (isPad ? 0.5 : 0.9) * screenMinSize))
        self.view.addConstraint(NSLayoutConstraint.init(item: self.panelView , attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: self.view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 0.96, constant: 0))
        
        let panelViews : [String : UIView] = ["title":self.titleView, "message":self.messageView, "buttons":self.buttonsView]
        self.panelView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[title]-0-[message]-0-[buttons]-10-|", options: [], metrics: nil, views: panelViews))
        self.panelView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[title]-0-|", options: [], metrics: nil, views: panelViews))
        self.panelView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[message]-0-|", options: [], metrics: nil, views: panelViews))
        self.panelView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[buttons]-0-|", options: [], metrics: nil, views: panelViews))
    }

    //MARK: Public functions
    init(style:GdprAssentAlertStyle, moreURL:URL?, completion:@escaping (Bool)->Void) {
        self.style = style
        self.moreURL = moreURL
        self.completion = completion
        self.panelView = {
            let view = UIView.init(frame:CGRect.zero)
            view.backgroundColor = UIColor.white
            view.layer.cornerRadius = 14
            view.layer.masksToBounds = true
            return view
        }()
        
        super.init(nibName: nil, bundle: nil)
        
        if  Double.init(UIDevice.current.systemVersion) ?? 8 >= 8 {
            self.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        } else {
            self.modalPresentationStyle = UIModalPresentationStyle.currentContext
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func didComplete(granted : Bool) {
        self.completion(granted)
    }
    
    public func touchedReadPrivacyPolicy() {
        self.presentPrivacyPolicy()
    }
    
    public func okButtonText() -> String? {
        return nil
    }
    
    public func cancelButtonText() -> String? {
        return nil
    }
    
    //MARK: private methods
    @objc private func touchedPrivacyPolicyOK() {
        self.didComplete(granted: true)
    }
    
    @objc private func touchedPrivacyPolicyCancel() {
        self.didComplete(granted: false)
    }
    
    @objc private func touchedPrivacyPolicyClose() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func presentPrivacyPolicy() {
        let vc = UIViewController.init(nibName: nil, bundle: nil)
        vc.view.backgroundColor = UIColor.white
        
        let webView = UIWebView.init(frame: CGRect.zero)
        if self.moreURL == nil {
            return
        } else {
            webView.loadRequest(URLRequest.init(url: self.moreURL!))
        }
        
        let okButton:UIButton = {
            let button = UIButton.init(type: UIButton.ButtonType.custom)
            button.setTitleColor(UIColor.white, for: UIControl.State.normal)
            button.setTitle(self.okButtonText(), for: UIControl.State.normal)
            button.setBackgroundImage(self.okButton.backgroundImage(for: UIControl.State.normal), for: UIControl.State.normal)
            button.addTarget(self, action: #selector(touchedPrivacyPolicyOK), for: UIControl.Event.touchUpInside)
            button.layer.cornerRadius = self.okButton.layer.cornerRadius
            button.layer.masksToBounds = true
            return button
        }()
        
        let cancelButton:UIButton = UIButton.init(type: UIButton.ButtonType.custom)
        
        let closeButton:UIButton = {
            let button = UIButton.init(type: UIButton.ButtonType.system)
            button.addTarget(self, action: #selector(touchedPrivacyPolicyClose), for: UIControl.Event.touchUpInside)
            
            let layer = CAShapeLayer.init()
            layer.path = self.crossPathWithSize(size: CGSize.init(width: 16, height: 16), lineWidth: 2).cgPath
            layer.fillColor = UIColor.gray.cgColor
            button.layer.addSublayer(layer)
            button.layer.shadowColor = UIColor.white.cgColor
            button.layer.shadowOffset = CGSize.zero
            button.layer.shadowRadius = 4
            button.layer.shadowOpacity = 1
            return button
        }()
        
        for subView:UIView in [webView, closeButton, okButton, cancelButton] {
            vc.view.addSubview(subView)
            subView.translatesAutoresizingMaskIntoConstraints = false
        }
        vc.view.addConstraint(NSLayoutConstraint.init(item: closeButton, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: vc.topLayoutGuide, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 10))
        vc.view.addConstraint(NSLayoutConstraint.init(item: closeButton, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: vc.view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 10))
        let views = ["web": webView, "ok": okButton, "cancel": cancelButton]
        vc.view.addConstraint(NSLayoutConstraint.init(item: webView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: vc.topLayoutGuide, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0))
        vc.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[web]-0-|", options: [], metrics: nil, views: views))
        okButton.addConstraint(NSLayoutConstraint.init(item: okButton, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: self.okButton.bounds.size.width))
        vc.view.addConstraint(NSLayoutConstraint.init(item: okButton, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: vc.view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0))
        vc.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[web]-10-[ok(40)]-3-[cancel]", options: [], metrics: nil, views: views))
        vc.view.addConstraint(NSLayoutConstraint.init(item: cancelButton, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: vc.bottomLayoutGuide, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 3))
        
        switch self.style {
            case .Agree:
                cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
                cancelButton.contentEdgeInsets = UIEdgeInsets.init(top: 3, left: 0, bottom: 0, right: 0)
                cancelButton.setTitleColor(UIColor.gray, for: UIControl.State.normal)
                cancelButton.setTitle(self.cancelButtonText(), for: UIControl.State.normal)
                cancelButton.addTarget(self, action: #selector(touchedPrivacyPolicyCancel), for: UIControl.Event.touchUpInside)
                vc.view.addConstraint(NSLayoutConstraint.init(item: cancelButton, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: vc.view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0))
                break;
            case .Continue:
                cancelButton.addConstraint(NSLayoutConstraint.init(item: cancelButton, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 0))
                break;
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    private func crossPathWithSize(size:CGSize, lineWidth:CGFloat) -> UIBezierPath {
        let lineWidthHalf = lineWidth / 2
        let path = UIBezierPath.init()
        path.move(to: CGPoint.init(x: lineWidthHalf, y: 0))
        path.addLine(to: CGPoint.init(x: size.width / 2, y:size.height / 2 - lineWidthHalf))
        // Right-Top
        path.addLine(to: CGPoint.init(x: size.width - lineWidthHalf, y: 0))
        path.addLine(to: CGPoint.init(x: size.width, y: lineWidthHalf))
        path.addLine(to: CGPoint.init(x: size.width / 2 + lineWidthHalf, y: size.height / 2))
        // Right-Bottom
        path.addLine(to: CGPoint.init(x: size.width, y: size.height - lineWidthHalf))
        path.addLine(to: CGPoint.init(x: size.width - lineWidthHalf, y: size.height))
        path.addLine(to: CGPoint.init(x: size.width / 2, y: size.height / 2 + lineWidthHalf))
        // Left-Bottom
        path.addLine(to: CGPoint.init(x: lineWidthHalf, y: size.height))
        path.addLine(to: CGPoint.init(x: 0, y: size.height - lineWidthHalf))
        path.addLine(to: CGPoint.init(x: size.width / 2 - lineWidthHalf, y: size.height / 2))
        path.addLine(to: CGPoint.init(x: 0, y: lineWidthHalf))
        path.close()
        
        return path
    }
}
