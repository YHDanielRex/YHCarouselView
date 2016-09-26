//
//  YHCarouselView.swift
//  Swift_CustomControl
//
//  Created by 颜洪 on 16/9/21.
//  Copyright © 2016年 颜洪. All rights reserved.
//

import UIKit
import ImageIO

let DEFAULTTIME: CGFloat = 5.0
let HORMARGIN: CGFloat = 10.0
let VERMARGIN: CGFloat = 5.0
let DES_LABEL_H: CGFloat = 20.0

// pageControl的显示位置
enum PageControlPosition {
    case Default           //默认值 == PositionBottomCenter
    case Hide           //隐藏
    case CenterTop     //中上
    case LeftBottom     //左下
    case CenterBottom   //中下
    case RightBottom     //右下
}

// 图片切换方式
enum ImageChangeMode {
    case TakeTurnImage
    case Fade
}


// 协议
protocol YHCarouselViewDelegate {
    
    
    /// 处理图片的点击, 返回图片在数组中的索引
    ///
    /// - parameter carouselView: 控件本身
    /// - parameter index:        点击的图片索引
    ///
    func clickImage(carouselView : YHCarouselView, index : NSInteger) -> Void
}

// 点击方法的闭包实现
typealias imageClickBlock = (_ index: NSInteger) -> Void

class YHCarouselView: UIView, UIScrollViewDelegate {
    
//MARK: 属性的设置
    /**设置图片的切换模式, 默认为Default*/
    var changeMode : ImageChangeMode = ImageChangeMode.TakeTurnImage
    
    /**设置图片的内容模式, 默认为scaleToFill*/
    var imageContentMode: UIViewContentMode = UIViewContentMode.scaleToFill {
        
        didSet {
            
            self.currImageView?.contentMode = self.imageContentMode
            self.otherImageView?.contentMode = self.imageContentMode
        }
    }
    
    
    
    /**设置pageControl的位置, 默认为CenterBottom*/
    // 一张图片时默认隐藏
    var pagePosition: PageControlPosition = PageControlPosition.CenterBottom {
        
        didSet {
            
            self.pageControl?.isHidden = (self.pagePosition == PageControlPosition.Hide) || (self._imageArray.count == 1)
            if (self.pageControl?.isHidden)! {
                return
            }
            
            var size: CGSize?;
            if self.pageImageSize == nil {//没有设置图片，系统原有样式
                size = self.pageControl?.size(forNumberOfPages: (self.pageControl?.numberOfPages)!)
                size?.height = 8;
            } else {//设置图片了
                size = CGSize(width: (self.pageImageSize?.width)! * CGFloat(((self.pageControl?.numberOfPages)!) * 2 - 1), height: (self.pageImageSize?.height)!);
            }
            self.pageControl?.frame = CGRect(x: 0, y: 0, width: (size?.width)!, height: (size?.height)!)
            
            let centerY: CGFloat = self.frame.size.height - ((size?.height)! * 0.5) - VERMARGIN - ((self.describeLabel?.isHidden)! ? 0 : DES_LABEL_H)
            let pointY: CGFloat = self.frame.size.height - (size?.height)! - VERMARGIN - ((self.describeLabel?.isHidden)! ? 0 : DES_LABEL_H)
            
            if (self.pagePosition == PageControlPosition.Default || self.pagePosition == PageControlPosition.CenterBottom) {
                self.pageControl?.center = CGPoint(x: self.frame.size.width * 0.5, y: centerY)
            }
            else if (self.pagePosition == PageControlPosition.CenterTop) {
                self.pageControl?.center = CGPoint(x: self.frame.size.width * 0.5, y: size!.height * 0.5 + VERMARGIN)}
            else if (self.pagePosition == PageControlPosition.LeftBottom){
                self.pageControl?.frame = CGRect(x: HORMARGIN, y: pointY, width: size!.width, height: size!.height)}
            else {
                self.pageControl?.frame = CGRect(x: self.frame.size.width - HORMARGIN - size!.width, y: pointY, width: size!.width, height: size!.height)
            }
        }
    }
    
    var delegate: YHCarouselViewDelegate?
    
