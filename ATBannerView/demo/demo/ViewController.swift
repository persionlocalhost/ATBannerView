//
//  ViewController.swift
//  demo
//
//  Created by alex on 2024/9/8.
//

import UIKit
//import CoreMedia
//import MobileCoreServices

class ViewController: UIViewController {
//
//    private lazy var collectionView: UICollectionView = {
//        let layout = ATDragCollectionViewFlowLayout()
//        
//        layout.minimumLineSpacing = 10
//        layout.minimumInteritemSpacing = 10
//        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
////        layout.delegate = self
//        let w = (UIScreen.main.bounds.size.width - 5*10) / 4
//        layout.itemSize = CGSize(width: w, height: w)
//        let col = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        col.delegate = self
//        col.dataSource = self
//        col.backgroundColor = .white
//        return col
//    }()
//    
//    var dataSorce =  [Int]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "首页"

        
        let model1 = ATHomeBannerModel()
        model1.bannerUrl = "https://q3.itc.cn/images01/20240313/5d18f1f3b27d47ad8262bacc72642a35.jpeg"
        model1.fileType = 1
        model1.videoUrl = ""
        
        let model0 = ATHomeBannerModel()
        model0.videoUrl = "https://dh2.v.netease.com/2017/cg/fxtpty.mp4"
        model0.fileType = 2
        model0.bannerUrl = "https://burnlab-app-default.oss-accelerate.aliyuncs.com/ikier/ikier/public/test/project/1726880793163.jpg"
        
        let model2 = ATHomeBannerModel()
        model2.bannerUrl = "https://i1.hdslb.com/bfs/archive/18d674f89850c59a2371894a9c432ff6caf6586f.jpg"
        model2.fileType = 1
        model2.videoUrl = ""
        
        let model3 = ATHomeBannerModel()
        model3.videoUrl = "https://vd2.bdstatic.com/mda-ibtfrfq2agf2216r/hd/mda-ibtfrfq2agf2216r.mp4?v_from_s=tc_videoui_4135&auth_key=1611284615-0-0-e2902fb9f17bb70ca87e881a32a37a27&bcevod_channel=searchbox_feed&pd=1&pt=3&abtest="
        model3.fileType = 2
        model3.bannerUrl = "https://pic.rmb.bdstatic.com/bjh/down/606d54ffe1b7dfab5ed1235959d69c9e.jpeg"
        
        let model4 = ATHomeBannerModel()
        model4.bannerUrl = "https://pic.rmb.bdstatic.com/bjh/down/606d54ffe1b7dfab5ed1235959d69c9e.jpeg"
        model4.fileType = 1
        model4.videoUrl = ""
        
        let model5 = ATHomeBannerModel()
        model5.bannerUrl = "https://pic.rmb.bdstatic.com/bjh/down/606d54ffe1b7dfab5ed1235959d69c9e.jpeg"
        model5.fileType = 2
        model5.videoUrl = "https://vd4.bdstatic.com/mda-jg3pp0t2atgbjh5d/sc/mda-jg3pp0t2atgbjh5d.mp4?auth_key=1601173151-0-0-260509c2cb8752744f1c2b5652747ad1&bcevod_channel=searchbox_feed&pd=1&pt=3"
        
