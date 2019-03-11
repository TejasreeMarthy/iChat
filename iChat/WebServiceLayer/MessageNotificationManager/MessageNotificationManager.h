//
//  MessageNotificationManager.h
//  iChat
//
//  Created by Tejasree Marthy on 07/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

typedef NS_ENUM (NSUInteger, MessageNotificationType) {
    MessageNotificationTypeInfo = 0,
    MessageNotificationTypeWarning = 1,
    MessageNotificationTypeError = 2
};

NS_ASSUME_NONNULL_BEGIN

@interface MessageNotificationManager : NSObject
    /**
     *  Show notification with title, subtitle and type
     *
     *  @param title    Notification title
     *  @param subtitle Notification subtitle
     */
+ (void)showNotificationWithTitle:(NSString*)title
                         subtitle:(NSString*)subtitle
                             type:(MessageNotificationType)type;
    
    /**
     *  Show notification with title, subtitle and custom parameters
     *
     *  @param title    Notification title
     *  @param subtitle Notification subtitle
     *  @param color    Notification background color
     *  @param iconImage Notification icon image
     */
+ (void)showNotificationWithTitle:(NSString*)title
                         subtitle:(NSString*)subtitle
                            color:(UIColor*)color
                        iconImage:(UIImage*)iconImage;
    /**
     *  Enable or disable oneByOne notification mode
     *
     *
     */
+ (void)oneByOneModeSetEnabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
