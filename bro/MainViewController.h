//
//  MainViewController.h
//  bro
//
//  Created by Yuriy Paterega on 17.08.15.
//  Copyright (c) 2015 Yuriy Paterega. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
@interface MainViewController : UIViewController<UIWebViewDelegate,
NSURLConnectionDelegate,
NSURLConnectionDataDelegate>


@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;


@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UITextField *urlField;

- (IBAction)loadLocation:(id)sender;
- (IBAction)shortenURL:(id)sender;
- (IBAction)clipboardURL:(id)sender;


@property (weak,nonatomic) IBOutlet UIBarButtonItem *shortenButton;
@property (weak,nonatomic) IBOutlet UIBarButtonItem *shortLabel;
@property (weak,nonatomic) IBOutlet UIBarButtonItem *clipboardButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addToBd;

@property (strong) NSManagedObject *urlAdress;
@end
