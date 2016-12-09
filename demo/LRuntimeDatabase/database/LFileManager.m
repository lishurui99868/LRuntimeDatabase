//
//  LFileManager.m
//  LRuntimeDatabase
//
//  Created by 李姝睿 on 2016/12/6.
//  Copyright © 2016年 李姝睿. All rights reserved.
//

#import "LFileManager.h"

@implementation LFileManager

+ (NSString *)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

@end
