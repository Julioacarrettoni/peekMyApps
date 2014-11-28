//
//  ViewController.m
//  peekMyApps
//
//  Created by Julio Carrettoni on 11/28/14.
//  Copyright (c) 2014 Julio Carrettoni. All rights reserved.
//

#import "ViewController.h"
#import "AnAppTableViewCell.h"

@interface ViewController ()

@end

@implementation ViewController {
    
    __weak IBOutlet UILabel *statusLabel;
    __weak IBOutlet UIActivityIndicatorView *statusIndicator;
    
    __weak IBOutlet UILabel *numberOfAppsFound;
    
    __weak IBOutlet UITableView *foundAppsTableView;
    
    NSMutableDictionary* allFoundApps;
    NSOperationQueue* requestQueue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    requestQueue = [[NSOperationQueue alloc] init];
    
    requestQueue.maxConcurrentOperationCount = 3;
    requestQueue.qualityOfService = NSQualityOfServiceUtility;
    
    [self startScanning];
}

#pragma mark - scanning

- (void) startScanning {
    [self scanningDidStart];
    allFoundApps = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSDictionary* apps = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"app_store_app_data.json" ofType:nil]] options:0 error:nil];
        allFoundApps = [NSMutableDictionary dictionary];
        for (NSString* key in [apps allKeys]) {
            NSString* scheme = apps[key];
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:scheme]]) {
                allFoundApps[key] = [@{@"id" : key,
                                       @"scheme": scheme
                                       } mutableCopy];
                [self getExtraInfoForAppID:key];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
            [self scanningDidEnd];
        });
    });
}

- (void) getExtraInfoForAppID:(NSString*) appID {
    [requestQueue addOperationWithBlock:^{
        NSString* url = [NSString stringWithFormat:@"https://itunes.apple.com/%@/lookup?id=%@", [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode], appID];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        if (data) {
            NSDictionary* info = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray* results = info[@"results"];
            if ([results firstObject][@"artworkUrl60"]) {
                NSString* imageURL = [results firstObject][@"artworkUrl60"];
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURL] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
                NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                UIImage* image = [UIImage imageWithData:data];
                if (image) {
                    allFoundApps[appID][@"icon"] = image;
                }
            }
            if ([results firstObject][@"trackName"])
                allFoundApps[appID][@"name"] = [results firstObject][@"trackName"];
            if ([results firstObject][@"trackViewUrl"])
                allFoundApps[appID][@"trackViewUrl"] = [results firstObject][@"trackViewUrl"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadData];
            });
        }
    }];
}

- (void) scanningDidStart {
    statusLabel.text = @"Scaning your device";
    [statusIndicator startAnimating];
    statusIndicator.hidden = NO;
    numberOfAppsFound.text = @"-";
}

- (void) scanningDidEnd {
    statusLabel.text = @"Device Scanned";
    [statusIndicator stopAnimating];
    statusIndicator.hidden = YES;
    if (allFoundApps.count == 0) {
        numberOfAppsFound.text = @"0 Apps";
    }
    else if (allFoundApps.count == 1) {
        numberOfAppsFound.text = @"1 App";
    }
    else {
        numberOfAppsFound.text = [NSString stringWithFormat:@"%lu Apps", (unsigned long)allFoundApps.count];
    }
}

#pragma mark - UITableView
- (void) reloadData {
    [foundAppsTableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return allFoundApps.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AnAppTableViewCell* cell = (id)[tableView dequeueReusableCellWithIdentifier:@"AnAppTableViewCell"];
    [cell setAppInfo:allFoundApps[[allFoundApps allKeys][indexPath.row]]];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary* appInfo = allFoundApps[[allFoundApps allKeys][indexPath.row]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appInfo[@"scheme"]]];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSDictionary* appInfo = allFoundApps[[allFoundApps allKeys][indexPath.row]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appInfo[@"trackViewUrl"]]];
}

@end
