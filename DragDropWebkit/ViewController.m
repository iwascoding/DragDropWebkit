//
//  ViewController.m
//  DragDropWebkit
//
//  Created by Paul Hecker on 06.04.2017.
//  Copyright © 2017 Paul Hecker. All rights reserved.
//

#import "ViewController.h"
#import "Utilities.h"
#import "DropView.h"

#import <WebKit/WebKit.h>

NSString *const kUpdateLogViewNotification = @"UpdateLogView";
NSString *const kUpdateLogViewNotification_text = @"text";

@interface ViewController () <WebUIDelegate>

@property (weak) IBOutlet WebView *webview;
@property (weak) IBOutlet NSTextView *textView;
@property (weak) IBOutlet DropView *dropView;

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
    
    [self.dropView registerForDraggedTypes:@[NSTIFFPboardType, NSFilenamesPboardType, NSFilesPromisePboardType]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateLogViewNotification:)
                                                 name:kUpdateLogViewNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:kUpdateLogViewNotification
                                               object:nil];
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

+ (void) postUpdateLogViewNotificationWithText:(NSString*)inText
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateLogViewNotification
                                                        object:nil
                                                      userInfo:@{kUpdateLogViewNotification_text: inText}];
}

- (void)webView:(WebView *)sender willPerformDragDestinationAction:(WebDragDestinationAction)action forDraggingInfo:(id < NSDraggingInfo >)draggingInfo
{
    NSArray *files = nil;
    
    NSArray			*draggedURLStrings = nil;
    
    draggedURLStrings = [[draggingInfo draggingPasteboard] propertyListForType:NSURLPboardType];
    
    if (nil == draggedURLStrings)
    {
        __typeof__(self) __weak weakSelf = self;
        // we only want to show the error once!
        
        self.webviewFileDragEvents = [Utilities existingPathsOfPromisedFilesForDraggingInfo:draggingInfo
                                                                      importImageBlock:^(NSString *inFilePathURL, BOOL inFinished) {
                                                                          
                                                                          [[self class] postUpdateLogViewNotificationWithText:[NSString stringWithFormat:@"########### --> Imported file %@", inFilePathURL]];

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
                    NSString *urlString = [Utilities pathURLStringToDraggedPasteboardImage];
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
            NSString *urlString = [Utilities pathURLStringToDraggedPasteboardImage];
            if (urlString)
            {
                files = @[urlString];
            }
        }
    }

    if ([files count])
    {
        // we only want to show the error once!
        [[self class] postUpdateLogViewNotificationWithText:[NSString stringWithFormat:@"########### --> Imported files %@", files]];
    }
}

- (void) updateLogViewNotification:(NSNotification*)inNoti
{
    [self appendToMyTextView:[inNoti.userInfo[kUpdateLogViewNotification_text] stringByAppendingString:@"\n"]];
}

- (void)appendToMyTextView:(NSString*)text
{
    NSAssert([NSThread isMainThread], @"Not on main thread");
    
    NSAttributedString* attr = [[NSAttributedString alloc] initWithString:text];
    
    [[self.textView textStorage] appendAttributedString:attr];
    [self.textView scrollRangeToVisible:NSMakeRange([[self.textView string] length], 0)];
}

@end
