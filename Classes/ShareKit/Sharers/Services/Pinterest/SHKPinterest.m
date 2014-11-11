//
//  SHKPinterest.m
//  ShareKit
//
//  Created by Vilém Kurz on 09/05/14.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "SHKPinterest.h"
#import "SharersCommonHeaders.h"
#import "SHKPinterestNoArc.h"

#ifdef COCOAPODS
#import "Pinterest.h"
#else
#import <Pinterest/Pinterest.h>
#endif


@implementation SHKPinterest

#pragma mark -
#pragma mark Configuration : Service Definition

+ (NSString *)sharerTitle { return SHKLocalizedString(@"Pinterest"); }

+ (BOOL)canShareURL { return YES; }

+ (BOOL)canShareItem:(SHKItem *)item {
 
    BOOL isOfImageType = item.URLContentType == SHKShareTypeImage && item.URL != nil;
    BOOL isOfWebPageType = item.URLContentType == SHKURLContentTypeWebpage && item.URL != nil;
    BOOL isPictureURI = item.URLPictureURI != nil;
    
    return isOfImageType || isOfWebPageType || isPictureURI;
}

+ (BOOL)requiresAuthentication { return NO; }

#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare {
    NSString *clientId = SHKCONFIG(pinterestClientId);
    return clientId && [[SHKPinterestNoArc pinterestWithClientId:clientId] canPinWithSDK];
}

#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
    SHKFormFieldLargeTextSettings *descriptionField = [SHKFormFieldLargeTextSettings label:SHKLocalizedString(@"Description") key:@"title" start:self.item.title item:self.item];
    return @[descriptionField];
}

#pragma mark -
#pragma mark Implementation

- (BOOL)validateItem {
    
    BOOL result = [super validateItem] && [SHKPinterest canShareItem:self.item];
    return result;
}

- (BOOL) send {
    // Make sure that the item has minimum requirements
	if (![self validateItem])
		return NO;
    
    NSString *clientId = SHKCONFIG(pinterestClientId);
    
    if (self.item.URLPictureURI) {
        [SHKPinterestNoArc createPinWithClientId:clientId
                                        imageURL:[self.item.URLPictureURI copy]
                                       sourceURL:[self.item.URL copy]
                                     description:[self.item.title copy]];
    } else {
        [SHKPinterestNoArc createPinWithClientId:clientId
                                        imageURL:[self.item.URL copy]
                                       sourceURL:nil
                                     description:[self.item.title copy]];
    }

    self.item = nil;

    return YES;
}

@end
