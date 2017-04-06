//
//  Utilities.m
//  DragDropWebkit
//
//  Created by Paul Hecker on 06.04.2017.
//  Copyright © 2017 Paul Hecker. All rights reserved.
//

#import "Utilities.h"
#import "ViewController.h"

#import "CDEvents.h"


@implementation Utilities

+ (CDEvents*) existingPathsOfPromisedFilesForDraggingInfo:(id<NSDraggingInfo>)draggingInfo
                                         importImageBlock:(void (^)(NSString *inFilePathURL, BOOL inFinished))block
{
    NSString        *path = [NSTemporaryDirectory() stringByAppendingString:@"GSDraggingUtilsPromisedFiles"];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
    
    NSArray         *draggedFileNames = [draggingInfo namesOfPromisedFilesDroppedAtDestination:[NSURL fileURLWithPath:path]];
    NSMutableArray  *draggedFileURLs = [[NSMutableArray alloc] init];
    
    for (NSString *name in draggedFileNames)
    {
        if (0 < [name length])
        {
            NSString    *filePath = [path stringByAppendingPathComponent:name];
            NSURL       *fileURL = [NSURL fileURLWithPath:filePath];
            
            if (nil != fileURL)
            {
                [draggedFileURLs addObject:fileURL];
            }
        }
    }
    
    if (0 < [draggedFileURLs count])
    {
        NSUInteger countOfURLs = [draggedFileURLs count];
        
        [ViewController postUpdateLogViewNotificationWithText:[NSString stringWithFormat:@"########### --> Starting promise for %@...", path]];

        return [[CDEvents alloc] initWithURLs:@[[NSURL fileURLWithPath:path]]
                                        block:^(CDEvents *watcher, CDEvent *event) {
                                            if ([draggedFileURLs containsObject:event.URL])
                                            {
                                                NSMutableArray *excluded = [[NSMutableArray alloc] initWithObjects:event.URL, nil];
                                                if (0 < [watcher.excludedURLs count])
                                                {
                                                    [excluded addObjectsFromArray:watcher.excludedURLs];
                                                }
                                                watcher.excludedURLs = [excluded copy];
                                                
                                                block([event.URL absoluteString], ([watcher.excludedURLs count] == countOfURLs));
                                            }
                                        }
                                    onRunLoop:[NSRunLoop currentRunLoop]
                         sinceEventIdentifier:kCDEventsSinceEventNow
                         notificationLantency:CD_EVENTS_DEFAULT_NOTIFICATION_LATENCY
                      ignoreEventsFromSubDirs:CD_EVENTS_DEFAULT_IGNORE_EVENT_FROM_SUB_DIRS
                                  excludeURLs:nil
                          streamCreationFlags:(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)];
    }
    
    return nil;
}

+ (NSString *) pathURLStringToDraggedPasteboardImage
{
    (void)[[NSPasteboard generalPasteboard] types];
    NSData *data = [[NSPasteboard pasteboardWithName:NSDragPboard] dataForType:@"public.tiff"];
    
    if ( [data length] == 0 )
        return nil;
    
    NSString *filename = [[[NSUUID UUID] UUIDString] stringByAppendingPathExtension:@"tiff"];
    NSString     *path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    
    BOOL success = [data writeToFile:path atomically:YES];
    
    if (success)
    {
        NSURL *url = [NSURL fileURLWithPath:path];
        return [url absoluteString];
    }
    
    return nil;
}

@end