    /**
     *  轮播的图片数组，可以是本地图片（UIImage，不能是图片名称），也可以是网络路径
     *  支持网络gif图片，本地gif需做处理后传入
     */
    var _imageArray = [AnyObject]()
    var imageArray: [AnyObject]? {
        
        set{
            self._imageArray = newValue!
            if self._imageArray.count == 0 {
                
                return
            }
            
            var i: NSInteger = 0;
            for imageIdx: AnyObject in self._imageArray {
                
                if imageIdx is NSString {
                    if let image: UIImage = UIImage(named: imageIdx as! String) {
                        
                        if !imageIdx.hasSuffix(".gif") {
                            
                            self.images.append(image)
                        }
                        else {
                            
                            self.images.append(gifImageNamed(imageName: imageIdx as! NSString))
                        }
                    }
                    else {
                        
                        let placeholder: UIImage = UIImage(named: "XRPlaceholder")!
                        self.images.append(placeholder)
                        if (imageIdx.hasPrefix("http")) {
                            
                            self.downloadImages(index: i)
                        }
                    }
                }
                i += 1
            }
            
            // 防止在滚动过程中重新给imageArray赋值时报错
            if self.currIndex >= self.images.count {
                
                self.currIndex = self.images.count - 1;
            }
            self.currImageView?.image = self.images[self.currIndex];
            self.describeLabel?.text = self.descriptionArray.count > self.currIndex ? self.descriptionArray[self.currIndex] : "";
            self.pageControl?.numberOfPages = self.images.count;
            self.layoutSubviews()
        }
        
        get {
            
            return self._imageArray
        }
    }
    
    /**
     *  图片描述的字符串数组，应与图片顺序对应
     *
     *  图片描述控件默认是隐藏的
     *  设置该属性，控件会显示
     *  设置为nil或空数组，控件会隐藏
     */
    var descriptionArray = [String]()
    
    /**
     *  每一页停留时间，默认为5s，最少2s
     *  当设置的值小于2s时，则为默认值
     */
    var _time: TimeInterval? = 0
    var time: TimeInterval? {
        
        set {
            
            self._time = newValue
            self.startTimer()
        }
        
        get {
            
            return self._time == 0 ? 2 : self._time
        }
    }
    
