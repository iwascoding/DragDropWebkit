//
//  ViewController.h
//  DragDropWebkit
//
//  Created by Paul Hecker on 06.04.2017.
//  Copyright © 2017 Paul Hecker. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *const kUpdateLogViewNotification;

@interface ViewController : NSViewController

+ (void) postUpdateLogViewNotificationWithText:(NSString*)inText;

@end

