# YHCarouselView
	一个采用Swift对无限轮播图的简易封装（采用两个imageView的方式）

# 集成YHCarouseelView
####导入###
- 方式1：手动导入
	- 将YHCarouselView文件夹中的所有文件添加到项目中
- 方式2: cocoapods导入
	- pod 'YHCarouselView'

> 建议采用方式一进行导入, 用户可以修改文件中部分内容, 以适应用户当前项目

####创建####
- 代码创建
> 目前不支持采用xib的形式创建, 由于创建及设置属性的代码量比较简洁, 所以不介意才用xib的形式进行集成, 避免冲突等造成项目问题
1. 创建YHCarouselView对象, 设置所需要的属性
2. 将YHCarouselView对象添加到当前view上显示

> 创建方式采用init(frame: , imagesArray: , descriptions: )方式进行创建, 其他属性均有默认值, 在需要的时候可进行修改

- YHCarouselView可调用的属性方法
	1. changeMode: 图片的切换模式, 默认为左右切换， 还有为淡入淡出
	2. imageContentMode： 图片的内容填充模式
	3. pagePosition: pagePosition的位置, 默认为CenterBottom
	4. time: 自动切换的停留时间, 默认为2s， 最少为2s
	5. autoCache： 设置是否开启图片的缓存
	6. callbackBlock: 图片点击的闭包实现(可采用协议代理的方式实现图片的点击)

####效果演示####
- 轮播滚动
![](https://camo.githubusercontent.com/8e146337ac8167aaa7f23bee5cb267a66c6296c2/687474703a2f2f75706c6f61642d696d616765732e6a69616e7368752e696f2f75706c6f61645f696d616765732f313432393037342d343465373532333635626133343838352e6769663f696d6167654d6f6772322f6175746f2d6f7269656e742f7374726970)

- 淡入淡出
![https://camo.githubusercontent.com/0df159f3d8ff7f0fea3966c514e0b42b03f348aa/687474703a2f2f7777322e73696e61696d672e636e2f6c617267652f62363832333261316777316633636b366c3430797167323061393034797530782e676966](https://camo.githubusercontent.com/0df159f3d8ff7f0fea3966c514e0b42b03f348aa/687474703a2f2f7777322e73696e61696d672e636e2f6c617267652f62363832333261316777316633636b366c3430797167323061393034797530782e676966)

参考自[codingZero](https://github.com/codingZero/XRCarouselView)