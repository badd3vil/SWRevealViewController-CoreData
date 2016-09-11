//
//  MainViewController.m
//  bro
//
//  Created by Yuriy Paterega on 17.08.15.
//  Copyright (c) 2015 Yuriy Paterega. All rights reserved.
//


#import "MainViewController.h"
#import "SWRevealViewController.h"
#import "DataView.h"
@interface MainViewController ()
{
    NSURLConnection *shortenURLConnection;
    NSMutableData *shortURLData;
    
}

@end

@implementation MainViewController

@synthesize urlAdress;


- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

- (void)viewDidLoad {
   
    self.addToBd.enabled = NO;
    self.title = @"Browser";

    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    

    [super viewDidLoad];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark Actions

- (IBAction)loadLocation:(id)sender
{
    // Received when the user finished editing the URL text field by clicking
    //	on the "Go" button in the keyboard, or when they tap on the Reload button
    //	in the navigation toolbar.
    NSString *urlText = self.urlField.text;
    
    // If the user was lazy and didn't start their URL with http:// or https://
    //	insert "http://" for them.
    if (![urlText hasPrefix:@"http:"] && ![urlText hasPrefix:@"https:"])
    {
        if (![urlText hasPrefix:@"//"])
            urlText = [@"//" stringByAppendingString:urlText];
        urlText = [@"http:" stringByAppendingString:urlText];
    }
    
    // Create an URL object from the address the user typed in
    NSURL *url = [NSURL URLWithString:urlText];
    
    // Construct an URL request from that URL and tell the web view to load the page
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (IBAction)shortenURL:(id)sender
{
    // Received when the user taps the "Shorten" button in the bottom toolbar
    // Start by constructing the URL that's going to be sent to the service:
   
    NSString *urlToShorten = self.webView.request.URL.absoluteString;
    NSString *urlString = [NSString stringWithFormat:@"http://to.ly/api.php?longurl=%@",
                           [urlToShorten stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
    // Clear the response buffer
    shortURLData = [NSMutableData new];
    
    // Turn the request string into an URL object, use the URL object to create a request object, and then
    //	start an NSURLConnection using that request.
    // When -connectionWithRequest:delegate: returns, an HTTP request to the URL shortening service
    //	has already started. The object in the delegate parameter will receive messages as the
    //	response is collected.
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    shortenURLConnection = [NSURLConnection connectionWithRequest:request
                                                         delegate:self];
    
    // "Debounce" the shorten URL button by disabling it as soon as a request is started.
    // This prevents the user from accidentially starting several requests simultaniously.
    self.shortenButton.enabled = NO;
    self.addToBd.enabled = YES;
}

- (IBAction)clipboardURL:(id)sender
{
    // Sent when the user taps the "Copy" button in the toolbar.
    // Transfer the shortened URL to the system clipboard, so the user can
    //	paste it in somewhere else.
        
    // Get the shortened URL, turn it into an URL object
    NSString *shortURLString = self.shortLabel.title;
    NSURL *shortURL = [NSURL URLWithString:shortURLString];
    
    if (!shortURL) {
        NSLog(@"Error loading: %@");
        return;
    } else {
        NSLog(@"Success loading: %@", shortURL);
    }
    
    // Transfer the value of the URL to the pasteboard (aka clipboard)
    [[UIPasteboard generalPasteboard] setURL:shortURL];
}

#pragma mark <UIWebViewDelegate>

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    // Received when the web view starts to load a page
    
    // Disable the "shorten it" button until the page is finished loading
    self.shortenButton.enabled = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // Received when the web view finishes loading a page
    
    // Stop the "is loading" animation
    //	[self stopLoadAnimation];
    
    // Enable the button to turn this (succesfully loaded) URL into a shorter one
    self.shortenButton.enabled = YES;
    
    // Update the URL in the text field to reflect what was actually loaded.
    self.urlField.text = webView.request.URL.absoluteString;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // Received if the web view couldn't load the page for some reason
    NSString *message = [NSString stringWithFormat:@"A problem occurred trying to load this page: %@",
                         error.localizedDescription];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Could not load URL"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"That's Sad"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark <NSURLConnectionDelegate>

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // Received if an error occurs with the URL shorten request.
    // This is unlikely, and there's not much that can be done about it.
    
    // Replace the short url with an error message
    self.shortLabel.title = @"failed";
    
    // Disable the "copy" button; there's nothing to copy
    self.clipboardButton.enabled = NO;
    
    // Reenable the shorten button (so they can try again, if they want)
    self.shortenButton.enabled = YES;
    
    
    
 
}

#pragma mark <NSURLConnectionDataDelegate>

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Received as each chunk of data is recieved from the URL shortening service.
    // The only thing the X.co service sends back, in the body of the response,
    //	is the text of the short URL, so it's unlikely this would be called more
    //	than once. If, however, your app requested a large amount of data (a whole
    //	web page, for example), this message would be recieved multiple times as
    //	the data downloaded.
    
    [shortURLData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Received when the short URL service request is finished.
    // The data in the shortURLData object now contains text of the short URL.
    
    // Success!
    // The response from the URL shortening service has been recieved.
    // Extract the response and udpate the interface.
    
    // Convert the raw bytes received from the web server into a string object
    NSString *shortURLString = [[NSString alloc] initWithData:shortURLData encoding:NSUTF8StringEncoding];
    
    // Show the results in the bottom toolbar
    self.shortLabel.title = shortURLString;
    // Enable the copy to clipboard b	utton
    self.clipboardButton.enabled = YES;
}

- (IBAction)save:(id)sender {
    NSManagedObjectContext *context = [self managedObjectContext];
    
    
  
    
    if (self.urlAdress) {
        // Update existing device
        [self.urlAdress setValue:self.urlField.text forKey:@"longUrl"];
        [self.urlAdress setValue:self.shortLabel.title forKey:@"shortUrl"];

        
    } else {
        // Create a new device
        NSManagedObject *newUrl = [NSEntityDescription insertNewObjectForEntityForName:@"Url" inManagedObjectContext:context];
        [newUrl setValue:self.urlField.text forKey:@"longUrl"];
        [newUrl setValue:self.shortLabel.title forKey:@"shortUrl"];
        }
    
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
        self.addToBd.enabled = NO;
}


@end
