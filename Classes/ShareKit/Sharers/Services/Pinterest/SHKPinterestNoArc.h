#import <Foundation/Foundation.h>

@class Pinterest;


@interface SHKPinterestNoArc : NSObject

+ (void)createPinWithClientId:(NSString *)clientId imageURL:(NSURL *)imageURL sourceURL:(NSURL *)sourceURL description:(NSString *)descriptionText;

+ (Pinterest *)pinterestWithClientId:(NSString *)clientId;

@end
