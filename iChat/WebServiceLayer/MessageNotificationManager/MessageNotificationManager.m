//
//  MessageNotificationManager.m
//  iChat
//
//  Created by Tejasree Marthy on 07/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

#import "MessageNotificationManager.h"

@implementation MessageNotificationManager
#pragma mark - Message notification
    
+ (void)showNotificationWithTitle:(NSString*)title
                         subtitle:(NSString*)subtitle
                            color:(UIColor*)color
                        iconImage:(UIImage*)iconImage {
    
    //    [messageNotification() showNotificationWithTitle:title
    //                                            subtitle:subtitle
    //                                               color:color
    //                                           iconImage:iconImage];
}
    
+ (void)showNotificationWithTitle:(NSString*)title
                         subtitle:(NSString*)subtitle
                             type:(MessageNotificationType)type {
    
    UIImage *iconImage = nil;
    UIColor * backgroundColor = [UIColor redColor];
    
    switch (type) {
        case MessageNotificationTypeInfo: {
            iconImage = [UIImage imageNamed:@"icon-info"];
            backgroundColor = [UIColor colorWithRed:41.0/255.0 green:128.0/255.0 blue:255.0/255.0 alpha:1.0];
            break;
        }
        
        case MessageNotificationTypeWarning: {
            iconImage = [UIImage imageNamed:@"icon-error"];
            backgroundColor = [UIColor colorWithRed:241.0/255.0 green:196.0/255.0 blue:15.0/255.0 alpha:1.0];
            break;
        }
        
        case MessageNotificationTypeError: {
            iconImage = [UIImage imageNamed:@"icon-error"];
            backgroundColor = [UIColor colorWithRed:241.0/255.0 green:196.0/255.0 blue:15.0/255.0 alpha:1.0];
            break;
        }
        default:
        break;
    }
    
    if (!title) {
        title = @"";
    }
    
    if (!subtitle) {
        subtitle = @"";
    }
    
    [self showNotificationWithTitle:title
                           subtitle:subtitle
                              color:backgroundColor
                           iconImage:iconImage];
}
    
    
+ (void)oneByOneModeSetEnabled:(BOOL)enabled {
    //    messageNotification().oneByOneMode = enabled;
}
    
@end