    /**
     *  是否开启图片缓存，默认为YES
     */
    var autoCache: Bool = true
    
    
//MARK: 私有属性
    // 轮播图的图片数组
    private var images = [UIImage]()
    // 当前显示的imageView
    private var currImageView: UIImageView? = {
        let currImageView = UIImageView.init()
        currImageView.clipsToBounds = true
        return currImageView
    }()
    // 滚动显示的imageView
    private var otherImageView: UIImageView? = {
        let otherImageView = UIImageView.init()
        otherImageView.clipsToBounds = true
        return otherImageView
    }()
    // 图片描述控件, 默认在底部
    private var describeLabel: UILabel? = {
        
        let describeLabel = UILabel.init()
        describeLabel.backgroundColor = UIColor.init(white: 0, alpha: 0.5)
        describeLabel.textColor = UIColor.white
        describeLabel.textAlignment = NSTextAlignment.center
        describeLabel.font = UIFont.systemFont(ofSize: 13)
        describeLabel.isHidden = true
        return describeLabel
    }()
    // 滚动视图
    private var scrollView: UIScrollView? = {
        
        let scrollView = UIScrollView.init()
        scrollView.isPagingEnabled = true
        scrollView.scrollsToTop = false
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    // 分页控件
    private var pageControl: UIPageControl? = {
        let pageControl = UIPageControl.init()
        pageControl.isUserInteractionEnabled = false
        return pageControl
    }()
    private var currIndex: NSInteger = 0 // 当前显示的图片的索引
    private var nextIndex: NSInteger = 1 // 将要显示的图片的索引
    private  var pageImageSize: CGSize? // pageControl图片的大小
    private var timer: Timer? // 定时器
    // 任务队列
    private lazy var queue: OperationQueue = {
        
        return OperationQueue.init()
    }()
    
    // 图片的点击闭包
    private var callback: imageClickBlock?
    
    // 缓存图片的本地文件路劲
    private var _cache: String?
    private var cache: String? {
        
        set {
            
            _cache = newValue
        }
        get {
        
            let caches = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            _cache = caches.last
            let isExists = FileManager.default.fileExists(atPath: _cache!)
            
            if !isExists {
                
                try! FileManager.default.createDirectory(atPath: _cache!, withIntermediateDirectories: true, attributes: nil)
            }
            return _cache
        }
    }

    
//MARK: 图片点击事件
    // 采用block的方式点击实现
    func setClickBlock(block: @escaping imageClickBlock){
        
        self.callback = block
    }
    
    func imageClick(sender: UITapGestureRecognizer) {
        
        if callback != nil {
            
            callback!(self.currIndex)
        }
        
        self.delegate?.clickImage(carouselView: self, index: self.currIndex)
    }
    
//MARK: 定时器
    /**开启定时器, 默认开启, 调用后重新开启*/
    func startTimer() {
        
        // 只有一张图片, 不开启定时器
        if self.images.count <= 1 {
            return
        }
        
        // 如果定时器已经开启, 先停止在重新开启
        if self.timer != nil {
            
            self.stopTimer()
        }
        self.timer = Timer.scheduledTimer(withTimeInterval: self.time!, repeats: true, block: { (timer: Timer) in
            
            // 切换
            if self.changeMode == ImageChangeMode.Fade {
                
                // 淡入淡出模式
                self.nextIndex = (self.currIndex + 1) % self.images.count
                self.otherImageView?.image = self.images[self.nextIndex]
                
                UIView.animate(withDuration: 1.2, animations: { 
                    self.currImageView?.alpha = 0
                    self.otherImageView?.alpha = 1
                    self.pageControl?.currentPage = self.nextIndex
                    }, completion: { (finished: Bool) in
                        
                    self.changeToNext()
                })
            }
            else {
                
                self.scrollView?.setContentOffset(CGPoint(x: self.frame.size.width * 3, y: 0), animated: true)
            }
        })
        RunLoop.current.add(self.timer! , forMode: RunLoopMode.commonModes)
    }
    
    /**停止定时器*/
    func stopTimer() {
        if self.timer != nil  {
            self.timer?.invalidate()
        }
        self.timer = nil
    }
    
//MARK: 当前图片过半时就改变当前页码
    func changeCurrentPage(offset: CGFloat) -> Void {
        
        if offset < self.frame.size.width * 1.5 {
            
            var index = self.currIndex - 1
            if index < 0 {
                index = self.images.count - 1
            }
            self.pageControl?.currentPage = index
        }
        else if offset > self.frame.size.width * 2.5 {
            
            self.pageControl?.currentPage = (self.currIndex + 1) % self.images.count
        }
        else {
            
            self.pageControl?.currentPage = self.currIndex
        }
    }
    
//MARK: UIScrollViewDelegate协议方法
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if CGSize.zero.equalTo(scrollView.contentSize) {
            return
        }
        let offsetX: CGFloat = scrollView.contentOffset.x;
        //滚动过程中改变pageControl的当前页码
        self.changeCurrentPage(offset: offsetX)
        
        //向右滚动
        if offsetX < self.frame.size.width * 2 {
            if (self.changeMode == ImageChangeMode.Fade) {
                self.currImageView?.alpha = offsetX / self.frame.size.width - 1;
                self.otherImageView?.alpha = 2 - offsetX / self.frame.size.width;
            } else {
                self.otherImageView?.frame = CGRect(x: self.frame.size.width, y: 0, width: self.frame.size.width, height: self.frame.size.height)
            }
            
            self.nextIndex = self.currIndex - 1;
            if self.nextIndex < 0 {
                self.nextIndex = self.images.count - 1
            }
            self.otherImageView?.image = self.images[self.nextIndex];
            if offsetX <= self.frame.size.width {
                self.changeToNext()
            }
            
            //向左滚动
        } else if offsetX > self.frame.size.width * 2 {
            if (self.changeMode == ImageChangeMode.Fade) {
                self.otherImageView?.alpha = offsetX / self.frame.size.width - 2;
                self.currImageView?.alpha = 3 - offsetX / self.frame.size.width;
            } else {
                
                self.otherImageView?.frame = CGRect(x: (self.currImageView?.frame)!.maxX, y: 0, width: self.frame.size.width, height: self.frame.size.height)
            }
            
            self.nextIndex = (self.currIndex + 1) % self.images.count;
            self.otherImageView?.image = self.images[self.nextIndex];
            if (offsetX >= self.frame.size.width * 3) {
                
                self.changeToNext()
            }
        }
    }
    
