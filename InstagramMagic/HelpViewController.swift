//
//  HelpViewController.swift
//  InstagramMagic
//
//  Created by Jerry on 2017/10/16.
//  Copyright © 2017年 Jerry. All rights reserved.
//

import UIKit
import Eureka

class HelpViewController: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        form +++ Section(NSLocalizedString("help.1", comment: ""))
            <<< ImageRow(){
                $0.cell.img.image = UIImage(named: "help1")
                }.onCellSelection({ (cell, row) in
                    let vc = PhotoVC()
                    vc.imgView.image = UIImage(named: "help1")
                    self.present(vc, animated: false, completion: nil)
                })
        
        form +++ Section(NSLocalizedString("help.2", comment: ""))
            <<< ImageRow(){
                $0.cell.img.image = UIImage(named: "help2")
                }.onCellSelection({ (cell, row) in
                    let vc = PhotoVC()
                    vc.imgView.image = UIImage(named: "help2")
                    self.present(vc, animated: false, completion: nil)
                })
        
        form +++ Section(NSLocalizedString("help.3", comment: ""))
            <<< ImageRow(){
                $0.cell.img.image = UIImage(named: "help3")
                }.onCellSelection({ (cell, row) in
                    let vc = PhotoVC()
                    vc.imgView.image = UIImage(named: "help3")
                    self.present(vc, animated: false, completion: nil)
                })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