        let  banners = [model1, model0, model2, model3, model4, model5]
        updateBanner(banners)
    
      
    }
    
    // banner
    public func updateBanner(_ banners: [ATHomeBannerModel]) {
        
        // 思路：无限循环的话
        // 1、需要将第0个同时放在第0个和最后一个
        // 2、需要将最后一个放在第0个
        
        // 3、因为可能有视频，那么单独给个view来同时处理视频和图片
        // 4、如果只是图片，那么直接传图片即可
        // 视频可能不是第一索引值，
        var originalArray = [ATHomeBannerModel]()
        var lists = [ATBannerPlayerView]()
        var firstArr = [ATBannerPlayerView]()
        var isContainsVideo = false
        var urls = [String]()
        var images = [String]()
        
        // 判断是否包含视频
        for model in banners {
            if model.fileType == 2 {
                urls.append(model.videoUrl)
                isContainsVideo = true
                originalArray.append(model)
            }else {
                originalArray.append(model)
                images.append(model.bannerUrl)
            }
        }
       
        let frame = CGRect(x: 0, y: 200, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.width * (9 / 16))
        if isContainsVideo == true {
            for (index, item) in originalArray.enumerated() {
                let view = ATBannerPlayerView(frame: frame)
                view.updateBannerContent(index, (item.fileType == 2 ? item.videoUrl : item.bannerUrl), item.bannerUrl, urls, item.fileType)
                lists.append(view)
                if index == 0 {
                    let view0 = ATBannerPlayerView(frame: frame)
                    view0.updateBannerContent(index, (item.fileType == 2 ? item.videoUrl : item.bannerUrl), item.bannerUrl, urls, item.fileType)
                    firstArr.append(view0)
                }else if index == banners.count - 1 {
                    let view4 = ATBannerPlayerView(frame: frame)
                    view4.updateBannerContent(index, (item.fileType == 2 ? item.videoUrl : item.bannerUrl), item.bannerUrl, urls, item.fileType)
                    lists.insert(view4, at: 0)
                }
            }

            lists.append(firstArr.first!)
            
            let bannerView =  ATBannerView(frame: frame, bannerViews: lists, banners: banners, timeInterval: 6)
            bannerView.backgroundColor = UIColor(hexString: "#F2F2F2")
            self.view.addSubview(bannerView)
        }else {
            let bannerView = ATBannerView(frame: frame, images: images, timeInterval: 6)
            bannerView.backgroundColor = UIColor(hexString: "#F2F2F2")
            self.view.addSubview(bannerView)
        }
    }

    // {p:{}, p: {}}
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        
//     
////        var cmdArr = [[String:String]]()
////        var xDict = [String:String]()
////        var yDict = [String:String]()
////        for i in 0..<8 {
////            let model = ATCmdArr(x: 0.266, y: 1.90)
////            xDict = ["x":"\(model.x)"]
////            yDict = ["y":"\(model.y)"]
////            let cmd = ["points_\(i)" : "{\(xDict),\(yDict)}"]
////            cmdArr.append(cmd)
////        }
////        
////        if let jsonData = try? JSONSerialization.data(withJSONObject: cmdArr, options: []) {
////            // 成功转换，将JSON数据转换为String以便打印或查看
////            if let jsonString = String(data: jsonData, encoding: .utf8) {
////                
////                let cmdMode = ATCmdMode(cmdArray: jsonString)
////                print(jsonString)
////                
////                
////            }
////        } else {
////            print("无法将数组转换为JSON")
////        }
//        
////        
////       let layer = ATProjectLayersModel(layerName: "alex", layerColor: "#cccccc", materialName: "世界和平", materialId: "13d", engraveParamFlag: 12, thicknessParam: 32, layerId: 1, elementType: 13, mode: 1, scan: 13, gasAssisted: 133, processNum: 133, direction: 133, lineSpace: 12.3, startDown: 1, autoDown: 2, power: 13, speed: 11, output: true, show: true, cutFlag: false, embossFlag: false, cleanSpeed: 13, cleanPower: 12, overScanFlag: false)
////        
////        // 数组
////        let item = ATProjectItemsModel(id: "djq", type: 1, x: 202, y: 30, z: 100, angle: 34, lastAngle: 19, lineType: 10, layer: 1, color: "DDFKKD", text: "YEXY", lastText: "JDLAJ", fontSize: 12, lastFontSize: 12, initFontSize: 2, fontFamily: "RED", cmdArray: "", sceneY: 400, image: "DADKA", width: 34, height: 34, filter: 7, blur: 17, gray: 78, bright: 78, contrast: 7, whiteBalance: 7, inverse: true, imgFormat: "sjaisj")
////        
////    
////        let project = ATProjectModel(layers: [layer], canvasName: "Alexander", items: [item])
////        do{
////            let encoder = JSONEncoder()
////            encoder.outputFormatting = .prettyPrinted
////            let jsonData = try encoder.encode(project)
////            if let json = String(data: jsonData, encoding: .utf8) {
////                print("JSON: \(json)")
////            }
////            
////        }catch {
////            print(error.localizedDescription)
////        }
//        
//       
//    }

//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//
//        // 将JSON字符串转换为Data
//        let jsonString = """
//        {
//            "cmdArray": {
//                "points_0": {"x": 75.57807782274, "y": 74.17848378899215},
//                "points_1": {"x": 149.0567645945, "y": 148.3569675779843},
//                "points_2": {"x": 75.57807782276, "y": 74.17848378899215},
//                "points_3": {"x": 149.0567645947, "y": 148.3569675779843},
//                "points_4": {"x": 75.57807782278, "y": 74.17848378899215},
//                "points_5": {"x": 149.0567645949, "y": 148.3569675779843},
//            }
//        }
//        """
//
//        guard let jsonData = jsonString.data(using: .utf8) else {
//            fatalError("Unable to convert JSON string to Data")
//        }
//
//
//        if let points = ATManager.share.parseJSON(jsonData: jsonData) {
////            print("数组：\(points)")
//
//            let points = ATManager.share.parseCmdArr(pointsDict: points)
//            for point in points {
//                print("\(point.x) -- \(point.y)")
//            }
//
//        }else {
//
//            print("Failed to parse JSON")
//        }
//
//
//
//
//
////        self.navigationController?.pushViewController(ATHomeViewController(), animated: true)
//    }

}
//
//
//extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource  {
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return self.dataSorce.count
//    }
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(ATDragCell.classForCoder()), for: indexPath) as! ATDragCell
//        
//        cell.update(self.dataSorce[indexPath.item])
//        
//        return cell
//        
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
//        return true
//    }
//    
//    // 数据源更新
//    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//        // 移动前的模型
//        let temp = self.dataSorce[sourceIndexPath.item]
//        self.dataSorce.remove(at: sourceIndexPath.item)
//        self.dataSorce.insert(temp, at: destinationIndexPath.item)
//    }
//    
//}
//
//
//class ATDragCell: UICollectionViewCell {
//    
//    private var label: UILabel?
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        self.contentView.backgroundColor = UIColor.randomColor
//        label = UILabel()
//        self.contentView.addSubview(label!)
//        label!.snp.makeConstraints { make in
//            make.centerX.centerY.equalTo(self.contentView)
//        }
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    func update(_ index: Int) {
//        label?.text = "第\(index)行"
//    }
//}
//
//
//extension ViewController: UIDocumentPickerDelegate {
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        guard let url = urls.first else { return }
//     
//      
//     
//    }
//    
//    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
//        
//    }
//    
//}
