//
//  LAddViewController.m
//  LRuntimeDatabase
//
//  Created by 李姝睿 on 2016/12/8.
//  Copyright © 2016年 李姝睿. All rights reserved.
//

#import "LAddViewController.h"
#import "LDatabase.h"

@interface LAddViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@end

@implementation LAddViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _textField.text = _model.title;
    _textView.text = _model.detail;
}

- (void)done {
    if (! _model) {
        _model = [[LTestModel alloc] init];
        _model.title = _textField.text;
        _model.detail = _textView.text;
        [[LDatabase shareDatabase] insertItem:_model];
    } else {
        _model.title = _textField.text;
        _model.detail = _textView.text;
        NSString *sql = @"update LTestModel set title = ?,detail = ? where addId = ?";
        if ([[LDatabase shareDatabase].database executeUpdate:sql, _model.title, _model.detail, _model.addId]) {
            NSLog(@"修改成功");
        }
    }
    
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
