//
//  ViewController.m
//  DragDropWebkit
//
//  Created by Paul Hecker on 06.04.2017.
//  Copyright © 2017 Paul Hecker. All rights reserved.
//

#import "ViewController.h"

#import <WebKit/WebKit.h>


@interface ViewController () <WebUIDelegate>

@property (weak) IBOutlet WebView *webview;
@property (weak) IBOutlet NSTextView *textView;

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


@end
