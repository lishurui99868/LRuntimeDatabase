//
//  LRootViewController.m
//  LRuntimeDatabase
//
//  Created by 李姝睿 on 2016/12/7.
//  Copyright © 2016年 李姝睿. All rights reserved.
//

#import "LRootViewController.h"
#import "LAddViewController.h"
#import "LDatabase.h"

@interface LRootViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation LRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Root";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
    
    _dataArray = [NSMutableArray array];
    
    [self createTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_dataArray removeAllObjects];
    NSArray *arr = [[LDatabase shareDatabase] readAllDataWithClass:[LTestModel class]];
    [_dataArray addObjectsFromArray:arr];
    [_tableView reloadData];
}

- (void)createTableView {
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 64) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
}

#pragma mark - tableViewDataSourceAndDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    if (cell) {
        LTestModel *model = _dataArray[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@---%@",model.title, model.detail];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        LTestModel *model = _dataArray[indexPath.row];
        
        [_dataArray removeObject:model];
        NSString *sql = @"delete from LTestModel where addId = ?";
        if ([[LDatabase shareDatabase].database executeUpdate:sql, model.addId]) {
            NSLog(@"删除成功");
        }
        [tableView deleteRowsAtIndexPaths:[NSMutableArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LAddViewController *vc = [[LAddViewController alloc] init];
    vc.model = _dataArray[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}
#pragma mark - 添加
- (void)add {
    LAddViewController *vc = [[LAddViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
