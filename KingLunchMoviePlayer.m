//
//  KingLunchMoviePlayer.m
//  KingMovie
//
//  Created by King on 2017/3/24.
//  Copyright © 2017年 King. All rights reserved.
//

#import "KingLunchMoviePlayer.h"
#import <AVFoundation/AVFoundation.h>


#define KScreenWidth [UIScreen mainScreen].bounds.size.width
#define KScreenHeight [UIScreen mainScreen].bounds.size.height

#define kIsFirstLauchApp @"kIsFirstLauchApp"


@interface KingLunchMoviePlayer ()
/**播放前的图片，防止出现黑屏现象*/
@property (nonatomic,strong)UIImageView *starPlayerImageView;

/**播放中断时图片*/
@property (nonatomic,strong)UIImageView *pausePlayerImageView;

/**定时器*/
@property (nonatomic,strong)NSTimer *timer;

/**结束进入主界面按钮*/
@property (nonatomic,strong)UIButton *enterMainButton;

@end

@implementation KingLunchMoviePlayer

/**禁用自动转屏，只支持竖屏*/
-(BOOL)shouldAutorotate{
    
    return NO;
}
//视图将要显示的时候将状态栏隐藏掉，使界面更加美观
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //隐藏状态栏
    [UIApplication sharedApplication].statusBarHidden = NO;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    
}
//手动释放下，不然会造成崩溃
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.timer invalidate];
    self.timer = nil;
    self.player = nil;
}

-(void)viewDidLoad
{
    
    [super viewDidLoad];
    
    //设置播放界面
    [self setupPlayerView];
    
    //添加监听事件
    [self addNotification];
}
#pragma  mark - 监听事件及实现方法
- (void)addNotification{
    //移除后台运行的通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    //进入前台 注册通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(viewWillEnterForeground) name:UIApplicationDidBecomeActiveNotification  object:nil];
    
    //判断是否为第一次启动app
    
    if ([self isFirstLauchApp]) {
        
        //第二次进入视频播放一遍结束
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackComplete) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        
        
    }else{
        
        //第一次进入视频需要循环播放
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlaybackAgain) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        
    }
    
    //开始播放
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlaybackStart) name:AVPlayerItemTimeJumpedNotification object:nil];
    
    
}
#pragma  mark -- 开始播放视频
-(void)moviePlaybackStart{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self.starPlayerImageView removeFromSuperview];
        self.starPlayerImageView = nil;
    });
}
#pragma  mark -- 循环播放
-(void)moviePlaybackAgain{
    
    self.starPlayerImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"lauchAgain"]];
    
    _starPlayerImageView.frame = CGRectMake(0, 0, KScreenWidth, KScreenHeight);
    
    [self.contentOverlayView addSubview:_starPlayerImageView];
    
    [self.pausePlayerImageView removeFromSuperview];
    self.pausePlayerImageView = nil;
    
    //播放地址
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"opening_long_1080*1920.mp4" ofType:nil];
    //初始化player
    self.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:filePath]];
    self.showsPlaybackControls = NO;
    
    //播放视频
    [self.player play];
    
}
-(void)viewWillEnterForeground{
    
    if (!self.player) {
        
        //准备播放视频
        [self prepareMovie];
    }
    //播放视频
    [self.player play];
}
- (void)prepareMovie{
    //首次运行
    NSString *filePath = nil;
    
    if (![self isFirstLauchApp]) {
        //第一次安装
        
        filePath = [[NSBundle mainBundle]pathForResource:@"opening_long_1080*1920.mp4" ofType:nil];
        
        [self setIsFirstLauchApp:YES];
    }else{
        
        filePath = [[NSBundle mainBundle]pathForResource:@"opening_short_1080*1920.mp4" ofType:nil];
        
    }
    
    //初始化palyer
    
    self.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:filePath]];
    self.showsPlaybackControls = NO;
    
    //播放
    [self.player play];
    
}
- (void)setupPlayerView{
    
    //设置图片
    self.starPlayerImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"lauch"]];
    _starPlayerImageView.frame = CGRectMake(0, 0,KScreenWidth , KScreenHeight);
    
    /**   contentOverlayView 是iOS 8 新增加的视频框架 AVPlayerViewController 中的一个类 ，使用它可实现画中画的功能，相当于一个透明的层，在这个层我们可以添加任何内容，比如视频、动画，而不会影响整体的框架，大小和我们的界面大小相同 可以理解为浮动在界面表面的二维空间*/
    [self.contentOverlayView addSubview:_starPlayerImageView];
    
    //判断是否是第一次启动app
    
    if (![self isFirstLauchApp]) {
        
        //设置播放主界面按钮
        [self setupEnterMainButton];
    }
    

    
}

