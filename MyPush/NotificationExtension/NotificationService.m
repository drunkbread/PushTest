//
//  NotificationService.m
//  NotificationExtension
//
//  Created by EaseMob on 2017/2/16.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "NotificationService.h"
#import <UIKit/UIKit.h>
@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {

    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    NSString *attchUrl = [request.content.userInfo objectForKey:@"image"];
    NSURL *url = [NSURL URLWithString:attchUrl];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
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

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.bestAttemptContent);
}

@end
