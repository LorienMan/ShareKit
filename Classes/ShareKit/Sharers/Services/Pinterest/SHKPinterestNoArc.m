#import "SHKPinterestNoArc.h"

#ifdef COCOAPODS
#import "Pinterest.h"
#else
#import <Pinterest/Pinterest.h>
#endif

@implementation SHKPinterestNoArc

+ (void)createPinWithClientId:(NSString *)clientId
                     imageURL:(NSURL *)imageURL
                    sourceURL:(NSURL *)sourceURL
                  description:(NSString *)descriptionText {

    Pinterest *pinterest = [[Pinterest alloc] initWithClientId:clientId];
    [pinterest createPinWithImageURL:imageURL
                           sourceURL:sourceURL
                         description:descriptionText];
}

+ (Pinterest *)pinterestWithClientId:(NSString *)clientId {
    return [[Pinterest alloc] initWithClientId:clientId];
}

@end
