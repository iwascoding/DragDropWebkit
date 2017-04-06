//
//  Utilities.h
//  DragDropWebkit
//
//  Created by Paul Hecker on 06.04.2017.
//  Copyright © 2017 Paul Hecker. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CDEvents;

@interface Utilities : NSObject

+ (CDEvents*) existingPathsOfPromisedFilesForDraggingInfo:(id<NSDraggingInfo>)draggingInfo
                                         importImageBlock:(void (^)(NSString *inFilePathURL, BOOL inFinished))block;

+ (NSString *) pathURLStringToDraggedPasteboardImage;

@end
