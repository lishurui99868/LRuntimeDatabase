//
//  LDatabase.m
//  LRuntimeDatabase
//
//  Created by 李姝睿 on 2016/12/6.
//  Copyright © 2016年 李姝睿. All rights reserved.
//

#import "LDatabase.h"
#import "LFileManager.h"
#import "LRuntime.h"

@implementation LDatabase

static LDatabase * _ldb;
+ (LDatabase *)shareDatabase {
    @synchronized (self) {
        if (! _ldb) {
            _ldb = [[LDatabase alloc] init];
        }
    }
    return _ldb;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *path = [NSString stringWithFormat:@"%@/LRuntimeDatabase.sqlite",[LFileManager getDocumentPath]];
        _database = [[FMDatabase alloc] initWithPath:path];
        if ([_database open]) {
            [self createTable];
            // 为表添加新字段
            [self insertColumn];
        }
    }
    return self;
}

- (void)createTable {
    NSArray *classArray = @[@"LTestModel"];
    for (NSString *className in classArray) {
        if ([_database tableExists:className]) {
            continue;
        }
        NSMutableString *sql = [NSMutableString string];
        [sql appendFormat:@"CREATE TABLE IF NOT EXISTS %@ (",className];
        // 获取属性数组
        NSArray *propertyNameArray = [LRuntime getPropertyNameArrayWithClassName:className];
        // 获取枚举中的数据类型
        NSArray *ldataTypeArray = [LRuntime getDataTypeArrayWithClassName:className];
        // 获取数据库中对应的类型
        NSArray *databaseTypeArray = [LRuntime getDatabaseTypeWithTypeArray:ldataTypeArray];
        for (NSInteger i = 0; i < propertyNameArray.count; i ++) {
            NSString *propertyName = propertyNameArray[i];
            // 创建自增长Id
            if (i == 0) {
                [sql appendFormat:@"%@ INTEGER PRIMARY KEY AUTOINCREMENT",propertyName];
                continue;
            }
            NSRange range = [propertyName rangeOfString:@"Unique"];
            if (range.location != NSNotFound) {
                [sql appendFormat:@",%@ %@ NOT NULL UNIQUE",propertyName, databaseTypeArray[i]];
            } else {
                [sql appendFormat:@",%@ %@",propertyName,databaseTypeArray[i]];
            }
        }
        [sql appendString:@")"];
        // 增加，修改，删除，创建都用这个方法
        if ([_database executeUpdate:sql]) {
            NSLog(@"创建表成功");
        } else {
            NSLog(@"创建表失败:%@",[_database lastErrorMessage]);
        }
    }
}
// 为表添加新字段
- (void)insertColumn {
    // 添加字段名必须与创建属性名相同,否则插入数据库会崩溃
}
// 插入数据
- (void)insertItem:(id)item {
    if ([item isKindOfClass:[NSArray class]]) {
        // 开启事务
        [_database beginTransaction];
        [self insertItemArray:item];
        // 提交事务
        [_database commit];
    } else {
        [self insertItemModel:item];
    }
}

