//
//  SHKGooglePlus.m
//  ShareKit
//
//  Created by CocoaBob on 12/31/12.
//
//

#import "SHKGooglePlus.h"

#import "SharersCommonHeaders.h"

#import <GooglePlus/GPPSignIn.h>
#import "GTLPlusPerson.h"

#define ALLOWED_VIDEO_SIZE 1037741824 //1GB in Bytes
#define ALLOWED_IMAGE_SIZE 37748736 //36MB in Bytes

@interface SHKGooglePlus ()

@property BOOL isDisconnecting;

@end

@implementation SHKGooglePlus {
    BOOL _originalQuiet;
    BOOL _pendingAuth;
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle {	return SHKLocalizedString(@"Google+"); }

+ (BOOL)canShareURL { return YES; }
+ (BOOL)canShareText { return YES; }
+ (BOOL)canShareImage { return YES; }
+ (BOOL)canShareFile:(SHKFile *)file {
    
    BOOL isAllowedVideo = [file.mimeType hasPrefix:@"video"] && file.size < ALLOWED_VIDEO_SIZE;
    BOOL isAllowedImage = [file.mimeType hasPrefix:@"image"] && file.size < ALLOWED_IMAGE_SIZE;
    if (isAllowedVideo || isAllowedImage) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)canShareOffline { return NO; }
+ (BOOL)canAutoShare { return NO; }

#pragma mark -
#pragma mark Life Cycles

- (id)init {
    
    self = [super init];
    if (self) {
        
        [[GPPSignIn sharedInstance] setClientID:SHKCONFIG(googlePlusClientId)];
        [[GPPSignIn sharedInstance] setShouldFetchGooglePlusUser:YES];
    }
    return self;
}

#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized {
    
    BOOL alreadyAuthenticated = [[GPPSignIn sharedInstance] authentication] != nil;
    BOOL result = alreadyAuthenticated;
    
    if (!alreadyAuthenticated) {
        result = [[GPPSignIn sharedInstance] hasAuthInKeychain];
    }
    
	return result;
}

- (void)authorizationFormShow {
    
    [self saveItemForLater:SHKPendingShare];
    
    [[GPPSignIn sharedInstance] setDelegate:self];
    [[GPPSignIn sharedInstance] authenticate];

    _pendingAuth = YES;
}

+ (void)logout {

    SHKGooglePlus *sharer = (SHKGooglePlus *)[[GPPSignIn sharedInstance] delegate];
    if (!sharer) {
        
        sharer = [[SHKGooglePlus alloc] init];
        [[GPPSignIn sharedInstance] setDelegate:sharer];
        [[SHK currentHelper] keepSharerReference:sharer];
    }
    
    sharer.isDisconnecting = YES;
    [[GPPSignIn sharedInstance] disconnect];
}

+ (NSString *)username {
    
    GTLPlusPerson *loggedUser = [[GPPSignIn sharedInstance] googlePlusUser];
    NSString *result = loggedUser.displayName;
    return result;
}

#pragma mark - GPPSignInDelegate methods

// The authorization has finished and is successful if |error| is |nil|.
- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error {
    
    if (!error) {
        [self authDidFinish:YES];
        [self restoreItem];
        [self tryPendingAction];
    } else {
        [self authDidFinish:NO];
        SHKLog(@"auth error: %@", [error description]);
        if (error.code == 400) {//400 = "invalid_grant"
            [self promptAuthorization];
        }
        
    }
    if (!self.isDisconnecting) {
        [GPPSignIn sharedInstance].delegate = nil;
        [[SHK currentHelper] removeSharerReference:self]; //ref will be removed in didDisconnectWithError: if logoff is in progress
    }
}

- (void)didDisconnectWithError:(NSError *)error {
    if (error) {
        SHKLog(@"Google plus could not disconnect with error: %@", error);
    } else {
        [self authDidFinish:NO]; //refresh UI
    }
    [GPPSignIn sharedInstance].delegate = nil;
    [[SHK currentHelper] removeSharerReference:self];
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send {
    
    //item validation is not needed, as GPPShareBuilder can be empty.
    
    [[GPPShare sharedInstance] setDelegate:self];
    id<GPPShareBuilder> mShareBuilder = [[GPPShare sharedInstance] nativeShareDialog];
    
    [mShareBuilder setPrefillText:self.item.text];
    
    switch ([self.item shareType]) {
        case SHKShareTypeURL:
            [mShareBuilder setURLToShare:self.item.URL];
            break;
        case SHKShareTypeText:
            break;
        case SHKShareTypeImage:
            [(id<GPPNativeShareBuilder>)mShareBuilder attachImage:self.item.image];
            break;
        case SHKShareTypeFile:
            if ([self.item.file.mimeType hasPrefix:@"image"]) {
                [(id<GPPNativeShareBuilder>)mShareBuilder attachImageData:[self.item.file data]];
            } else { //video
                [(id<GPPNativeShareBuilder>)mShareBuilder attachVideoURL:self.item.file.URL];
            }
            break;
        default:
            return NO;
            break;
    }
    _originalQuiet = self.quiet;
    self.quiet = YES; //if user cancels, on return blinks activity indicator. This disables it, as we share in safari and it is hidden anyway
    [self sendDidStart];
    
    BOOL dialogOpenedSuccessfully = [mShareBuilder open];
    if (dialogOpenedSuccessfully) {
        [[SHK currentHelper] keepSharerReference:self];
    }
    return dialogOpenedSuccessfully;
}

#pragma mark -
#pragma mark GPPShareDelegate

// Reports the status of the share action, |shared| is |YES| if user has
// successfully shared her post, |NO| otherwise, e.g. user canceled the post.
- (void)finishedSharing:(BOOL)shared {
    
    if (shared) { 
        self.quiet = _originalQuiet;
        [self sendDidFinish];
    } else {
        [self sendDidCancel];
    }
    [[SHK currentHelper] removeSharerReference:self];
}

#pragma mark -

+ (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if (![[GPPSignIn sharedInstance] delegate] || ![[GPPShare sharedInstance] delegate]) {
        
        //the sharer does not exist anymore after safari trip. We have to recreate it so that delegate methods are called.
        SHKGooglePlus *gPlusSharer = [[SHKGooglePlus alloc] init];
        [[GPPSignIn sharedInstance] setDelegate:gPlusSharer];
        [[GPPShare sharedInstance] setDelegate:gPlusSharer];
        
        //otherwise the sharer would be deallocated prematurely and delegate methods might not be called. The reference is removed in delegate methods, see finishedSharing: or finishedWithAuth:error:.
        [[SHK currentHelper] keepSharerReference:gPlusSharer];
    }

    ((SHKGooglePlus *)[[GPPSignIn sharedInstance] delegate])->_pendingAuth = NO;

    BOOL result = [GPPURLHandler handleURL:url sourceApplication:sourceApplication annotation:annotation];
    return result;
}

+ (void)handleDidBecomeActive {
    if ([GPPSignIn sharedInstance].delegate) {
        [(SHKGooglePlus *)[GPPSignIn sharedInstance].delegate handleDidBecomeActive];
    }
}

- (void)handleDidBecomeActive {
    if (_pendingAuth) {
        [self authDidFinish:NO];
        _pendingAuth = NO;
    }
}

@end
