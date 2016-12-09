//
//  LDatabase.h
//  LRuntimeDatabase
//
//  Created by 李姝睿 on 2016/12/6.
//  Copyright © 2016年 李姝睿. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

@interface LDatabase : NSObject

@property (nonatomic, strong) FMDatabase *database;

+ (LDatabase *)shareDatabase;
// 插入数据
- (void)insertItem:(id)item;
// 数据库查询
- (NSArray *)readAllDataWithClass:(Class)modelClass;
// 添加一个字段
- (void)insertColumnWithClass:(Class)modelClass columnName:(NSString *)columnName;
// 查询为模型赋值
- (NSArray *)getModelItemArrayWithClass:(Class)itemClass sql:(NSString *)sql argumentsArray:(NSArray *)argumentsArray;

@end