- (void)insertItemModel:(id)model {
    Class currentClass = [model class];
    NSString *className = NSStringFromClass(currentClass);
    
    NSMutableString *sql = [NSMutableString string];
    [sql appendFormat:@"insert into %@(",className];
    
    NSMutableArray *propertyNameArray = [NSMutableArray array];
    [propertyNameArray addObjectsFromArray:[LRuntime getPropertyNameArrayWithClassName:className]];
    // 移除自增长id属性(第一个属性为自增长id)
    [propertyNameArray removeObjectAtIndex:0];
    NSString *propertyName = [propertyNameArray componentsJoinedByString:@","];
    [sql appendString:propertyName];
    [sql appendString:@") values ("];
    
    NSMutableArray *placeholderArray = [NSMutableArray array];
    NSMutableArray *valueArray = [NSMutableArray array];
    for (NSString *propertyName in propertyNameArray) {
        [placeholderArray addObject:@"?"];
        if ([self isNullClass:[model valueForKey:propertyName]]) {
            [model setValue:@"" forKey:propertyName];
        }
        [valueArray addObject:[model valueForKey:propertyName]];
    }
    NSString *placeholder = [placeholderArray componentsJoinedByString:@","];
    [sql appendString:placeholder];
    [sql appendString:@")"];
    
    if ([_database executeUpdate:sql withArgumentsInArray:valueArray]) {
        NSLog(@"插入成功");
    } else {
        NSLog(@"插入失败%@",[_database lastErrorMessage]);
    }
}
// 拼成一条sql语句插入数据库效率最高(但是sqlite限制为500条)
#define kLimitDatabaseCount 500
- (void)insertItemArray:(NSArray *)modelArray {
    if (modelArray.count) {
        Class currentClass = [modelArray[0] class];
        NSString *className = NSStringFromClass(currentClass);
        NSMutableArray *propertyNameArray = [NSMutableArray array];
        [propertyNameArray addObjectsFromArray:[LRuntime getPropertyNameArrayWithClassName:className]];
        // 移除自增长id属性(第一个属性为自增长ID)
        [propertyNameArray removeObjectAtIndex:0];
        NSString *propertyName = [propertyNameArray componentsJoinedByString:@","];
        
        NSMutableString *sql = [NSMutableString string];
        [sql appendFormat:@"insert into %@(",className];
        [sql appendString:propertyName];
        [sql appendString:@") values "];
        
        NSMutableArray *valueArray = [NSMutableArray array];
        for (NSInteger i = 0; i < modelArray.count; i ++) {
            id obj = modelArray[i];
            [sql appendString:@"("];
            NSMutableArray *placeholderArray = [NSMutableArray array];
            for (NSString *propertyName in propertyNameArray){
                [placeholderArray addObject:@"?"];
                id value = [obj valueForKey:propertyName];
                if ([self isNullClass:value]) {
                    value = @"";
                }
                [valueArray addObject:value];
            }
            NSString *placeholder = [placeholderArray componentsJoinedByString:@","];
            [sql appendString:placeholder];
            [sql appendString:@"),"];
            
            if ((i + 1) % kLimitDatabaseCount == 0) {
                // 删除拼接sql语句最后的逗号
                [sql deleteCharactersInRange:NSMakeRange(sql.length - 1, 1)];
                if ([_database executeUpdate:sql withArgumentsInArray:valueArray]) {
                    // NSLog(@"插入成功");
                } else {
                    NSLog(@"插入失败%@",[_database lastErrorMessage]);
                }
                [sql setString:@""];
                // 判断后面是否还有数据
                if (i + 1 != modelArray.count) {
                    [sql appendFormat:@"insert into %@(",className];
                    [sql appendString:propertyName];
                    [sql appendString:@") values "];
                    [valueArray removeAllObjects];
                }
            }
        }
        if (sql.length > 0) {
            [sql deleteCharactersInRange:NSMakeRange(sql.length - 1, 1)];
            if ([_database executeUpdate:sql withArgumentsInArray:valueArray]) {
//                NSLog(@"插入成功");
            } else {
                NSLog(@"插入失败%@",[_database lastErrorMessage]);
            }
        }
    }
}
// 数据库查询
- (NSArray *)readAllDataWithClass:(Class)modelClass {
    NSString *className = NSStringFromClass(modelClass);
    NSString *sql = [NSString stringWithFormat:@"select * from %@",className];
    return [self getModelItemArrayWithClass:modelClass sql:sql argumentsArray:nil];
}
// 查询为模型赋值
- (NSArray *)getModelItemArrayWithClass:(Class)itemClass sql:(NSString *)sql argumentsArray:(NSArray *)argumentsArray {
    NSString *className = NSStringFromClass(itemClass);
    FMResultSet *rs = [_database executeQuery:sql withArgumentsInArray:argumentsArray];
    NSMutableArray *array = [NSMutableArray array];
    NSArray *propertyNameArray = [LRuntime getPropertyNameArrayWithClassName:className];
    NSArray *propertyTypeArray = [LRuntime getDataTypeArrayWithClassName:className];
    
    while ([rs next]) {
        id item = [[itemClass alloc] init];
        for (NSInteger i = 0; i < propertyNameArray.count; i ++) {
            NSString *propertyName = propertyNameArray[i];
            int propertyType = [propertyTypeArray[i] intValue];
            if (propertyType == LDataTypeString) {
                NSString *s = [rs stringForColumn:propertyName];
                [item setValue:s forKey:propertyName];
            } else if (propertyType == LDataTypeInt) {
                int iv = [rs intForColumn:propertyName];
                [item setValue:[NSNumber numberWithInt:iv] forKey:propertyName];
            } else if (propertyType == LDataTypeDouble) {
                double d = [rs doubleForColumn:propertyName];
                [item setValue:[NSNumber numberWithDouble:d] forKey:propertyName];
            } else if (propertyType == LDataTypeFloat) {
                float f = [rs doubleForColumn:propertyName];
                [item setValue:[NSNumber numberWithFloat:f] forKey:propertyName];
            } else if (propertyType == LDataTypeBool) {
                BOOL b = [rs boolForColumn:propertyName];
                [item setValue:[NSNumber numberWithBool:b] forKey:propertyName];
            } else {
                NSString *s = [rs stringForColumn:propertyName];
                [item setValue:s forKey:propertyName];
            }
        }
        [array addObject:item];
    }
    return array;
}
// 添加一个字段
- (void)insertColumnWithClass:(Class)modelClass columnName:(NSString *)columnName {
    // 如果不存在，添加新的字段
    if (! [self columnIsExitsInTableWithClass:modelClass columnName:columnName]) {
        NSString *sql = [NSString stringWithFormat:@"alter table %@ add %@ Text (1024)",NSStringFromClass(modelClass),columnName];
        if ([_database executeUpdate:sql]) {
            NSLog(@"添加字段成功");
        }
    }
}
// 判断该字段是否存在数据库
- (BOOL)columnIsExitsInTableWithClass:(Class)itemClass columnName:(NSString *)columnName {
    NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info(%@)",NSStringFromClass(itemClass)];
    FMResultSet *rs = [_database executeQuery:sql];
    while ([rs next]) {
        if ([columnName isEqualToString:[rs stringForColumn:@"name"]]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isNullClass:(id)obj {
    if (! obj) {
        return YES;
    }
    if ([obj isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([obj isKindOfClass:[NSString class]]) {
        if ([[obj lowercaseString] isEqualToString:@"null"]) {
           return YES;
        }
        if ([[obj lowercaseString] isEqualToString:@"<null>"]) {
            return YES;
        }
        if ([[obj lowercaseString] isEqualToString:@"(null)"]) {
            return YES;
        }
        if ([[obj lowercaseString] isEqualToString:@"[null]"]) {
            return YES;
        }
    }
    return NO;
}












@end
