/*
 
 Copyright (c) 2012, SMB Phone Inc.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those
 of the authors and should not be interpreted as representing official policies,
 either expressed or implied, of the FreeBSD Project.
 
 */

#import "WebLoginViewController.h"
#import "LoginManager.h"
#import "OpenPeer.h"
#import "ActivityIndicatorViewController.h"
#import "Constants.h"
#import "Utility.h"
#import <OpenpeerSDK/HOPIdentity.h>
#import <OpenpeerSDK/HOPAccount.h>

@interface WebLoginViewController()

@property (nonatomic) BOOL outerFrameInitialised;
@property (nonatomic, weak) id coreObject;
@end

@implementation WebLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.outerFrameInitialised = NO;
    }
    return self;
}

- (id)init
{
    self = [self initWithCoreObject:nil];
    return self;
}

- (id) initWithCoreObject:(id) inCoreObject
{
    self = [self initWithNibName:@"WebLoginViewController" bundle:nil];
    if (self)
    {
        self.coreObject = inCoreObject;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) openLoginUrl:(NSString*) url
{
    NSLog(@"Web request initiated by sample app. URL: %@",url);
    [self.loginWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

- (void) passMessageToJS:(NSString*) message
{
    NSLog(@"\n\n Message to JS: \n %@ \n\n",message);
    [self.loginWebView stringByEvaluatingJavaScriptFromString:message];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *requestString = [[request URL] absoluteString];
    NSLog(@"Web request: %@", requestString);
    
    //Check if request contains JSON message for core
    if ([requestString hasPrefix:@"https://datapass.hookflash.me/?method="] || [requestString hasPrefix:@"http://datapass.hookflash.me/?method="])
    {
        NSString *function = [Utility getFunctionNameForRequest:requestString];
        NSString *params = [Utility getParametersNameForRequest:requestString];

        params = [params stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        if ([function length] > 0 && [params length] > 0)
        {
            NSString *functionNameSelector = [NSString stringWithFormat:@"%@:", function];
            //Execute JSON parsing in function read from requestString.
            if ([self respondsToSelector:NSSelectorFromString(functionNameSelector)])
                [self performSelector:NSSelectorFromString(functionNameSelector) withObject:params];
        }
        return NO;
    }

    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSString *requestString = [[[webView request] URL] absoluteString];
    
    NSLog(@"START LOADING - web request: %@", requestString);
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *requestString = [[[webView request] URL] absoluteString];
    
    NSLog(@"FINISH LOADING - web request: %@", requestString);
    
    if (!self.outerFrameInitialised && [requestString isEqualToString:outerFrameURL])
    {
        NSLog(@"FINISH LOADING - outerFrameURL: %@", outerFrameURL);
        self.outerFrameInitialised = YES;
        [self onOuterFrameLoaded];
    }
    else if (!self.outerFrameInitialised && [requestString isEqualToString:namespaceGrantServiceURL])
    {
        NSLog(@"FINISH LOADING - namespaceGrantServiceURL: %@", namespaceGrantServiceURL);
        self.outerFrameInitialised = YES;
        [self onOuterFrameLoaded];
    }
    else
    {
        NSLog(@"FINISH LOADING - NOTHING");
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"UIWebView _ERROR_ : %@",[error localizedDescription]);
}


- (void)notifyClient:(NSString *)message
{
    NSLog(@"\n\n Message from JS: \n %@ \n\n",message);
    
    if ([self.coreObject isKindOfClass:[HOPIdentity class]])
    {
        [(HOPIdentity*)self.coreObject handleMessageFromInnerBrowserWindowFrame:message];
    }
    else if ([self.coreObject isKindOfClass:[HOPAccount class]])
    {
        [(HOPAccount*)self.coreObject handleMessageFromInnerBrowserWindowFrame:message];
    }
}

- (void)onOuterFrameLoaded
{
    NSString* jsMethod = nil;
    
    if ([self.coreObject isKindOfClass:[HOPIdentity class]])
    {
        jsMethod = [NSString stringWithFormat:@"initInnerFrame(\'%@\')",[(HOPIdentity*)self.coreObject getInnerBrowserWindowFrameURL]];
    }
    else if ([self.coreObject isKindOfClass:[HOPAccount class]])
    {
        jsMethod = [NSString stringWithFormat:@"initInnerFrame(\'%@\')",[(HOPAccount*)self.coreObject getInnerBrowserWindowFrameURL]];
    }
    
    if (jsMethod)
        [self passMessageToJS:jsMethod];
}
@end
