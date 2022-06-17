//
//  ViewController.swift
//  PannedViewExample
//
//  Created by Aleksey on 17.06.2022.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var pannedView: PannedView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        pannedView.delegate = self
        pannedView.roundCorners(corners: [.topLeft,.topRight], radius: 12)
    }

    @IBAction func closeBtnClicked(_ sender: Any) {
        pannedView.closeAnimated()
    }
    
}

extension ViewController: PannedViewDelegate {
    func pannedViewClosed() {
        print("pannedViewClosed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {[weak self] in
            self?.pannedView.openView()
        })
    }
}
