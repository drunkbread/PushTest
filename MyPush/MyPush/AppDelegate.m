//
//  AppDelegate.m
//  MyPush
//
//  Created by EaseMob on 2017/2/8.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>
#import <HyphenateLite/HyphenateLite.h>
#import "HMPush.h"
#import "MyPushHeader.h"
@interface AppDelegate ()<UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (NSClassFromString(@"UNUserNotificationCenter")) {
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    }
    
    [self _registerRemoteNotification];
    [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet setWithArray:@[[HMPush registerNormalNotificationActions]
//                                ,[HMPush registerTextInputNotificationAction]
                                                                                                          ]]];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [self _registerHyphenate];
    [HMPush sharedPush];
    [self _loginHyphenate];
    return YES;
}


#pragma mark - Init HyphenateSDK

- (void)_registerHyphenate {
    
    EMOptions *options = [EMOptions optionsWithAppkey:@"drunkbread#lif"];
    options.apnsCertName = @"pushH1";
    [[EMClient sharedClient] initializeSDKWithOptions:options];
}

- (void)_loginHyphenate {
    
    EMError *error = nil;
    error = [[EMClient sharedClient] loginWithUsername:@"realm10" password:@"1"];
    if (!error) {
        
        NSLog(@"Login Success !!!");
        [[EMClient sharedClient] getPushNotificationOptionsFromServerWithCompletion:^(EMPushOptions *aOptions, EMError *aError) {
            aOptions.displayStyle = EMPushDisplayStyleMessageSummary;
            [[EMClient sharedClient] updatePushOptionsToServer];
        }];
    } else {
        
        NSLog(@"Login Failed ~~");
    }
}

#pragma mark - Register Remote Notification

- (void)_registerRemoteNotification {
    
    UIApplication *application = [UIApplication sharedApplication];
    
    // iOS10
    if (NSClassFromString(@"UNUserNotificationCenter")) {

        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionBadge + UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            
            if (granted && !error) {
                
                [application registerForRemoteNotifications];
            }
        }];
        return;
    }
    // iOS8
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        
        UIUserNotificationType notificationTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
        [application registerUserNotificationSettings:settings];
    }
}

#pragma mark -  Fetch DeviceToken

//注册推送成功，返回devicetoken
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    NSLog(@"Get DeviceToken Success !!!---%@", [self deviceTokenString:deviceToken]);
    [[EMClient sharedClient] bindDeviceToken:deviceToken];
    
}

//注册推送失败，返回Error
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    
    NSLog(@"Register Remote Notification Failed , Error = %@", error.description);
}

- (NSString *)deviceTokenString:(NSData *)token
{
    return [[[[token description] stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
}

#pragma mark - Notification Handling

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    NSLog(@"willPresentNotification");
    
//    // 推送请求
//    UNNotificationRequest *request = notification.request;
//    // 内容
//    UNNotificationContent *content = request.content;
//    // 用户基本信息
//    NSDictionary *info = content.userInfo;
//    // 推送的badge
//    NSNumber *badge = content.badge;
//    // 推送消息的body
//    NSString *body = content.body;
//    // 推送 提示音
//    UNNotificationSound *sound = content.sound;
//    //推送 subtitle
//    NSString *subtitle = content.subtitle;
//    //推送 title
//    NSString *title = content.title;
    
    if ([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        // Remote Notification
    } else {
        //Local Notification
    }
    completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {

    [self handleNotificationResponse:response];
    [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
    completionHandler();
    
}

#pragma mark - Handle Notification



- (void)handleNotificationResponse:(UNNotificationResponse *)response
{
    NSString *categoryId = response.notification.request.content.categoryIdentifier;
    if ([categoryId isEqualToString:kNormalNotificationCategotyIdentifier]) {
    
        if ([response.actionIdentifier isEqualToString:kTextInputActionIdentifier]) {
            
            UNTextInputNotificationResponse *textResponse = (UNTextInputNotificationResponse *)response;
            if ([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
                
                // 收到远程推送
                NSLog(@"回复的内容是:%@",textResponse.userText);
            } else {
                // 本地通知 回复消息

                [self replyMessageWithNotificationResponse:textResponse];
            }
        }
        
        if ([response.actionIdentifier isEqualToString:kNormalActionUnlockScreenIdentifier]) {
            
            NSLog(@"Unlock Screen Clicked !!!");
        } else if ([response.actionIdentifier isEqualToString:kNormalActionLaunchAppIdentifier]) {
            
            NSLog(@"Launch App Clicked !!!");
        } else if ([response.actionIdentifier isEqualToString:kNormalActionDestructiveIdentifier]) {
            
            NSLog(@"Destructive Clicked !!!");
        }
    }
}

#pragma mark - Reply Message

- (void)replyMessageWithNotificationResponse:(UNTextInputNotificationResponse *)textResponse
{
    NSDictionary *userInfo = textResponse.notification.request.content.userInfo;
    NSString *targetUser = userInfo[@"from"];
    EMTextMessageBody *msgBody = [[EMTextMessageBody alloc] initWithText:textResponse.userText];
    EMMessage *msg = [[EMMessage alloc] initWithConversationID:targetUser from:[[EMClient sharedClient] currentUsername] to:targetUser body:msgBody ext:nil];
    [[EMClient sharedClient].chatManager sendMessage:msg progress:nil completion:^(EMMessage *message, EMError *error) {
        
        if (!error) {
            
            NSLog(@"Reply Message Success !");
        } else {
            
            NSLog(@"Reply Message Failed ! --> %u",error.code);
        }
    }];

}

- (void)applicationWillResignActive:(UIApplication *)application {
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {

    [[EMClient sharedClient] applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {

}

- (void)applicationWillTerminate:(UIApplication *)application {

}


@end
