//
//  ViewController.m
//  DragDropWebkit
//
//  Created by Paul Hecker on 06.04.2017.
//  Copyright © 2017 Paul Hecker. All rights reserved.
//

#import "ViewController.h"
#import "CDEvents.h"

#import <WebKit/WebKit.h>

@interface ViewController () <WebUIDelegate>

@property (weak) IBOutlet WebView *webview;
@property (weak) IBOutlet NSTextView *textView;

@property CDEvents *webviewFileDragEvents;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString    *path = [[NSBundle mainBundle] pathForResource:@"webview" ofType:@"html"];
    NSData      *data = [NSData dataWithContentsOfFile:path];
    
    [[self.webview mainFrame] loadData:data
                              MIMEType:@"text/html"
                      textEncodingName:@"UTF-8"
                               baseURL:[NSURL fileURLWithPath:[path stringByDeletingLastPathComponent]]];
}

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (NSString*)targetElementSrcInWebView:(WebView *)sender
                        forDragginInfo:(id < NSDraggingInfo >)draggingInfo
{
    // hit object
    NSPoint         locationInSelf = [sender convertPoint:[draggingInfo draggingLocation] fromView:nil];
    NSDictionary    *hitElementDict = [sender elementAtPoint:locationInSelf];
    DOMElement      *hitElement = [hitElementDict objectForKey:@"WebElementDOMNode"];
    
    if ([hitElement isKindOfClass:[DOMHTMLImageElement class]])
    {
        DOMHTMLImageElement *imageElement = (DOMHTMLImageElement*) hitElement;
        NSString            *imageElementSrc = [[imageElement src] stringByRemovingPercentEncoding];
        
        return imageElementSrc;
    }
    
    return nil;
}

- (void)webView:(WebView *)sender willPerformDragDestinationAction:(WebDragDestinationAction)action forDraggingInfo:(id < NSDraggingInfo >)draggingInfo
{
    NSArray *files = nil;
    NSString *targetImageElementSrc = [self targetElementSrcInWebView:sender forDragginInfo:draggingInfo];
    
    NSArray			*draggedURLStrings = nil;
    
    draggedURLStrings = [[draggingInfo draggingPasteboard] propertyListForType:NSURLPboardType];
    
    if (nil == draggedURLStrings)
    {
        __typeof__(self) __weak weakSelf = self;
        // we only want to show the error once!
        
        self.webviewFileDragEvents = [self existingPathsOfPromisedFilesForDraggingInfo:draggingInfo
                                                                      importImageBlock:^(NSString *inFilePathURL, BOOL inFinished) {
                                                                          
                                                                          NSLog(@"########### --> Imported file %@", inFilePathURL);

                                                                          if (inFinished)
                                                                          {
                                                                              weakSelf.webviewFileDragEvents = nil;
                                                                          }
                                                                      }];
        if (nil != self.webviewFileDragEvents)
        {
            // the import of the file will be done in the event block
            return;
        }
    }
    
    if (nil != draggedURLStrings)
    {
        NSMutableArray	*fileURLs = [NSMutableArray array];
        
        for (NSString *dragURLString in draggedURLStrings)
        {
            if ([dragURLString length]) // filter out zero length URLS
            {
                NSURL *url = [NSURL URLWithString:dragURLString];
                
                if (![url isFileURL])
                {
                    NSString *urlString = [self pathURLStringToDraggedPasteboardImage];
                    if (urlString)
                    {
                        [fileURLs addObject:urlString];
                    }
                }
                else
                {
                    [fileURLs addObject:dragURLString];
                }
            }
        }
        files = fileURLs;
    }
    else
    {
        if (nil != [[draggingInfo draggingPasteboard] dataForType:NSTIFFPboardType])
        {
            NSString *urlString = [self pathURLStringToDraggedPasteboardImage];
            if (urlString)
            {
                files = @[urlString];
            }
        }
    }

    if ([files count])
    {
        // we only want to show the error once!
        NSLog(@"########### --> Imported files %@", files);
    }
}

- (CDEvents*) existingPathsOfPromisedFilesForDraggingInfo:(id<NSDraggingInfo>)draggingInfo
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

- (NSString *) pathURLStringToDraggedPasteboardImage
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
