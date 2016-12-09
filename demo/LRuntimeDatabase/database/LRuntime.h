//
//  LRuntime.h
//  LRuntimeDatabase
//
//  Created by 李姝睿 on 2016/12/6.
//  Copyright © 2016年 李姝睿. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LDataType) {
    LDataTypeString = 0,
    LDataTypeInt,
    LDataTypeBool,
    LDataTypeDouble,
    LDataTypeFloat
};

@interface LRuntime : NSObject

// 通过类名得到类中的属性名
+ (NSArray *)getPropertyNameArrayWithClassName:(NSString *)className;
// 通过类名获取数据类型
+ (NSArray *)getDataTypeArrayWithClassName:(NSString *)className;
// 将数组中的枚举数据类型转化成数据库存储的数据类型
+ (NSArray *)getDatabaseTypeWithTypeArray:(NSArray *)typeArray;


@end