- (void)setupEnterMainButton{
    
    self.enterMainButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    _enterMainButton.frame = CGRectMake(24, KScreenHeight - 32 - 48, KScreenWidth - 48, 48);
    
    _enterMainButton.layer.borderWidth = 1;
    _enterMainButton.layer.cornerRadius = 24;
    _enterMainButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [_enterMainButton setTitle:@"进入应用" forState:UIControlStateNormal];
    
    _enterMainButton.hidden = YES;
    
    [self.view addSubview:_enterMainButton];
    
   
    [_enterMainButton addTarget:self action:@selector(enterMainAction:) forControlEvents:UIControlEventTouchUpInside];
    
    //设置定时器当视频播放到第三秒时 展示进入应用button
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(showEnterMainButton) userInfo:nil repeats:YES];
    
}
#pragma   mark -- 进入应用程序按钮进入主界面
-(void)enterMainAction:(UIButton *)btn{
    //进入主界面后视频暂停播放
    [self.player pause];
    //暂停播放和进入到主界面有时间间隙，这时候最好获取视频暂停后的截图，避免出现卡顿感
    self.pausePlayerImageView = [[UIImageView alloc]init];
    
    _pausePlayerImageView.frame = CGRectMake(0, 0, KScreenWidth, KScreenHeight);
    
    [self.contentOverlayView addSubview:_pausePlayerImageView];
    
    //等比例填充，图片不会变形， 还有一种带有scale 的填充模式，但是图片会变形，  这种方式，使用带有Aspect的填充模式，不过可以裁剪超出边界的部分 self.ImageView.clipsToBounds = YES;
    self.pausePlayerImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    //获取视频暂停时候的截图
    [self getoverPlayerImage];
    
}
-(void)getoverPlayerImage{
  //  AVAsset 抽象类和不可变类,定义了媒体资源混合呈现的方式.可以让我们开发者在处理媒体提供了一种简单统一的方式,它并不是媒体资源,但是它可以作为时基媒体的容器.
    //找到当前播放的资源  一个媒体资源创建AVAsset对象时,可以通过URL对它进行初始化,URL可以是本地资源也可以是一个网络资源  实际上是创建了它子类AVUrlAsset的一个实例,而AVAsset是一个抽象类,不能直接被实例化
 /**  
    NSURLassetUrl = [NSURL URLWithString:@"1234"];
    AVAssetasset = [AVAsset asetWithURL:assetUrl];
  */
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc]initWithAsset:self.player.currentItem.asset];
    
    gen.appliesPreferredTrackTransform = YES;
    
    NSError *error = nil;
    CMTime actualTime;
    CMTime now = self.player.currentTime;
    
    /**这里需要说一下如何获取视频具体某一帧 
    
     先说下CMTime 是一个用来描述视频时间的结构体。
    他有两个构造函数： * CMTimeMake * CMTimeMakeWithSeconds
    这两个的区别是
     * CMTimeMake(a,b) a当前第几帧, b每秒钟多少帧.当前播放时间a/b
     * CMTimeMakeWithSeconds(a,b) a当前时间,b每秒钟多少帧.*/
    
    /**开始我api 很困惑: 为什么我request的时间 不等于 actual
     后来查了一下文档。
     当你想要一个时间点的某一帧的时候，他会在一个范围内找，如果有缓存，或者有在索引内的关键帧，就直接返回，从而优化性能。如果我们要精确时间，那么只需要实现下面的代码*/
    [gen setRequestedTimeToleranceBefore:kCMTimeZero];
    [gen setRequestedTimeToleranceAfter:kCMTimeZero];
   
    CGImageRef image = [gen copyCGImageAtTime:now actualTime:&actualTime error:&error];
    
    if (!error) {
        //取视频暂停那一帧的图片为暂停图片
        UIImage *thumb = [[UIImage alloc]initWithCGImage:image];
        
        self.pausePlayerImageView.image = thumb;
    }

    NSLog(@"%f , %f",CMTimeGetSeconds(now),CMTimeGetSeconds(actualTime));
    NSLog(@"%@",error);
    //视频播放结束
    /**
     <#delayInSeconds#>  : 延迟0.01秒
     */
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self moviePlaybackComplete];
    });
    

}
//判断第三秒显示进入按钮
-(void)showEnterMainButton{
    
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc ]initWithAsset:self.player.currentItem.asset];
    
    gen.appliesPreferredTrackTransform = YES;
    
    NSError * error = nil;
    
    CMTime actualTime;
    CMTime now = self.player.currentTime;
    
    [gen setRequestedTimeToleranceAfter:kCMTimeZero];
    [gen setRequestedTimeToleranceBefore:kCMTimeZero];
    
    [gen copyCGImageAtTime:now actualTime:&actualTime error:&error];
    
    NSInteger currentPlayBackTime = (NSInteger)CMTimeGetSeconds(actualTime);
    
    if (currentPlayBackTime >= 3) {
        self.enterMainButton.hidden = NO;
        
        static dispatch_once_t onceToken;
        dispatch_once (&onceToken,^{
            
            self.enterMainButton.alpha = 0;
            
            //动画，显示进入主页的button
            [UIView animateWithDuration:0.5 animations:^{
                self.enterMainButton.alpha = 1;
            } completion:nil];
            
            
        });
        
        if(currentPlayBackTime >5){
            
            // 防止没有显现出来
            self.enterMainButton.alpha = 1;
            self.enterMainButton.hidden = NO;
            
            [self.timer invalidate];
            self.timer = nil;
            
        }
    
    }
    
}
#pragma  mark -- 视频播放完成
-(void)moviePlaybackComplete{
    
    //视频播放完成移除通知，否则会出现界面显示错误 还需要将空控件手动释放掉
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    [self.starPlayerImageView removeFromSuperview];
    self.starPlayerImageView = nil ;
    
    [self.pausePlayerImageView removeFromSuperview];
    self.pausePlayerImageView = nil;
    
    if (self.timer) {
        
        [self.timer invalidate];
        self.timer = nil;
    }
    //进入主界面
    [self enterMain];
    
}
- (void)enterMain{
    
    AppDelegate *dele = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    UIViewController *main = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]]instantiateInitialViewController];
    
    dele.window.rootViewController = main;
    
    [dele.window makeKeyAndVisible];
}


#pragma  mark -- 是否是第一次启动app

-(BOOL)isFirstLauchApp{
    
    return [[NSUserDefaults standardUserDefaults] boolForKey:kIsFirstLauchApp];
}

-(void)setIsFirstLauchApp:(BOOL)isFirstLauchApp{
    
    [[NSUserDefaults standardUserDefaults]setBool:isFirstLauchApp forKey:kIsFirstLauchApp];
}




@end
