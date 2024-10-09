##### 背景

无限图片轮播器我已经记不清自己写了多少次了，不管是用 ```UIScrollView + Timer ```方式实现，还是```UICollectionView + Timer```方式实现，其本质是一样的，```核心点都是: 让第一个Item重复添加到最后位置，最后个Item重复添加为第0个位置。比如：轮播数组的顺序本来是 [0, 1, 2]， 需要将数组改为[2, 0, 1, 2, 0]，传入自定义bannerView```。

- 实现目标：
轮播器需要兼容视频和图片共存，当显示视频时，移除定时器，要求视频正常播放完成后自动到下一页，若下一页是图片开启定时器，6秒后划到下一页，手动拖动轮播器，也需要判断是否是视频页，若是视频页则关闭定时器，若是图片页则正常在6秒后跳转（滑动的时候需要移除定时器，所以当手势完成后再判断是否是视频页，若是不要开启定时器。若是图片，则开启定时器）。

- 实现效果：
![banner](https://github.com/user-attachments/assets/07125e25-ce5c-4f0d-a18f-e8c9a96c57eb)


- 实现步骤：

- 1、提供几种实现轮播器的方式，纯图片轮播、视频和图片共存轮播，纯视频轮播
```objc
   // 方式一 : 视频和图片共存，纯视频，这里传入的数组是一个单独的View数组。
    public init(frame: CGRect, bannerViews: [ATBannerPlayerView], banners: [ATHomeBannerModel], timeInterval: CGFloat, isVideo: Bool? = false) {
        super.init(frame: frame)
        NotificationCenter.default.addObserver(self, selector: #selector(restart(_:)), name: Notification.Name(rawValue: NotificationNameHomeBannerVideoStopName), object: nil)
        self.numberOfPages = bannerViews.count - 2
        self.timeInterval = timeInterval
        self.bannerViews = bannerViews
        self.banners = banners
        self.isOnlyImages = false
        size = Size(width: frame.size.width, height: frame.size.height)
        setupBannerView()
        setupContentView()
    }
    
    // 方式二 纯图片
    public init(frame: CGRect, images: [String], timeInterval: CGFloat) {
        super.init(frame: frame)
        self.numberOfPages = images.count
        self.timeInterval = timeInterval
        size = Size(width: frame.size.width, height: frame.size.height)
        setupBannerView()
        setupBannerContent(images)
        setupTimer()
    }
    
    // 方式三 纯图片
    public init(frame: CGRect, images: [String], placeholderImage placeholder: UIImage?, timeInterval: CGFloat) {
        super.init(frame: frame)
        self.placeholderImage = placeholder
        self.numberOfPages = images.count
        self.timeInterval = timeInterval
        size = Size(width: frame.size.width, height: frame.size.height)
        setupBannerView()
        setupBannerContent(images)
        setupTimer()
    }
```

- 2、添加轮播内容，这里将内容添加到```UIScrollView```上，因为要实现手势左右滑动，使用它则是最简便的方式。
```objc

// 这种方式是添加View数组（视频和图片共存）
 fileprivate func setupContentView() {
        if self.bannerViews.count <= 0 {
            return
        }
        for i in 0..<self.bannerViews.count {
            let playerView = self.bannerViews[i]
            playerView.frame = CGRect(x: CGFloat(i) * size.width, y: 0, width: size.width, height: size.height)
            playerView.backgroundColor = .clear
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
            playerView.addGestureRecognizer(tap)
            self.urls.append(playerView.urlString)
            self.images.append(playerView.imageString)
            self.scrollView.addSubview(playerView)
        }
        self.currentBannerView = self.bannerViews.first!
        if self.currentBannerView.isVideo == true {
            removeTimer()
        }else {
            setupTimer()
        }
        setupScrollView(count: self.bannerViews.count)
    }

// 这种方式是纯图片
    fileprivate func setupBannerContent(_ images: [String]) {
        let count = images.count + 2
        var index = 0
        while index < count {
            var tempIndex = index - 1
            if index == count - 1 {
                tempIndex = 0
            }else if index == 0 {
                tempIndex = count - 3;
            }
            let frame = CGRect(x: CGFloat(index) * size.width, y: 0, width: size.width, height: size.height)
            let imageView = UIImageView(frame: frame)
            imageView.contentMode = .scaleToFill
            if images[tempIndex].hasPrefix("http") {
                imageView.sd_setImage(with: URL(string: images[tempIndex]), placeholderImage: UIImage(named: ""))
            }else {
                imageView.image = UIImage(named: images[tempIndex])
            }
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
            imageView.addGestureRecognizer(tap)
            self.scrollView.addSubview(imageView)
            index += 1
        }
        setupScrollView(count: count)
    }

```

- 3、添加定时器，要求6秒后轮播到下一页
```objc
// 因为在轮播过程中，定时器可能会移除后再添加，所以想做了一层是否为空的判断
    fileprivate func setupTimer() {
        if self.timer == nil {
            self.timer = Timer(timeInterval: self.timeInterval, target: self, selector: #selector(nextBannerAction), userInfo: nil, repeats: true)
            RunLoop.main.add(self.timer!, forMode: .common)
        }
    }
```

- 4、事件交互相关
```objc
    // MARK:  定时器执行到下一页
    @objc func nextBannerAction() {
        let page = self.pageControl.currentPage + 2
        self.scrollView.setContentOffset(CGPoint(x: CGFloat(page) * size.width, y: 0), animated: true)
        if self.isOnlyImages == false{
            let view = self.bannerViews[page]
            self.currentBannerView = view
            if view.isVideo == true {
                removeTimer()
                ATBannerPlayerView.share.rePlay()
            } else {
                setupTimer()
            }
        }
    }
    // MARK:  手势左右滑动
    @objc func swipeBannerAction() {
        let page = self.pageControl.currentPage + 1
        if self.isOnlyImages == false  {
            let view = self.bannerViews[page]
            self.currentBannerView = view
            if view.isVideo == true {
                removeTimer()
                ATBannerPlayerView.share.rePlay()
            }else {
                setupTimer()
            }
        }
    }
```

- 3、轮播内容的传入, 既然传入的数组是View类型的数组，每个view就是一页轮播。单独的View就是一个图片或者视频播放器。
```objc
 deinit {
        NotificationCenter.default.removeObserver(self)
        for pla in playerLayers {
            pla.removeFromSuperlayer()
        }
        print("banner 释放了")
    }

    public func play(_ urlString: String?, _ imageName: String, _ index: Int) {
        if let urlPath = urlString {
            if urlPath.hasPrefix("http") { // 网络视频
                guard let url = URL(string: urlPath) else {
                    return
                }
                playerLayer(url, imageName, index)
                return
            }
        
            if #available(iOS 16.0, *) { // 本地视频
                let url = URL.init(filePath: urlPath)
                playerLayer(url, imageName, index)
            }else {
                let url = URL(fileURLWithPath: urlPath)
                playerLayer(url, imageName, index)
            }
        }
    }
    
    private func isAvaiableUrl(_ url: URL) -> Bool {
        let asset = AVAsset(url: url)
        return asset.isPlayable
    }
    
    private func playerLayer(_ url: URL, _ imageName: String, _ index: Int) {
        coverImageView.isUserInteractionEnabled = true
        coverImageView.frame = self.bounds
        coverImageView.sd_setImage(with: URL(string: imageName), placeholderImage: UIImage(named: "placeholderImageView"))
        coverImageView.contentMode = .scaleToFill
        self.addSubview(coverImageView)
        
        stop()
        let item = AVPlayerItem(url: url)
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = true
        player.actionAtItemEnd = .none
        player.replaceCurrentItem(with: item)
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = self.bounds
        self.layer.addSublayer(playerLayer)
        playerLayers.append(playerLayer)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [weak self] Notification in
            guard let self = self else { return }
            self.player.seek(to: CMTime.zero)
            self.rePlay()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationNameHomeBannerVideoStopName), object: nil, userInfo: ["currentIndex" : self.currentIndex])
        }
        self.rePlay()
    }

    
    public func rePlay() {
        if player.timeControlStatus == .paused {
            player.play()
        }
    }
    
    public func stop() {
        if player.timeControlStatus == .playing {
            player.pause()
        }
    }
    
    public func updateBannerContent(_ index: Int? = 0, _ urlString: String = "", _ imageString: String = "", _ urls: [String], _ fileType: Int?) {
        if urlString.isEmpty {
            return
        }
        self.currentIndex = index!
        self.urlString = urlString
        self.imageString = imageString
        self.isVideo = fileType == 2 ? true : false
        self.isLocalVideo = urlString.hasPrefix("http") ? false : true
        if fileType == 2 {
            play(urlString, imageString, index!)
            return
        }
        
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.frame = self.bounds
        imageView.contentMode = .scaleToFill
        imageView.sd_setImage(with: URL(string: urlString), placeholderImage: UIImage(named: "placeholderImageView"))
        self.addSubview(imageView)
    }
```
> 从代码中可以出，视频播放完成后是用一个通知```NSNotification.Name.AVPlayerItemDidPlayToEndTime```来进行处理监听的，我在这里做了一个处理，完成后，重复播放，并且发出通知，告知自定义的轮播器，视频已播放完成，需要划到下一页并开启定时器。

- 4、 视频播放完成后的处理逻辑
```objc
    @objc func restart(_ sender: Notification) {
        guard let dict = sender.userInfo else { return}
        let index = dict["currentIndex"] as! Int
        print("【AVPlayer】索引值相同才能跳转：\(self.pageControl.currentPage) - playerIndex: \(index)")
        if self.pageControl.currentPage != index {
            return
        }
        
        nextBannerAction()
    }
```
> 从代码中可以看出来，我在这里做了一次拦截，只有当前播放的视频索引值和```pageControl```的索引值对应的才能开启定时器，并进入下一页。 因为我这里设计的时候可能有多个视频，多个视频就意味着有多个轮播View，视频播放时长不一样，执行播放完成的通知的时间就不一样，因为用的是同一个通知，所以需要做一次拦截，只有当前显示的视频播放完成后才会继续往下执行。

- 5、手势切换轮播内容
```objc
extension ATBannerView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
       let page = NSInteger((scrollView.contentOffset.x + size.width * 0.5) / size.width)
       if page == self.numberOfPages + 1 {
           self.pageControl.currentPage = 0
       }else if page == 0 {
           self.pageControl.currentPage = self.numberOfPages - 1
       }else {
           self.pageControl.currentPage = page - 1
       }
   }
   
   func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
       removeTimer()
       setupOffset()
   }
   
   func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
       let page = NSInteger((scrollView.contentOffset.x + size.width * 0.5) / size.width)
       if page == self.numberOfPages + 1 {
           self.scrollView.contentOffset = CGPoint(x: size.width, y: 0)
       }
   }
    
   func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
       setupOffset()
       if self.currentBannerView.isVideo == false {
           setupTimer()
       }
       swipeBannerAction()
   }
}
```

- 6、当前控制器出栈后需要销毁定时器和通知
```objc
    deinit {
        NotificationCenter.default.removeObserver(self)
        removeTimer()
    }
```

- 7， 外层调用，创建轮播器
```objc
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
```

##### 总结：
在实现的时候，出现很多细枝末节的小问题，比如这句代码```   player.replaceCurrentItem(with: item)```会导致线程阻塞，原因是```AVPlayer```的```replaceCurrentItemWithPlayerItem```方法在切换视频时底层会调用信号量等待然后导致当前线程卡顿。解决方法可以使用```AVQueuePlayer```来按顺序执行播放。



