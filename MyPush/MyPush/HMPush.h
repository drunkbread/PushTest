//
//  HMPush.h
//  MyPush
//
//  Created by EaseMob on 2017/2/9.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface HMPush : NSObject
+ (instancetype)sharedPush;
+ (UNNotificationCategory *)registerNormalNotificationActions;
+ (UNNotificationCategory *)registerTextInputNotificationAction;
@end
