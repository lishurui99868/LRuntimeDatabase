//
//  LRuntime.m
//  LRuntimeDatabase
//
//  Created by 李姝睿 on 2016/12/6.
//  Copyright © 2016年 李姝睿. All rights reserved.
//

#import "LRuntime.h"
#import <objc/message.h>

@implementation LRuntime

// 通过类名得到类中的属性名
+ (NSArray *)getPropertyNameArrayWithClassName:(NSString *)className {
    NSMutableArray *array = [NSMutableArray array];
    unsigned int count;
    objc_property_t *props = class_copyPropertyList(NSClassFromString(className), &count);
    for (int i = 0; i < count; i ++) {
        objc_property_t property = props[i];
        const char *name = property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:name];
        NSRange range = [propertyName rangeOfString:@"_"];
        NSRange arrayRange = [propertyName rangeOfString:@"Array"];
        if (range.location == NSNotFound && arrayRange.location == NSNotFound) {
            [array addObject:propertyName];
        }
    }
    free(props);
    return array;
}
// 通过类名获取数据类型
+ (NSArray *)getDataTypeArrayWithClassName:(NSString *)className {
    NSMutableArray *array = [NSMutableArray array];
    unsigned int count;
    objc_property_t *props = class_copyPropertyList(NSClassFromString(className), &count);
    for (int i = 0; i < count; i ++) {
        objc_property_t property = props[i];
        const char *type = property_getAttributes(property);
        NSString *propertyType = [NSString stringWithUTF8String:type];
        int dataType = [self getLDataTypeWithPropertyType:propertyType];
        [array addObject:[NSNumber numberWithInt:dataType]];
    }
    free(props);
    return array;
}
// 将属性的数据类型转化成枚举中的类型
+ (LDataType)getLDataTypeWithPropertyType:(NSString *)propertyType {
    NSArray *typeArray = [propertyType componentsSeparatedByString:@","];
    NSString *type = nil;
    if (typeArray.count) {
        type = typeArray[0];
    }
    if ([type isEqualToString:@"T@\"NSString\""]) {
        return LDataTypeString;
    } else if ([type isEqualToString:@"Ti"]) {
        return LDataTypeInt;
    } else if ([type isEqualToString:@"Td"]) {
        return LDataTypeDouble;
    } else if ([type isEqualToString:@"Tc"]) {
        return LDataTypeBool;
    } else if ([type isEqualToString:@"Tf"]) {
        return LDataTypeFloat;
    } else {
        return LDataTypeString;
    }
}
// 将数组中的枚举数据类型转化成数据库存储的数据类型
+ (NSArray *)getDatabaseTypeWithTypeArray:(NSArray *)typeArray {
    NSMutableArray *array = [NSMutableArray array];
    for (NSNumber *number in typeArray) {
        int databaseType = number.intValue;
        if (databaseType == LDataTypeString) {
            [array addObject:@"Text (1024)"];
        } else if (databaseType == LDataTypeInt) {
            [array addObject:@"INTEGER"];
        } else if (databaseType == LDataTypeDouble || databaseType == LDataTypeFloat) {
            [array addObject:@"REAL"];
        } else if (databaseType == LDataTypeBool) {
            [array addObject:@"NUMERIC"];
        } else {
            [array addObject:@"Text (1024)"];
        }
    }
    return array;
}

@end