    func changeToNext() {
        
        if (self.changeMode == ImageChangeMode.Fade) {
            self.currImageView?.alpha = 1;
            self.otherImageView?.alpha = 0;
        }
        //切换到下一张图片
        self.currImageView?.image = self.otherImageView!.image;
        self.scrollView?.contentOffset = CGPoint(x: self.frame.size.width * 2, y: 0);
        self.scrollView?.layoutSubviews();
        self.currIndex = self.nextIndex;
        self.pageControl?.currentPage = self.currIndex;
        if self.descriptionArray.count > self.currIndex {
            self.describeLabel?.text = self.descriptionArray[self.currIndex]
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        self.stopTimer()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        self.startTimer()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if (self.changeMode == ImageChangeMode.Fade) {return};
        let pointInSelf: CGPoint = (self.scrollView?.convert(self.otherImageView!.frame.origin, to: self))!
        if (abs(pointInSelf.x) != self.frame.size.width) {
            let offsetX: CGFloat = self.scrollView!.contentOffset.x + pointInSelf.x;
            self.scrollView?.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
        
        }
    }
    
//MARK: 页面布局
    /**
     *  设置分页控件指示器的图片
     *  两个图片必须同时设置，否则设置无效
     *  不设置则为系统默认
     *
     *  @param pageImage    其他页码的图片
     *  @param currentImage 当前页码的图片
     */
    func setPageImage(pageImage: UIImage, currentPageImage: UIImage) -> Void {
        
        self.pageImageSize = pageImage.size
        self.pageControl?.setValue(currentPageImage, forKey: "currentPageImage")
        self.pageControl?.setValue(pageImage, forKey: "pageImage")
    }
    
    /**
     *  设置分页控件指示器的颜色
     *  不设置则为系统默认
     *
     *  @param color        其他页码的颜色
     *  @param currentColor 当前页码的颜色
     */
    func setPageColor(pageColor: UIColor, currentPageColor: UIColor) -> Void {
        
        self.pageControl?.pageIndicatorTintColor = pageColor
        self.pageControl?.currentPageIndicatorTintColor = currentPageColor
    }
    
    
    /**
     *  修改图片描述控件的部分属性，不需要修改的传nil
     *
     *  @param color   字体颜色，默认为[UIColor whiteColor]
     *  @param font    字体，默认为[UIFont systemFontOfSize:13]
     *  @param bgColor 背景颜色，默认为[UIColor colorWithWhite:0 alpha:0.5]
     */
    func setDescribeText(textColor: UIColor, font: UIFont, bgColor: UIColor) -> Void {
        
        if textColor.hashValue > 0 {
            self.describeLabel?.textColor = textColor
        }
        if font.hashValue > 0 {
            self.describeLabel?.font = font
        }
        if bgColor.hashValue > 0 {
            self.describeLabel?.backgroundColor = bgColor
        }
    }
    
    override func layoutSubviews() {
        
        // 有导航控制器时, 会默认在scrollView上方添加64的内边距, 这里强制设置为0
        self.scrollView?.contentInset = UIEdgeInsets.zero
        self.scrollView?.frame = self.bounds
        self.describeLabel?.frame = CGRect(x: 0, y: self.frame.size.height - DES_LABEL_H, width: self.frame.size.width, height: DES_LABEL_H)
        // 重新计算pageControl的位置
        self.setScrollViewContentSize()
    }
    
    
    /**
     *  清除沙盒中的图片缓存
     */
    func clearDiskCache() {
        let contents: Array = try! FileManager.default.contentsOfDirectory(atPath: self.cache!)
        for fileName: String in contents {
            
            try! FileManager.default.removeItem(atPath: (cache?.appending("/"+fileName))!)
        }
    }
    
//MARK: 设置scrollView的contentSize
    func setScrollViewContentSize() {
        
        if self.images.count > 1 {
            self.scrollView?.contentSize = CGSize(width: self.frame.size.width * 5, height: 0);
            self.scrollView?.contentOffset = CGPoint(x: self.frame.size.width * 2, y: 0);
            self.currImageView?.frame = CGRect(x: self.frame.size.width * 2, y: 0, width: self.frame.size.width, height: self.frame.size.height);
            
            if (self.changeMode == ImageChangeMode.Fade) {
                //淡入淡出模式，两个imageView都在同一位置，改变透明度就可以了
                self.currImageView?.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height);
                self.otherImageView?.frame = self.currImageView!.frame;
                self.otherImageView?.alpha = 0;
                self.insertSubview(self.currImageView!, at: 0)
                self.insertSubview(self.otherImageView!, at: 1)
            }
            
            self.startTimer();
        }
        else {
            //只要一张图片时，scrollview不可滚动，且关闭定时器
            self.scrollView?.contentSize = CGSize.zero;
            self.scrollView?.contentOffset = CGPoint.zero;
            self.currImageView?.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height);
            self.stopTimer()
        }
    }
    
