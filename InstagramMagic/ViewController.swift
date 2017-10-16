//
//  ViewController.swift
//  InstagramTest
//
//  Created by Jerry on 2017/10/13.
//  Copyright © 2017年 Jerry. All rights reserved.
//

import UIKit
import Alamofire
import SDWebImage
import Eureka
import SnapKit
import AVKit
import MBProgressHUD
import YYCategories
import Photos
import MJRefresh

class DataModel: NSObject {
    var title: String?
    var type: Int = -1 //0 GraphImage 单图, 1 GraphSidecar 图集, 2 GraphVideo 视频
    
    var imageGroup: [String] = []
    
    var video: String?
    var videoDisplay: String?
}

class ViewController: FormViewController {
    
    let jsonRex = "<script.*?type=\"text/javascript\">window._sharedData.*?=(.*?);</script>"
    
    var data: DataModel?
    
    var popupController:CNPPopupController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("APPTitle", comment: "Instagram魔术手")
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Help", style: .done, target: self, action: #selector(ViewController.pushHelpVC))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "about"), style: .done, target: self, action: #selector(ViewController.popAboutMe))
        
        self.tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: {
            //读取粘贴板
            NSLog("\(UIPasteboard.general.string ?? "")")
            guard (self.getRex(str: UIPasteboard.general.string ?? "", pattern: "[a-zA-z]+://instagram.com[^\\s]*").first != nil) else {
                self.tableView.mj_header.endRefreshing()
                let hud = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
                hud.mode = .text
                hud.label.text = NSLocalizedString("noInstagramLinkTitle", comment: "非正确Instagram链接")
                hud.detailsLabel.text = NSLocalizedString("noInstagramLinkSubTitle", comment: "Instagram中复制链接，再来本APP中刷新")
                hud.hide(animated: true, afterDelay: 3)
                return
            }
            self.loadURL(url: UIPasteboard.general.string!)
        })
        
        self.tableView.mj_header.beginRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc private func pushHelpVC() {
        let vc = HelpViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func loadURL(url: String) {
        
        Alamofire.request(url).responseJSON { response in
            
            self.tableView.mj_header.endRefreshing()
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                
                guard utf8Text.utf8.count > 0 else{
                    NSLog("数据获取失败")
                    return
                }
                
                //转成json
                guard var jsonString = self.getRex(str: utf8Text, pattern: self.jsonRex).first else { return }
                
                let scanner = Scanner(string: jsonString)
                var _jsonString: NSString?
                
                scanner.scanUpTo("{", into: nil)
                scanner.scanUpTo(";</script>", into: &_jsonString)
                guard _jsonString != nil else { return }
                jsonString = _jsonString! as String
                
                let jsonData:Data = jsonString.data(using: String.Encoding.utf8)!
                
                guard let jsonDict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) else { return }
                
                let model = DataModel()
                
                //获取title
                guard let entry_data = (jsonDict as! NSDictionary)["entry_data"] as? NSDictionary else { return }
                guard let PostPage = entry_data["PostPage"] as? [NSDictionary] else { return }
                guard PostPage.count > 0 else { return }
                guard let graphql = PostPage.first!["graphql"] as? NSDictionary else { return }
                guard let shortcode_media = graphql["shortcode_media"] as? NSDictionary else { return }
                guard let edge_media_to_caption = shortcode_media["edge_media_to_caption"] as? NSDictionary else { return }
                guard let edges = edge_media_to_caption["edges"] as? [NSDictionary] else { return }
                guard edges.count > 0 else { return }
                guard let node = edges.first!["node"] as? NSDictionary else { return }
                guard let text = node["text"] as? String else { return }
                
                model.title = text
                
                //判断图片还是视频
                guard let type = shortcode_media["__typename"] as? String else{
                    NSLog("获取类型失败")
                    return
                }
                
                //单图
                if (type == "GraphImage"){
                    model.type = 0
                    guard let imgURL = shortcode_media["display_url"] as? String else { return }
                    model.imageGroup.append(imgURL)
                    self.data = model
                    self.reloadTableView()
                    return
                }
                
                //图集
                if (type == "GraphSidecar"){
                    model.type = 1
                    guard let edge_sidecar_to_children = shortcode_media["edge_sidecar_to_children"] as? NSDictionary else { return }
                    guard let edges2 = edge_sidecar_to_children["edges"] as? [NSDictionary] else { return }
                    
                    for _edges2 in edges2 {
                        guard let node2 = _edges2["node"] as? NSDictionary else { return }
                        guard let display_url = node2["display_url"] as? String else { return }
                        model.imageGroup.append(display_url)
                    }
                    self.data = model
                    self.reloadTableView()
                    return
                }
                
                //视频
                if (type == "GraphVideo"){
                    model.type = 2
                    
                    guard let imgURL = shortcode_media["display_url"] as? String else { return }
                    model.videoDisplay = imgURL
                    //model.imageGroup.append(imgURL)
                    
                    guard let video_url = shortcode_media["video_url"] as? String else { return }
                    model.video = video_url
                    
                    self.data = model
                    self.reloadTableView()
                    return
                }
                
            }
        }
    }
    
    private func getRex(str: String, pattern: String) -> [String] {
        var returnValue: [String] = []
        // 使用正则表达式一定要加try语句
        do {
            // - 1、创建规则
            //let pattern = pattern
            // - 2、创建正则表达式对象
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            // - 3、开始匹配
            let res = regex.matches(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, str.characters.count))
            // 输出结果
            returnValue = res.map({(str as NSString).substring(with: $0.range)})
        }
        catch {
            print(error)
        }
        return returnValue
    }
    
    
    private func reloadTableView() {
        
        guard self.data != nil else { return }
        
        form.removeAll()
        
        form +++ Section(self.data?.title ?? "")
        
        //图片
        if self.data!.type == 0 || self.data!.type == 1 {
            for img in self.data!.imageGroup {
                form +++ Section()
                    <<< ImageRow(){
                        $0.value = img
                        }.onCellSelection({ (cell, row) in
                            let vc = PhotoVC()
                            vc.imageURL = img
                            self.present(vc, animated: false, completion: nil)
                        })
                    
                    <<< ButtonRow(){
                        $0.title = NSLocalizedString("saveToPhoto", comment: "保存到相册")
                        }.onCellSelection({ (cell, row) in
                            
                            let hud = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
                            hud.mode = .annularDeterminate
                            hud.label.text = NSLocalizedString("imgDownloading", comment: "图片下载中")
                            
                            Alamofire.request(img).responseData { response in
                                
                                if let data = response.result.value {
                                    guard let image = UIImage(data: data) else {
                                        hud.hide(animated: true)
                                        return
                                    }
                                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                                    NSLog("保存成功")
                                    let _img = UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)
                                    let _imgView = UIImageView(image: _img)
                                    hud.customView = _imgView
                                    hud.mode = .customView
                                    hud.label.text = NSLocalizedString("savedSuccessfully", comment: "保存成功")
                                }
                                hud.hide(animated: true, afterDelay: 0.6)
                                }
                                .downloadProgress { progress in
                                    print("Download Progress: \(progress.fractionCompleted)")
                                    hud.progress = Float(progress.fractionCompleted)
                            }
                        })
                        .cellSetup { cell, row in
                            cell.imageView?.image = UIImage(named: "download_image")
                        }
                        .cellUpdate({ (cell, row) in
                            cell.textLabel?.textAlignment = .left
                            cell.textLabel?.textColor = UIColor(red: 12/255.0, green: 150/255.0, blue: 219/255.0, alpha: 1)
                        })
            }
        }
        
        //视频
        if self.data!.type == 2 {
            form +++ Section()
                <<< VideoRow(){
                    $0.value = self.data!.videoDisplay
                    }.onCellSelection({ (cell, row) in
                        let videoURL = URL(string: self.data!.video!)!
                        let player = AVPlayer(url: videoURL)
                        let playerVC = AVPlayerViewController()
                        playerVC.player = player
                        self.present(playerVC, animated: true) {
                            playerVC.player?.play()
                        }
                    })
            
            form +++ Section()
                <<< ButtonRow(){
                    $0.title = NSLocalizedString("saveToPhoto", comment: "保存到相册")
                    }.onCellSelection({ (cell, row) in
                        
                        
                        let hud = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
                        hud.mode = .annularDeterminate
                        hud.label.text = NSLocalizedString("videoDownloading", comment: "视频下载中")
                        
                        Alamofire.request(self.data!.video!).responseData { response in
                            hud.hide(animated: true)
                            guard let data = response.result.value else { return }
                            
                            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
                            let filePath = "\(documentsPath)/tempFile.mp4"
                            
                            do {
                                try data.write(to: URL(fileURLWithPath: filePath))
                            }
                            catch {
                                print("写入数据错误")
                                return
                            }
                            
                            PHPhotoLibrary.requestAuthorization
                                { (status) -> Void in
                                    switch (status)
                                    {
                                    case .authorized:
                                        // Permission Granted
                                        print("Write your code here")
                                        self.saveVideo(path: filePath)
                                    case .denied:
                                        // Permission Denied
                                        print("User denied")
                                    default:
                                        print("Restricted")
                                    }
                            }
                            }
                            .downloadProgress { progress in
                                print("Download Progress: \(progress.fractionCompleted)")
                                hud.progress = Float(progress.fractionCompleted)
                        }
                    })
        }
    }
    
    func saveVideo(path: String) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(string: path)!)
        }) { saved, error in
            
            dispatch_async_on_main_queue({
                let hud = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
                if saved {
                    let _img = UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)
                    let _imgView = UIImageView(image: _img)
                    hud.customView = _imgView
                    hud.mode = .customView
                    hud.label.text = NSLocalizedString("savedSuccessfully", comment: "视频保存成功")
                }else{
                    hud.label.text = NSLocalizedString("saveFailed", comment: "视频保存失败")
                }
                hud.hide(animated: true, afterDelay: 1.5)
            })
            
        }
    }
}

