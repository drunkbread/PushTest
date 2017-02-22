//
//  NotificationViewController.m
//  ContentExtension
//
//  Created by EaseMob on 2017/2/16.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

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
//    self.preferredContentSize = CGSizeMake(CGRectGetWidth(self.view.frame), 160);
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
