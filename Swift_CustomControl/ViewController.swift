//
//  ViewController.swift
//  Swift_CustomControl
//
//  Created by 颜洪 on 16/9/21.
//  Copyright © 2016年 颜洪. All rights reserved.
//

import UIKit

class ViewController: UIViewController, YHCarouselViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor.lightGray
        
        let arr = [
            "http://pic39.nipic.com/20140226/18071023_162553457000_2.jpg",//网络图片
            "1.jpg",//本地图片，传image，不能传名称
            "http://photo.l99.com/source/11/1330351552722_cxn26e.gif",//网络gif图片
            "2.gif"//本地gif使用gifImageNamed(name)函数创建
        ]
        
        let describeArray = ["网络图片", "本地图片", "网络动态图", "本地动态图"];
        
        /**
         *  通过代码创建
         */
        let carouselView = YHCarouselView.init(frame: CGRect(x: 0, y: 100, width: UIScreen.main.bounds.size.width, height: 180), imagesArray: arr as [AnyObject], descriptions: describeArray)
        
        
        //设置占位图片,须在设置图片数组之前设置,不设置则为默认占位图
        //        _carouselView.placeholderImage = [UIImage imageNamed:@"placeholderImage.jpg"];
        
        //设置每张图片的停留时间，默认值为5s，最少为2s
        carouselView.time = 2;
        
        //设置分页控件的图片,不设置则为系统默认
        carouselView.setPageImage(pageImage: UIImage.init(named: "other")!, currentPageImage: UIImage.init(named: "current")!)
        
        //设置分页控件的位置，默认为PositionBottomCenter
        carouselView.pagePosition = PageControlPosition.RightBottom;
        //用block处理图片点击事件
//        carouselView.callbackBlock = { (index) in
//            
//            print("点击了第\(index)张图片")
//        }
        
        //用代理处理图片点击
        carouselView.delegate = self;
        
        /**
         *  修改图片描述控件的外观，不需要修改的传nil
         *
         *  参数一 字体颜色，默认为白色
         *  参数二 字体，默认为13号字体
         *  参数三 背景颜色，默认为黑色半透明
         */
        let bgColor = UIColor.blue.withAlphaComponent(0.5)
        let font = UIFont.systemFont(ofSize: 15)
        let textColor = UIColor.green
        carouselView.setDescribeText(textColor: textColor, font: font, bgColor: bgColor)
        self.view.addSubview(carouselView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func clickImage(carouselView: YHCarouselView, index: NSInteger) {
        
        print("点击了第\(index)张图片")
    }

}

