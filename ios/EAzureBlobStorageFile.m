#import "EAzureBlobStorageFile.h"
#import <AZSClient/AZSClient.h>

NSString *ACCOUNT_NAME = @"account_name";
NSString *ACCOUNT_KEY = @"account_key";
NSString *CONTAINER_NAME = @"container_name";
NSString *CONNECTION_STRING = @"connection_string";


static NSString *const _filePath = @"filePath";
static NSString *const _contentType = @"contentType";
static NSString *const _fileName = @"fileName";

@implementation EAzureBlobStorageFile


RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(uploadFile:(NSDictionary *)options
                 findEventsWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject progress:(RCTResponseSenderBlock)responseProgress)
{
    [self uploadBlobToContainer: options rejecter:reject resolver:resolve progress:responseProgress];
}

-(NSString *)genRandStringLength:(int)len {
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyz";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    return randomString;
}

-(void)uploadBlobToContainer:(NSDictionary *)options rejecter:(RCTPromiseRejectBlock)reject resolver:(RCTPromiseResolveBlock)resolve progress:(RCTResponseSenderBlock)responseProgress{
    NSError *accountCreationError;

    
    NSString *fileName = @"";
    NSString *contentType = @"image/png";
    NSString *filePath = @"";
    if ([options valueForKey:_fileName] != [NSNull null]) {
        fileName = [options valueForKey:_fileName];
    }

    if ([options valueForKey:_contentType] != [NSNull null]) {
        contentType = [options valueForKey:_contentType];
    }

    if ([options valueForKey:_filePath] != [NSNull null]) {
        filePath = [options valueForKey:_filePath];
    }

    
    // Create a storage account object from a connection string.
    AZSCloudStorageAccount *account = [AZSCloudStorageAccount accountFromConnectionString:CONNECTION_STRING error:&accountCreationError];

    if(accountCreationError){
        NSLog(@"Error in creating account.");
    }

    NSError *error;
    // Create a blob service client object.
    AZSCloudBlobClient *blobClient = [account getBlobClient];

    // Create a local container object.
    AZSCloudBlobContainer *blobContainer = [blobClient containerReferenceFromName:CONTAINER_NAME];
//    [blobContainer createContainerIfNotExistsWithAccessType:AZSContainerPublicAccessTypeContainer requestOptions:nil operationContext:nil completionHandler:^(NSError *error, BOOL exists)
//        {
//            if (error){
//                reject(@"no_event",@"Error in creating container.",error);
//            }
//            else{
                // Create a local blob object
//                AZSCloudBlockBlob *blockBlob = [blobContainer blockBlobReferenceFromName:fileName];
//                blockBlob.properties.contentType = contentType;
//                NSData *data = [NSData dataWithContentsOfFile:filePath];
//                [blockBlob uploadFromData:data completionHandler:^(NSError * error) {
//                    if (error){
//                        reject(@"no_event",[NSString stringWithFormat: @"Error in creating blob. %@",filePath],error);
//                    } else {
//                        resolve(fileName);
//                    }
//                }];
    
                @autoreleasepool {
                    AZSCloudBlockBlob *blob = [blobContainer blockBlobReferenceFromName:fileName];
                    
                    NSUInteger size = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error] fileSize];
                    
                    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:filePath];
                    
                    AZSOperationContext *operationContext = [[AZSOperationContext alloc] init];
                    operationContext.sendingRequest = ^(NSMutableURLRequest *request, AZSOperationContext *context) {
                        NSNumber *number = [stream propertyForKey:NSStreamFileCurrentOffsetKey];
                        if (number != nil) {
                            NSUInteger pos = [number longValue];
                            float percentage = ((float)pos / size) * 100;
                            responseProgress(@[[NSNumber numberWithFloat:percentage]]);
                            NSLog(@"current %ld of %ld, %f%% completed", pos, size, percentage);
                        }
                    };
                    
                    NSLog(@"upload started.");
                    
                    [blob uploadFromStream:stream accessCondition:nil requestOptions:nil operationContext:operationContext completionHandler:^(NSError *error) {
                         if (error){
                             reject(@"no_event",[NSString stringWithFormat: @"Error in creating blob. %@",filePath],error);
                         } else {
                             resolve(fileName);
                         }
                    }];
                }

                
//            }
//        }];
}


RCT_EXPORT_METHOD(configure:(NSString *)account_name
                 key:(NSString *)connection_string
                 container:(NSString *)conatiner_name)
{
    ACCOUNT_NAME = account_name;
    CONTAINER_NAME = [conatiner_name lowercaseString];
    CONNECTION_STRING = connection_string;
}

@end
