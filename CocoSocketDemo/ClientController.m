//
//  ClientController.m
//  CocoSocketDemo
//
//  Created by sjl on 16/3/16.
//  Copyright © 2016年 LGQ. All rights reserved.
//

#import "ClientController.h"
#import <GCDAsyncSocket.h>
@interface ClientController ()<GCDAsyncSocketDelegate>
@property (weak, nonatomic) IBOutlet UIButton *disbtn;
@property (weak, nonatomic) IBOutlet UITextField *addressTF;
@property (weak, nonatomic) IBOutlet UITextField *portTF;
@property (weak, nonatomic) IBOutlet UITextField *messageTF;
@property (weak, nonatomic) IBOutlet UITextView *showMessageTF;
// 客户端socket
@property (strong, nonatomic) GCDAsyncSocket *clientSocket;

@property (nonatomic, strong) NSTimer *connectTimer;

@end

@implementation ClientController
- (void)addTimer
{
    // 长连接定时器
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    // 把定时器添加到当前运行循环,并且调为通用模式
    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
}
// 心跳连接
- (void)longConnectToSocket
{
    // 发送固定格式的数据,指令@"longConnect"
    float version = [[UIDevice currentDevice] systemVersion].floatValue;
    NSString *longConnect = [NSString stringWithFormat:@"心跳%f",version];
    
    NSData  *data = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.clientSocket writeData:data withTimeout:- 1 tag:0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 1.初始化
    //创建socket并指定代理对象为self,代理队列必须为主队列.
    self.clientSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
}

// 开始连接
- (IBAction)connectAction:(id)sender {
// 2.链接服务器
    [self.clientSocket connectToHost:self.addressTF.text onPort:self.portTF.text.integerValue viaInterface:nil withTimeout:-1 error:nil];
}
- (IBAction)disconnectbtnclick:(id)sender {
    [self.clientSocket disconnect];
}

// 发送消息
- (IBAction)sendMessageAction:(id)sender {
    NSData *data = [self.messageTF.text dataUsingEncoding:NSUTF8StringEncoding];
    // withTimeout -1 : 无穷大,一直等
    // tag : 消息标记
    [self.clientSocket writeData:data withTimeout:- 1 tag:0];
}

// 接收消息
- (IBAction)receiveMessageAction:(id)sender {
     [self.clientSocket readDataWithTimeout:11 tag:0];
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [self showMessageWithStr:@"链接成功"];
    NSLog(@"链接成功");

    [self showMessageWithStr:[NSString stringWithFormat:@"服务器IP: %@", host]];
    
    // 连接成功开启定时器
    [self addTimer];
    
    [self.clientSocket readDataWithTimeout:- 1 tag:0];
}

// 收到消息
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    [self showMessageWithStr:text];
    [self.clientSocket readDataWithTimeout:- 1 tag:0];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];

}

// 信息展示
- (void)showMessageWithStr:(NSString *)str {
    self.showMessageTF.text = [self.showMessageTF.text stringByAppendingFormat:@"%@\n", str];
}
 
// 链接断开
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
     [self showMessageWithStr:@"链接断开"];
    [self.connectTimer invalidate];
}

@end