class PhotoVC: UIViewController {
    
    var imageURL: String?
    var img: UIImage?
    
    let imgView = UIImageView(frame: UIScreen.main.bounds)
    
    var lastScaleFactor : CGFloat! = 1  //放大、缩小
    var netTranslation : CGPoint = CGPoint(x: 0, y: 0) //平移
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(imgView)
        self.imgView.contentMode = .scaleAspectFit
        self.imgView.isUserInteractionEnabled = true
        
        //点击手势
        let tapGestureRecognizer = UITapGestureRecognizer { (sender) in
            self.dismiss(animated: false, completion: nil)
        }
        
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
        //捏合手势
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(PhotoVC.pinchDid(pinch:)))
        imgView.addGestureRecognizer(pinch)
        
        //拖动手势
        //let pan = UIPanGestureRecognizer(target: self, action: #selector(PhotoVC.panDid(pan:)))
        //pan.maximumNumberOfTouches = 1
        //imgView.addGestureRecognizer(pan)
        
        if imageURL != nil {
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.mode = .annularDeterminate
            imgView.sd_setImage(with: URL(string: imageURL!), placeholderImage: nil, options: .refreshCached, progress: { (received, expected, url) in
                hud.progress = Float(received) / Float(expected)
            }, completed: { (img, error, type, url) in
                guard error == nil else { return }
                self.img = img
                hud.hide(animated: true)
            })
        }
        
    }
    
    //捏合手势
    @objc func pinchDid(pinch:UIPinchGestureRecognizer) {
        print(pinch.scale)//打印捏合比例
        
        let factor = pinch.scale
        if factor > 1{
            //图片放大
            imgView.transform = CGAffineTransform(scaleX: lastScaleFactor+factor-1, y: lastScaleFactor+factor-1)
        }else{
            //缩小
            imgView.transform = CGAffineTransform(scaleX: lastScaleFactor*factor, y: lastScaleFactor*factor)
        }
        //状态是否结束，如果结束保存数据
        if pinch.state == UIGestureRecognizerState.ended{
            if factor > 1{
                lastScaleFactor = lastScaleFactor + factor - 1
            }else{
                lastScaleFactor = lastScaleFactor * factor
            }
        }
        
        //print(pinch.velocity)//打印捏合速度
    }
    
    //拖动手势
    @objc func panDid(pan:UIPanGestureRecognizer) {
        //得到拖的过程中的xy坐标
        let translation : CGPoint = pan.translation(in: imgView)
        //平移图片CGAffineTransformMakeTranslation
        imgView.transform = CGAffineTransform(translationX: netTranslation.x+translation.x, y: netTranslation.y+translation.y)
        if pan.state == UIGestureRecognizerState.ended{
            netTranslation.x += translation.x
            netTranslation.y += translation.y
        }
    }
}

