//
//  HMPush.m
//  MyPush
//
//  Created by EaseMob on 2017/2/9.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "HMPush.h"
#import <HyphenateLite/HyphenateLite.h>
#import <CoreLocation/CoreLocation.h>

#import "MyPushHeader.h"

#define kDelaySeconds 0.01



static HMPush *push = nil;

@interface HMPush()<EMClientDelegate, EMChatManagerDelegate>

@end

@implementation HMPush

+ (instancetype)sharedPush
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        push = [[HMPush alloc] init];
    });
    return push;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
        [[EMClient sharedClient] addDelegate:self delegateQueue:nil];
    }
    return self;
}

- (void)messagesDidReceive:(NSArray *)aMessages
{
    for (EMMessage *msg in aMessages) {
        
        [self fireLocalNotification:msg];
    }

}

- (void)fireLocalNotification:(EMMessage *)msg
{
    // 1、创建UNMutableNotificationContent
    UNMutableNotificationContent *content = [self createNotificationContent:msg];
    
    // 3、 创建UNNotificationTrigger
    UNNotificationTrigger *trigger = [self createNotificationTrigger];
    
    // UNNotificationRequestIdentifier
    NSString *rqIdentifier = msg.ext[@"rqIdentifier"] ? msg.ext[@"rqIdentifier"] : msg.messageId;
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:rqIdentifier content:content trigger:trigger];
    
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        
        if (!error) {
            
            NSLog(@"You have a Local Notification !");
        }
    }];
}

#pragma mark - Create LocalNotification

// UNNotificationContent
- (UNMutableNotificationContent *)createNotificationContent:(EMMessage *)msg
{
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"You have a new Message !";
    content.subtitle = [NSString stringWithFormat:@"消息发送者是：%@",msg.from];
    content.body = [self getNotificationBodyFromMsg:msg];
    content.badge = @1;
    content.sound = [UNNotificationSound defaultSound];
    //用于回复消息
    NSDictionary *msgInfo = @{@"from":msg.from};
    content.userInfo = msgInfo;
    content.categoryIdentifier = @"Actionss";
    return content;
}
/**
 typedef NS_OPTIONS(NSUInteger, UNNotificationActionOptions) {
 
 // Whether this action should require unlocking before being performed.
 UNNotificationActionOptionAuthenticationRequired = (1 << 0),
 
 // Whether this action should be indicated as destructive.
 UNNotificationActionOptionDestructive = (1 << 1),
 
 // Whether this action should cause the application to launch in the foreground.
 UNNotificationActionOptionForeground = (1 << 2),
 } __IOS_AVAILABLE(10.0) __WATCHOS_AVAILABLE(3.0) __TVOS_PROHIBITED;
*/

#pragma mark - Register Category
// Normal Actions
+ (UNNotificationCategory *)registerNormalNotificationActions
{
    UNNotificationAction *unlockScreen = [UNNotificationAction actionWithIdentifier:kNormalActionUnlockScreenIdentifier title:NSLocalizedString(@"UnlockScreen", @"Unlock Screen") options:UNNotificationActionOptionAuthenticationRequired];
    UNNotificationAction *launchApp = [UNNotificationAction actionWithIdentifier:kNormalActionLaunchAppIdentifier title:NSLocalizedString(@"LaunchApp", @"Launch App") options:UNNotificationActionOptionForeground];
    UNNotificationAction *destructive = [UNNotificationAction actionWithIdentifier:kNormalActionDestructiveIdentifier title:NSLocalizedString(@"Destructive", @"Destructive") options:UNNotificationActionOptionDestructive];
    UNTextInputNotificationAction *textAction = [UNTextInputNotificationAction actionWithIdentifier:kTextInputActionIdentifier title:NSLocalizedString(@"title.input", @"Input") options:UNNotificationActionOptionForeground textInputButtonTitle:NSLocalizedString(@"Send", @"Send") textInputPlaceholder:NSLocalizedString(@"Input", @"Input here ...")];
    
    // Register Notification Category
    UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:kNormalNotificationCategotyIdentifier actions:@[unlockScreen, launchApp, destructive, textAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
    return category;
}

- (void) test {

}
// Text Input Action
+ (UNNotificationCategory *)registerTextInputNotificationAction
{
    UNTextInputNotificationAction *textAction = [UNTextInputNotificationAction actionWithIdentifier:kTextInputActionIdentifier title:@"Input" options:UNNotificationActionOptionNone textInputButtonTitle:NSLocalizedString(@"Send", @"Send") textInputPlaceholder:NSLocalizedString(@"Input", @"Input here ...")];
    // Register Notification Category
    UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:kTextInputNotificationCategotyIdentifier actions:@[textAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
    return category;
}

- (UNNotificationTrigger *)createNotificationTrigger
{
    // UNTimeIntervalNotificationTrigger
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:kDelaySeconds repeats:NO];
    
    // UNCalendarNotificationTrigger
//    NSDateComponents *components = [[NSDateComponents alloc] init];
//    components.weekday = 1;
//    components.hour = 15;
//    components.minute = 16;
//    UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:YES];
    
    // UNLocationNotificationTrigger
//    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(39.8715157295,116.3224821899);
//    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:center radius:500 identifier:@"Li Ze"];
//    region.notifyOnEntry = YES;
//    region.notifyOnExit = YES;
//    UNLocationNotificationTrigger *trigger = [UNLocationNotificationTrigger triggerWithRegion:region repeats:YES];
    return trigger;
}


#pragma mark - Local Notification

- (void)localNotification:(UNNotificationRequest *)request
{
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        
        if (!error) {
            
            NSLog(@"Good! Have a local Notification");
        }
    }];
}

- (NSString *)getNotificationBodyFromMsg:(EMMessage *)msg
{
    
    EMMessageBody *body = msg.body;
    NSString *bodyString = nil;
    switch (body.type) {
        case EMMessageBodyTypeText:
        {
            EMTextMessageBody *textBody = (EMTextMessageBody *)body;
            bodyString = textBody.text;
        }
            break;
        case EMMessageBodyTypeImage:
            bodyString = @"This is a Image Msg !";
            break;
            
        default:
            break;
    }
    return bodyString;
}
@end
