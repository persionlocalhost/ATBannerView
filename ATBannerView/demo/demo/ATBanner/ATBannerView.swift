//
//  ATBannerView.swift
//  atomstack
//
//  Created by Mac on 2024/9/7.
//

import UIKit
import SnapKit
import SDWebImage
import AVKit
struct Size {
    var width: CGFloat = 0
    var height: CGFloat = 0
}

protocol ATBannerViewDelegate: NSObjectProtocol {
    
    func didSelected(index: Int, bannerModel: ATHomeBannerModel)
}

class ATBannerView: UIView {
    
    // MARK: 声明属性
   private lazy var scrollView: UIScrollView = {
        let scr = UIScrollView(frame: self.bounds)
        scr.isPagingEnabled = true
        scr.delegate = self
        scr.backgroundColor = .clear
        scr.showsHorizontalScrollIndicator = false
        return scr
    }()
    
    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl(frame: .zero)
        control.backgroundColor = .clear
        control.numberOfPages = self.numberOfPages
        control.currentPage = 0
        control.pageIndicatorTintColor = .white
        control.currentPageIndicatorTintColor = UIColor(hexString: "#2B72FF")
        control.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        return control
    }()
    
    public weak var delegate: ATBannerViewDelegate?
    private lazy var numberOfPages: Int = 0
    private lazy var size = Size()
    private lazy var timeInterval: CGFloat = 0
    private var timer: Timer?
    private var placeholderImage: UIImage?
    private lazy var bannerViews = [ATBannerPlayerView]()
    private lazy var urls = [String]()
    private lazy var images = [String]()
    private lazy var currentBannerView = ATBannerPlayerView()
    private lazy var banners = [ATHomeBannerModel]()
    private var isOnlyImages: Bool? = true
    
    // 方式一
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
    
    // MARK: 事件交互
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
    
    @objc func restart(_ sender: Notification) {
        guard let dict = sender.userInfo else { return}
        let index = dict["currentIndex"] as! Int
        print("【AVPlayer】索引值相同才能跳转：\(self.pageControl.currentPage) - playerIndex: \(index)")
        if self.pageControl.currentPage != index {
            return
        }
        
        nextBannerAction()
    }

    @objc func tapAction() {
        let index = self.pageControl.currentPage
        delegate?.didSelected(index: index, bannerModel: self.banners[index])
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removeTimer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

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

extension ATBannerView {
    fileprivate func setupBannerView() {
        self.addSubview(self.scrollView)
        let y = self.size.height - 22
        self.addSubview(self.pageControl)
        self.pageControl.snp.makeConstraints { make in
            make.centerX.equalTo(self.snp.centerX)
            make.top.equalTo(self.snp.top).offset(y)
            make.height.equalTo(2)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.addGestureRecognizer(tap)
    }
    
    fileprivate func setupTimer() {
        if self.timer == nil {
            self.timer = Timer(timeInterval: self.timeInterval, target: self, selector: #selector(nextBannerAction), userInfo: nil, repeats: true)
            RunLoop.main.add(self.timer!, forMode: .common)
        }
    }
    
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
    
    fileprivate func setupScrollView(count: NSInteger) {
        self.scrollView.contentSize = CGSize(width: size.width * CGFloat(count), height: 0)
        self.scrollView.contentOffset = CGPoint(x: size.width, y: 0)
    }
    
    fileprivate func setupOffset() {
        if self.pageControl.currentPage == 0 {
            self.scrollView.contentOffset = CGPoint(x: size.width, y: 0)
        }else if self.pageControl.currentPage == self.numberOfPages - 1 {
            self.scrollView.contentOffset = CGPoint(x: size.width * CGFloat(self.numberOfPages), y: 0)
        }
    }
    
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
    
    fileprivate func removeTimer() {
        ATBannerPlayerView.share.stop()
        if timer != nil {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}

// 如果不只有图片就需要自定义view，若只是图片不需要了，bannerView就能直接展示
class ATBannerPlayerView: UIView {
    public static let share = ATBannerPlayerView()
    public lazy var isVideo: Bool = false
    public var urlString = ""
    public var imageString = ""
    private var coverImageView = UIImageView(image: UIImage(named: "placeholderImageView"))
    private var isLocalVideo = false
    private var player = AVPlayer()
     public var currentIndex: Int = 0
    var playerLayers: [AVPlayerLayer] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(hexString: "#F2F2F2")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
}