public class ImageCell: Cell<String>, CellType {
    
    open let img = UIImageView()
    
    public override func setup() {
        super.setup()
        
        self.height =  { UIScreen.main.bounds.width }
        
        self.textLabel?.textColor = .clear
        self.detailTextLabel?.textColor = .clear
        self.selectionStyle = .none
        
        self.contentView.addSubview(self.img)
        
        self.img.layer.masksToBounds = true
        self.img.layer.cornerRadius = 2
        
        self.img.contentMode = .scaleAspectFit
        
        //AutoLayout
        self.img.snp.makeConstraints { (make) in
            make.edges.equalTo(UIEdgeInsetsMake(8, 8, 8, 8))
        }
    }
    
    public override func update() {
        super.update()
        if row.value != nil {
            self.img.sd_setImage(with: URL(string: row.value ?? ""), placeholderImage: nil, options: .lowPriority)
        }
    }
}

public final class ImageRow: Row<ImageCell>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}


public class VideoCell: Cell<String>, CellType {
    
    private let img = UIImageView()
    let playView = UIImageView(image: #imageLiteral(resourceName: "player_play_big"))
    
    public override func setup() {
        super.setup()
        
        self.height =  { UIScreen.main.bounds.width }
        
        self.textLabel?.textColor = .clear
        self.detailTextLabel?.textColor = .clear
        self.selectionStyle = .none
        
        self.contentView.addSubview(self.img)
        
        self.img.layer.masksToBounds = true
        self.img.layer.cornerRadius = 2
        
        //AutoLayout
        self.img.snp.makeConstraints { (make) in
            make.edges.equalTo(UIEdgeInsetsMake(8, 8, 8, 8))
        }
        
        self.contentView.addSubview(playView)
        playView.snp.makeConstraints { (make) in
            make.center.equalTo(self.img.snp.center)
        }
    }
    
    public override func update() {
        super.update()
        if row.value != nil {
            self.img.sd_setImage(with: URL(string: row.value ?? ""), placeholderImage: nil, options: .lowPriority)
        }
    }
}

public final class VideoRow: Row<VideoCell>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}
