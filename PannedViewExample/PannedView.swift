//
//  PannedView.swift
//  PannedViewExample
//
//  Created by Aleksey on 17.06.2022.
//

import Foundation
import UIKit

public class PannedView:UIView {
    private var animateViewStartTransform:CGAffineTransform?
    private var prevMoveDirection:Int = 0 // 1 - up 2 - down
    private var minSizeToDropDown:CGFloat = 100
    private static let HEIGHT_SPACE:CGFloat = 16
    
    private weak var recognizer:UIPanGestureRecognizer?
    
    public var onViewAnimateFn:((CGAffineTransform) -> Void)?
    
    public weak var delegate:PannedViewDelegate?
    var isLoaded:Bool = false
    weak var animateView:UIView?
    
    var canDrag:Bool = true {
        didSet {
            updateRecognizer()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    private func updateRecognizer() {
        
        if (canDrag) {
            if (recognizer != nil) {
                return
            }
            let recognizer = UIPanGestureRecognizer(target: self, action:  #selector(wasDragged))
            self.addGestureRecognizer(recognizer)
            self.recognizer = recognizer
        } else {
            if let recognizer = self.recognizer {
                self.removeGestureRecognizer(recognizer)
            }
        }
    }
    
    private func setup() {
        updateRecognizer()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if !isLoaded {
            isLoaded = true
            alpha = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {[weak self] in
                if let ss = self {
                    ss.setupAnimation()
                }
                
            })
            
        }
    }
    
    private func setupAnimation() {
        
        weak var weakSelf = self
        var transformHeight:CGFloat = 0
        if let rect1 = self.globalFrame, let rect2 = animateView?.globalFrame, rect2.intersects(rect1) {
            transformHeight = rect1.minY - rect2.maxY - PannedView.HEIGHT_SPACE
        }
        if (transformHeight == 0) { // NOT INTERSECTS
            animateView = nil
        }
        let transaform =  CGAffineTransform(translationX: 0, y: frame.height)
        self.transform = transaform
        animateViewStartTransform = transformHeight != 0 ? CGAffineTransform(translationX: 0, y: transformHeight) : nil
        UIView.animate(withDuration: 0.25, delay: 0, animations: {
            weakSelf?.alpha = 1
            weakSelf?.transform = .identity
            
            weakSelf?.onViewAnimateFn?(transaform)
            
            if let t = weakSelf?.animateViewStartTransform {
                
                weakSelf?.animateView?.transform = t
//                weakSelf?.onViewAnimateFn?(t)
            }
        }, completion: {_ in
            
        })
    }
    
    @objc func wasDragged(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizer.State.began || gestureRecognizer.state == UIGestureRecognizer.State.changed {

            let translation = gestureRecognizer.translation(in: self)
            var newPointY = transform.ty + translation.y
            prevMoveDirection = translation.y < 0 ? 1 : translation.y == 0 ? 0 : -1
            
            self.layer.removeAllAnimations()
            if newPointY < 0 {
                newPointY = 0
            }
            self.transform.ty = newPointY
            
            var transform = self.transform
            transform.ty = self.frame.height - transform.ty
            onViewAnimateFn?(transform)

            if var transform = animateView?.transform, newPointY != 0 {
                
                transform.ty += translation.y
                var currentSpace:CGFloat = 0
                if let rect1 = self.globalFrame, let rect2 = animateView?.globalFrame {
                    currentSpace = rect1.minY - rect2.maxY
                }
                let dif = PannedView.HEIGHT_SPACE - currentSpace
                
                transform.ty -= dif
                if (transform.ty <= 0) {
                    animateView?.transform = transform
                    
//                    onViewAnimateFn?(transform)
                }
            }
            
            gestureRecognizer.setTranslation(CGPoint.zero, in: self)
        } else if gestureRecognizer.state == UIGestureRecognizer.State.ended {
            
            self.layer.removeAllAnimations()
            
            let needClose:Bool = (prevMoveDirection == -1 && ((self.transform.ty  > minSizeToDropDown) || gestureRecognizer.velocity(in: self).y > 500)) ? true : false
            if (needClose) {
                closeAnimated()
            } else {
                revertToOpenAnimated()
            }
            
        }
    }
    public func closeAnimated() {
        
        let transform = CGAffineTransform(translationX: 0, y: self.frame.size.height)
        UIView.animate(withDuration: 0.5) {[weak self] in
            self?.transform = transform
            self?.animateView?.alpha = 0
            self?.animateView?.transform = .identity
            self?.onViewAnimateFn?(.identity)
            
        } completion: {[weak self] res in
            if (res) {
                self?.delegate?.pannedViewClosed()
            }
        }
    }
    
    public func openView() {
        revertToOpenAnimated()
    }
    
    private func revertToOpenAnimated() {
        var transform = self.transform
        transform.ty = self.frame.height
        UIView.animate(withDuration:0.5, delay: 0.01, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5,options: [],
         animations: {[weak self] in
            if let ss = self {
                ss.transform = .identity
                self?.onViewAnimateFn?(transform)
                
                if let transform  = ss.animateViewStartTransform {
                    ss.animateView?.transform = transform
                }
            }
        })
    }
}

public protocol PannedViewDelegate:AnyObject {
    func pannedViewClosed()
}

fileprivate extension UIView {
    
    var globalFrame: CGRect? {
        let rootView = UIApplication.shared.keyWindow?.rootViewController?.view
        return self.superview?.convert(self.frame, to: rootView)
    }
}
