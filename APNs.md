# APNs   


## Apple Push Notification service
![](https://github.com/drunkbread/PushTest/blob/master/APNs-1%EF%BC%88%E7%AE%80%E5%8D%95%E6%B5%81%E7%A8%8B%EF%BC%89.png)

#### Provider   
- 从app接收devicetoken以及相关数据
- 决定什么时机发送通知
- 把通知数据传给APNs  
   
#### devicetoken
- 每一个推送请求都必须包含devicetoken，app每次启动要获取token并提供给Provider。
- devicetoken长度是可变的
- devicetoken是不固定的，不可作为设备的唯一标识。当升级系统版本，重置设备数据会使devicetoken改变 (这几天观察，app卸载重装之后取到的devicetoken会变..)

#### Payload
```
{
	"aps":{
		"alert":{	// alert可以是dic也可以试string
			"title":"This a push message !!!", // 标题
			"subtitle":"I am subtitle !!!”,	// 子标题
			"body":"I am alert body !!!" ,// 内容
			# "loc-key":"PUSH_Loc_KEY", // 本地化推送
			# "loc-args":["Ronaldo", "Zidane"]
			},
		"category":"Actionss", // 推送的category，value需要和app注册的categoryId一致
		"badge":1, // 角标
		"sound":"bingbong.aiff" // 声音
		},
	"key1":"value1", // 自定义字段
	"key2":"value2" // 自定义字段
}
```
- 注意： 
	- 2014年6月份iOS8 以上系统的设备payload提升到2KB，低于iOS8的设备维持在256字节。  
	- 2015年12月17日发布基于HTTP/2的全新APNs协议，payload最大size提升至4KB。 二进制协议仍保持2KB。 
	- 由于推送不保证到达，payload中不要带重要的信息，推送仅仅是作为一个通知。  

> 推送工具:  [NWPusher](https://github.com/noodlewerk/NWPusher)   
> 快速安装：`brew cask install pusher`

#### QoS 和 合并通知
当APNs尝试发一条推送，但是device不在线时，APNs会保存这条推送一段时间，等设备在线之后推给设备。APNs只会保存最新的一条推送。如果设备保持长时间不在线，这条最新的推送也会被丢弃。   

如果想要合并某两条推送，或者说更新某一条已经发出的推送，Provider发请求时需要在header里加`apns-collapse-id`。当对应的value值和之前的一条推送一样时，就会进行合并(更新)。
   
## 客户端需要做什么（UNUserNotifications）
### 本地通知
#### 创建UNNotificationContent
```objc
UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
content.title = @"You have a new Message !";
content.subtitle = [NSString stringWithFormat:@"消息发送者是：%@",msg.from];
// 这里body是NSString类型
content.body = [self getNotificationBodyFromMsg:msg];
content.badge = @1;
content.sound = [UNNotificationSound defaultSound];
//用于回复消息
NSDictionary *msgInfo = @{@"from":msg.from};
content.userInfo = msgInfo;
content.categoryIdentifier = @"Actionss";
```
#### 创建UNNotificationTrigger
- UNTimeIntervalNotificationTrigger
- UNCalendarNotificationTrigger
- UNLocationNotificationTrigger

###### 延迟几秒通知（UNTimeIntervalNotificationTrigger）
```objc
UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:kDelaySeconds repeats:NO];
```
###### 按日期重复通知（UNCalendarNotificationTrigger）
```objc
// 每周日的15：16系统会发本地通知
NSDateComponents *components = [[NSDateComponents alloc] init];
components.weekday = 1;
components.hour = 15;
components.minute = 16;
UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:YES];

```
###### 地理位置通知 （UNLocationNotificationTrigger）
```objc
CLLocationCoordinate2D center = CLLocationCoordinate2DMake(39.8715157295,116.3224821899);
CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:center radius:500 identifier:@"LizeBridge"];
region.notifyOnEntry = YES;
region.notifyOnExit = YES;
UNLocationNotificationTrigger *trigger = [UNLocationNotificationTrigger triggerWithRegion:region repeats:YES];
```
#### 创建UNNotificationRequest
```objc
NSString *rqIdentifier = msg.messageId;
UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:rqIdentifier content:content trigger:trigger];
```
> 普通场景下，这里每一个通知的requestIdentifier 应该是唯一的。如果想要更新某一个通知，可以重新创建一个request，requestId和想要更新的那一条一致。就可以进行更新。这里和远程推送`apps-collapse-id`是同样的作用。

#### 添加到通知中心
```objc
[[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
    
    if (!error) {
        
        NSLog(@"You have a Local Notification !");
    }
}];
```
#### 取消本地通知
```objc
// 移除已经发出的通知
[[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:@[response.notification]];
// 移除所有已发出的通知
[[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
```
### 远程推送
##### 注册推送
```objc
UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
[center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionBadge + UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
    
    if (granted && !error) {
        
        [application registerForRemoteNotifications];
    }
}];   
```
##### 获取devicetoken并传给Provider
```objc
//注册推送成功，返回devicetoken
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    NSLog(@"Get DeviceToken Success !!!");
    [[EMClient sharedClient] bindDeviceToken:deviceToken];
}
```
##### 接收处理推送
```objc
// 只有app在前台收到推送的时候才会执行这个回调
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    // 推送请求
    UNNotificationRequest *request = notification.request;
    // 内容
    UNNotificationContent *content = request.content;
    // 基本信息
    NSDictionary *info = content.userInfo;
    // 推送的badge
    NSNumber *badge = content.badge;
    // 推送消息的body
    NSString *body = content.body;
    // 推送 提示音
    UNNotificationSound *sound = content.sound;
    //推送 subtitle
    NSString *subtitle = content.subtitle;
    //推送 title
    NSString *title = content.title;
    
    // 判断是RemoteNotification 还是 LocalNotification
    if ([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        // Remote Notification
    } else {
        //Local Notification
    }
    // 这里可以控制通知的方式
    completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound);
}
// 点击alert进入app、点击自定义的按钮、输入框回复点击发送 会触发
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler
{
	completionHandler();
}

```

### Notification Actions

##### 创建普通Actions   
```objc
UNNotificationAction *unlockScreen = [UNNotificationAction actionWithIdentifier:kNormalActionUnlockScreenIdentifier title:NSLocalizedString(@"UnlockScreen", @"Unlock Screen") options:UNNotificationActionOptionAuthenticationRequired];

UNNotificationAction *launchApp = [UNNotificationAction actionWithIdentifier:kNormalActionLaunchAppIdentifier title:NSLocalizedString(@"LaunchApp", @"Launch App") options:UNNotificationActionOptionForeground];

UNNotificationAction *destructive = [UNNotificationAction actionWithIdentifier:kNormalActionDestructiveIdentifier title:NSLocalizedString(@"Destructive", @"Destructive") options:UNNotificationActionOptionDestructive];
```
#####注意： options传的是一个枚举类型，表示Action的行为方式   
```objc
锁屏状态下先解锁，不会进入app
UNNotificationActionOptionAuthenticationRequired

启动app
UNNotificationActionOptionForeground

红色字体，不会进入app
UNNotificationActionOptionDestructive

```
##### 创建文本输入框Action
```objc
UNTextInputNotificationAction *textAction = [UNTextInputNotificationAction actionWithIdentifier:kTextInputActionIdentifier title:@"Input" options:UNNotificationActionOptionNone textInputButtonTitle:NSLocalizedString(@"Send", @"Send") textInputPlaceholder:NSLocalizedString(@"Input", @"Input here ...")];

##  textInputButtonTittle 是输入框右侧按钮标题
## textInputPlaceholder 输入框占位符
```
##### 创建Category
```objc
UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:kNormalNotificationCategotyIdentifier actions:@[unlockScreen, launchApp, destructive, textAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
```
##### 把Category添加到通知中心
```objc
    [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet setWithArray:@[[HMPush registerNormalNotificationActions]]]];
```
> 注意：
> RemoteNotification 的payload里`category`的value要和注册的`categoryId`一致。在启动app的时候，就要注册category并且添加到通知中心。   

##### 点击action按钮后的处理
```objc
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler  {
	
	if ([response.actionIdentifier isEqualToString:kTextInputActionIdentifier]) {
        
        UNTextInputNotificationResponse *textResponse = (UNTextInputNotificationResponse *)response;
        if ([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
            
            // 远程推送
            NSLog(@"回复的内容是:%@",textResponse.userText);
       		 } else {
            		// 本地通知 回复消息

           		 [self _replyMessageWithNotificationResponse:textResponse];
       		 }
    	}
    
   	 if ([response.actionIdentifier isEqualToString:kNormalActionUnlockScreenIdentifier]) {
        // 点击解锁按钮
        NSLog(@"Unlock Screen Clicked !!!");
   		 } else if ([response.actionIdentifier isEqualToString:kNormalActionLaunchAppIdentifier]) {
        // 点击启动按钮
        NSLog(@"Launch App Clicked !!!");
    	} else if ([response.actionIdentifier isEqualToString:kNormalActionDestructiveIdentifier]) {
        // 点击销毁按钮
        NSLog(@"Destructive Clicked !!!");
    		}
	}
	 completionHandler();
}
```
### 更新通知
- 远程推送需要在请求头里加`apps-collapse-id`作为唯一的标识进行更新。目前找到的推送工具，不支持这个字段。暂用本地通知演示。
- 本地通知的更新主要依赖于`requestIdentifier`

### 带附件的通知
- 原理：在收到通知展示给用户之前下载附件并添加到通知的附件中

#### 添加扩展
Xcode —> File —> New —> Target   选择创建`Notification Service Extension`
![](https://github.com/drunkbread/PushTest/blob/master/Push-ServiceExtension.png)
此时工程里可以看到以下目录   
![](https://github.com/drunkbread/PushTest/blob/master/Push2.png)   
可以看到有一个自动创建好的类 `NotificationService`,继承自`UNNotificationServiceExtension`，在NotificationService类里有两个方法：

```objc
- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler
{
	//在后台处理收到的推送，传递给contentHandler。
	
	self.contentHandler = contentHandler;
	self.bestAttemptContent = [request.content mutableCopy];
	// 从payload的userinfo里拿到图片的url
	NSString *attchUrl = [request.content.userInfo objectForKey:@"image"];
	NSURL *url = [NSURL URLWithString:attchUrl];
    	NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
	// 下载附件到本地，然后添加content.attchments
	[[session downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    if (!error) {
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *localUrl = [NSURL fileURLWithPath:[location.path stringByAppendingString:@".jpg"]];
        NSError *iError = nil;
        [fm moveItemAtURL:location toURL:localUrl error:&iError];
        
        UNNotificationAttachment *attchment = [UNNotificationAttachment attachmentWithIdentifier:@"i" URL:localUrl options:nil error:nil];
        if (attchment) {
            self.bestAttemptContent.attachments = @[attchment];
        }
    }
    self.contentHandler(self.bestAttemptContent);
}] resume];

}

- (void)serviceExtensionTimeWillExpire 
{
	// 在扩展即将被系统终止之前调用，如果此时还没有传入内容，会传递原始的推送内容。
	// 下载附件的时间限制是30s，在时间将要到之前系统回调这个方法。给最后一次机会去处理推送的content。此时应以最快的方式处理返回。
	self.contentHandler(self.bestAttemptContent);
}


```

- 注意：   
 	- 当推送的payload中有`mutable-content:1`字段时，这条推送才可以被Service Extension更改。   
	- 附件大小：音频5M，图片10M，视频50M。   
	- Service Extension 限制下载的时间是30s。

##### payload
```
{
"aps":
    {
        "alert":
        {
            "title":"This is notification title !",
            "subtitle" : "I am subtitle !",
            "body":"This is notification body !"
        },
        "category":"Actionss",
        "badge":1,
        "mutable-content":1,
        "sound":"default"
    },
        "image":"https://a1.easemob.com/drunkbread/lif/chatfiles/7b31a940-f8b5-11e6-8e1a-49a5cde0debd"
}
```
效果如图：
![](https://github.com/drunkbread/PushTest/blob/master/Push-3.PNG)

### 自定义推送显示界面
Xcode —> File —> New —> Target —> Notification Content Extension
![](https://github.com/drunkbread/PushTest/blob/master/Push-4.png)
创建之后工程可以看到以下目录：   
![](https://github.com/drunkbread/PushTest/blob/master/Push-5.png)   
在storyboard中自定义UI界面。这个界面只能用于显示，不能响应点击或者手势等其他事件。

```objc
#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>

@interface NotificationViewController () <UNNotificationContentExtension>

@property IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *subTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *bodyLabel;

@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any required interface initialization here.
    self.preferredContentSize = CGSizeMake(CGRectGetWidth(self.view.frame), 160);
}

- (void)didReceiveNotification:(UNNotification *)notification {
    
    self.label.text = notification.request.content.title;
    self.subTitleLabel.text = notification.request.content.subtitle;
    self.bodyLabel.text = notification.request.content.body;
    UNNotificationContent *content = notification.request.content;
    UNNotificationAttachment *attchment = content.attachments.firstObject;
    if (attchment.URL.startAccessingSecurityScopedResource) {
        self.imageView.image = [UIImage imageWithContentsOfFile:attchment.URL.path];
    }
}

@end

```

![](https://github.com/drunkbread/PushTest/blob/master/IMG_0356.PNG)

- 如果不想在storyboard中处理UI，需要在Notifications Content 的info.plist中把 `NSExtensionMainStoryboard ` 替换为 `NSExtensionPrincipalClass `，value对应你的类名.
- `UNNotificationExtensionCategory` 和推送payload中category字段保持一致。
- `UNNotificationExtensionDefaultContentHidden` 是否显示默认的内容

![](https://github.com/drunkbread/PushTest/blob/master/Push-6.png)







	
