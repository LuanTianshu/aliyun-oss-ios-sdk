//
//  ViewController.m
//  oss-mac-demo
//
//  Created by 怀叙 on 2017/11/7.
//  Copyright © 2017年 zhouzhuo. All rights reserved.
//

#import "ViewController.h"
#import <AliyunOSSiOS/OSSService.h>
#import "StstokenSample.h"
#import "GetObjcetSample.h"

static OSSClient * client;
static OSSStsTokenCredentialProvider * provider;
NSString* const ENDPOINT = @"http://oss-cn-hangzhou.aliyuncs.com";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self initSTSToken];
    });
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)stsTokenButtonClicked:(id)sender {
    
    NSLog(@"stsTokenButton has been clicked!");
    
    [[[StstokenSample alloc] init] getStsToken:^(NSDictionary *dict){
        
        if(provider == nil || client == nil){
            [self initOSSClientWithAk:dict[@"AccessKeyId"] Sk:dict[@"AccessKeySecret"] Token:dict[@"SecurityToken"]];
        }else{
            //给provider设置
            [provider setAccessKeyId:dict[@"AccessKeyId"]];
            [provider setSecretKeyId:dict[@"AccessKeySecret"]];
            [provider setSecurityToken:dict[@"SecurityToken"]];
        }
        
        
        //以下内容只是用于展示事例
        NSMutableString *string = [[NSMutableString alloc] init];
        for (id key in dict){//只是打印下日志
            NSLog(@"%@：%@", key,dict[key]);
            [string appendString:[NSString stringWithFormat:@"%@：%@\n\n", key,dict[key]]];
        }
        
        [self.infoTF setStringValue:string];
    }];
}

- (void)initSTSToken{
    [[[StstokenSample alloc] init] getStsToken:^(NSDictionary *dict){
        
        if(provider == nil || client == nil){
            [self initOSSClientWithAk:dict[@"AccessKeyId"] Sk:dict[@"AccessKeySecret"] Token:dict[@"SecurityToken"]];
        }else{
            //给provider设置
            [provider setAccessKeyId:dict[@"AccessKeyId"]];
            [provider setSecretKeyId:dict[@"AccessKeySecret"]];
            [provider setSecurityToken:dict[@"SecurityToken"]];
        }
    }];
}

- (void)initOSSClientWithAk:(NSString *)ak Sk:(NSString *)sk Token:(NSString *)token{
    [OSSLog enableLog];
    provider = [[OSSStsTokenCredentialProvider alloc] initWithAccessKeyId:ak secretKeyId:sk securityToken:token];
    
    OSSClientConfiguration * conf = [[OSSClientConfiguration alloc] init];
    conf.maxRetryCount = 2;
    conf.timeoutIntervalForRequest = 30;
    conf.timeoutIntervalForResource = 24 * 60 * 60;
    conf.maxConcurrentRequestCount = 5;
    
    // 更换不同的credentialProvider测试
    client = [[OSSClient alloc] initWithEndpoint:ENDPOINT credentialProvider:provider clientConfiguration:conf];
}

- (IBAction)getObjectButtonClicked:(id)sender {
    
    NSLog(@"getObjectButton has been clicked!");
    [[[GetObjcetSample alloc] initWithOSSClient:client] getObject:^(NSData *data){
        if(data != nil){
            NSLog(@"success");
        }else{
            NSLog(@"fail");
        }
    }];
}

- (IBAction)uploadObjectButtonClicked:(NSButton *)sender
{
    OSSPutObjectRequest * request = [OSSPutObjectRequest new];
    request.bucketName = @"dhc-images";
    request.objectKey = @"demo";
    NSString * docDir = NSHomeDirectory();
    request.uploadingFileURL = [NSURL fileURLWithPath:[docDir stringByAppendingPathComponent:@"Documents/demo"]];
    request.objectMeta = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value1", @"x-oss-meta-name1", nil];
    request.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
    };
    
    OSSTask * task = [client putObject:request];
    [[task continueWithBlock:^id(OSSTask *task) {
        if (task.error) {
            OSSLogError(@"%@", task.error);
        }
        OSSPutObjectResult * result = task.result;
        NSLog(@"Result - requestId: %@, headerFields: %@",
              result.requestId,
              result.httpResponseHeaderFields);
        return nil;
    }] waitUntilFinished];
}
@end
