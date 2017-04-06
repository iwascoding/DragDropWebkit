//
//  DropView.m
//  DragDropWebkit
//
//  Created by Paul Hecker on 06.04.2017.
//  Copyright © 2017 Paul Hecker. All rights reserved.
//

#import "DropView.h"
#import "Utilities.h"

#import "ViewController.h"


@interface DropView ()

@property CDEvents *webviewFileDragEvents;

@end

@implementation DropView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    [[NSColor whiteColor] setFill];
    [NSBezierPath fillRect:dirtyRect];
}

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)draggingInfo
{
    return NSDragOperationCopy;
}

-(NSDragOperation) draggingUpdated:(id<NSDraggingInfo>)draggingInfo
{
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)draggingInfo
{
    NSArray *types = [[draggingInfo draggingPasteboard] types];
    
    if ([types containsObject:NSFilenamesPboardType])
    {
        //  files are being dragged
        NSArray		*filePaths = [[draggingInfo draggingPasteboard] propertyListForType:NSFilenamesPboardType];
        
        for (NSString *filePath in filePaths)
        {
            [ViewController postUpdateLogViewNotificationWithText:[NSString stringWithFormat:@"########### --> Imported file %@", filePath]];
        }
        
        return YES;
    }
    else if ([types containsObject:NSFilesPromisePboardType])
    {
        __typeof__(self) __weak weakSelf = self;
        
        self.webviewFileDragEvents = [Utilities existingPathsOfPromisedFilesForDraggingInfo:draggingInfo
                                                                           importImageBlock:^(NSString *inFilePathURL, BOOL inFinished) {
                                                                               
                                                                               NSURL *fileURL = [NSURL URLWithString:inFilePathURL];
                                                                               [ViewController postUpdateLogViewNotificationWithText:[NSString stringWithFormat:@"########### --> Imported file %@", [fileURL path]]];
                                                                               
                                                                               if (inFinished)
                                                                               {
                                                                                   weakSelf.webviewFileDragEvents = nil;
                                                                               }
                                                                           }];
        
        return (nil != self.webviewFileDragEvents);
    }
    
    return NO;
}

@end