//MARK: 创建视图
    // 初始化视图
    init(frame: CGRect, imagesArray: [AnyObject], descriptions: [String]) {
        
        super.init(frame: frame)
        self.imageArray = imagesArray as [AnyObject]
        self.descriptionArray = descriptions
        
        self._initViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    private func _initViews() {
        
        self.autoCache = true
        
        self.addSubview(self.scrollView!)
        self.addSubview(self.describeLabel!)
        self.addSubview(self.pageControl!)
        self.scrollView?.addSubview(self.otherImageView!)
        self.scrollView?.addSubview(self.currImageView!)
        self.scrollView?.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(YHCarouselView.imageClick(sender:)))
        self.scrollView?.addGestureRecognizer(tapGesture)
    }
    
//MARK: 下载图片
    func downloadImages(index: NSInteger) -> Void {
        
        let urlString: String = self.imageArray![index] as! String
        let imageName: String = urlString.replacingOccurrences(of: "/", with: "")
        let path: String = (self.cache?.appending("/"+imageName))!
        if self.autoCache {
            
            print(path)
            if FileManager.default.fileExists(atPath: path) {
                let data: NSData = try! NSData.init(contentsOfFile: path)
                if data.length > 0 {
                    
                    self.images[index] = self.getImageWithData(data: data)
                    return
                }
            }
        }
        // 下载图片
        let download: BlockOperation = BlockOperation.init {
            
            if let data: NSData = NSData.init(contentsOf: URL(string: urlString)!) {
                if data.hashValue == 0 {return}
                let image: UIImage = self.getImageWithData(data: data)
                // 取到的图片可能不是图片
                self.images[index] = image
                // 如果下载的图片为当前要显示的图片, 直接到主线程给imageView赋值, 否则要等到下一轮才会显示
                if self.currIndex == index {
                    self.performSelector(onMainThread: #selector(YHCarouselView.setImage(image:)), with: image, waitUntilDone: false)
                    if self.autoCache {
                        
                        data.write(toFile: path, atomically: true)
                    }
                }
            }
        }
        self.queue.addOperation(download)
    }
    
    func setImage(image: UIImage) {
        
        self.currImageView?.image = image
    }
    
//MARK: 下载图片，如果是gif则计算动画时长
    func getImageWithData(data: NSData) -> UIImage {
        
        let imageSource: CGImageSource = CGImageSourceCreateWithData(data, nil)!
        let count: size_t = CGImageSourceGetCount(imageSource)
        if count <= 1 { // 非gif图
            
            return UIImage.init(data: data as Data)!
        }
        else { // 非gif
            
            var gifImages: [UIImage] = [UIImage]()
            var duration: TimeInterval = 0
            for idx in 0..<count {
                
                let image: CGImage = CGImageSourceCreateImageAtIndex(imageSource, idx, nil)!
                duration += TimeInterval(self.durationWithSourceAtIndex(source: imageSource, index: idx))
                gifImages.append(UIImage.init(cgImage: image))
            }
            if duration > 0 {
                duration = Double(count) * 0.1
            }
            return UIImage.animatedImage(with: gifImages, duration: duration)!
        }
    }
    
//MARK: 获取每一帧图片的时长
    func durationWithSourceAtIndex(source: CGImageSource, index: NSInteger) -> Float {
        
        var duration: Float = 0.1
        let propertiesRef: CFDictionary = CGImageSourceCopyPropertiesAtIndex(source, index, nil)!
        let properties: NSDictionary = propertiesRef as NSDictionary
        let gifProperties: NSDictionary = properties.value(forKey: kCGImagePropertyGIFDictionary as String) as! NSDictionary
        
        var delayTime: NSNumber = gifProperties.value(forKey: kCGImagePropertyGIFUnclampedDelayTime as String) as! NSNumber
        if delayTime.boolValue {
            
            duration = delayTime.floatValue
        }
        else {
            
            delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as! NSNumber
            if delayTime.boolValue {
                duration = delayTime.floatValue
            }
        }
        return duration
    }
}

//MARK: 本地gif图片的处理
func gifImageNamed(imageName: NSString) -> UIImage {
    
    var imageNa = imageName
    if !imageName.hasSuffix(".gif") {
        
        imageNa = imageNa.appending(".gif") as NSString
    }
    
    let imagePath: String = Bundle.main.path(forResource: imageNa as String, ofType: nil)!
    let data: NSData = try! NSData(contentsOfFile: imagePath)
    if data.hashValue > 0 {
        
        var carouselview: YHCarouselView? = YHCarouselView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        let image = carouselview!.getImageWithData(data: data)
        carouselview = nil
        return image
    }
    return UIImage.init(named: imageName
        as String)!
}

