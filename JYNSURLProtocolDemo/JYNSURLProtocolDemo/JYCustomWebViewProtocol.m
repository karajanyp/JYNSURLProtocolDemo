//
//  JYCustomWebViewProtocol.m
//  JYNSURLProtocolDemo
//
//  Created by James Yu on 15/8/25.
//  Copyright (c) 2015年 James. All rights reserved.
//

#import "JYCustomWebViewProtocol.h"
#import <UIKit/UIKit.h>
#import "SDWebImageManager.h"
#import "UIImage+MultiFormat.h"
#import "NSData+ImageContentType.h"
#import "UIImage+GIF.h"

static NSString * const hasInitKey = @"JYCustomWebViewProtocolKey";

@interface JYCustomWebViewProtocol ()

@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation JYCustomWebViewProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([request.URL.scheme isEqualToString:@"http"]) {
        NSString *str = request.URL.path;

        if (([str hasSuffix:@".png"] || [str hasSuffix:@".jpg"] || [str hasSuffix:@".gif"])
            && ![NSURLProtocol propertyForKey:hasInitKey inRequest:request]) {
            
            return YES;
        }
    }
    
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];

    return mutableReqeust;
}

- (void)startLoading
{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    
    // prevent recursive call
    [NSURLProtocol setProperty:@YES forKey:hasInitKey inRequest:mutableReqeust];
    
    //check if we already have cache image
//    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL];
//    NSData *data = [[SDImageCache sharedImageCache] diskImageDataBySearchingAllPathsForKey:key];
    
//    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"bd_logo" ofType:@"png"];
//    NSData *data = [NSData dataWithContentsOfFile:imagePath];
    
    UIImage *image = [UIImage imageNamed:@"bd_logo.png"];
    NSData *data = UIImagePNGRepresentation(image);

    if (data) {
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:mutableReqeust.URL
                                                            MIMEType:[NSData sd_contentTypeForImageData:data]
                                               expectedContentLength:data.length
                                                    textEncodingName:nil];
        [self.client URLProtocol:self
              didReceiveResponse:response
              cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        
        [self.client URLProtocol:self didLoadData:data];
        [self.client URLProtocolDidFinishLoading:self];
    }
    else {
        self.connection = [NSURLConnection connectionWithRequest:mutableReqeust delegate:self];
    }
}

- (void)stopLoading
{
    [self.connection cancel];
}

#pragma mark- NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    [self.client URLProtocol:self didFailWithError:error];
}

#pragma mark - NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.responseData = [[NSMutableData alloc] init];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    UIImage *cacheImage = [UIImage sd_imageWithData:self.responseData];
    // cache our image
    [[SDImageCache sharedImageCache] storeImage:cacheImage
                           recalculateFromImage:NO
                                      imageData:self.responseData
                                         forKey:[[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL]
                                         toDisk:YES];
    
    [self.client URLProtocolDidFinishLoading:self];
}

@end
