//
//  WebViewJavascriptBridgeBase.h
//
//  Created by @LokiMeyburg on 10/15/14.
//  Copyright (c) 2014 @LokiMeyburg. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kOldProtocolScheme @"wvjbscheme"
#define kNewProtocolScheme @"https"
#define kQueueHasMessage   @"__wvjb_queue_message__"
#define kBridgeLoaded      @"__bridge_loaded__"

// 回调 block
typedef void (^WVJBResponseCallback)(id responseData);
// 注册的 Handler block
typedef void (^WVJBHandler)(id data, WVJBResponseCallback responseCallback);
// 消息类型 - 字典
typedef NSDictionary WVJBMessage;

@protocol WebViewJavascriptBridgeBaseDelegate <NSObject>
- (NSString*) _evaluateJavascript:(NSString*)javascriptCommand;
@end

@interface WebViewJavascriptBridgeBase : NSObject

// 代理，指向接口层类，用以给对应接口绑定的 WebView 组件发送执行 JS 消息
@property (weak, nonatomic) id <WebViewJavascriptBridgeBaseDelegate> delegate;
// 启动消息队列，可以理解为存放 WVJBMessage
@property (strong, nonatomic) NSMutableArray* startupMessageQueue;
// 回调 blocks 字典，存放 WVJBResponseCallback 类型的 block
@property (strong, nonatomic) NSMutableDictionary* responseCallbacks;
// 已注册的 handlers 字典，存放 WVJBHandler 类型的 block
@property (strong, nonatomic) NSMutableDictionary* messageHandlers;
@property (strong, nonatomic) WVJBHandler messageHandler;

// 开启日志
+ (void)enableLogging;
// 设置日志最大长度
+ (void)setLogMaxLength:(int)length;
// 对应 WKJSBridge 的 reset 接口
- (void)reset;
// 发送消息，入参依次是参数，回调 block，对应 JS 端注册的 HandlerName
- (void)sendData:(id)data responseCallback:(WVJBResponseCallback)responseCallback handlerName:(NSString*)handlerName;
// 刷新消息队列，核心代码
- (void)flushMessageQueue:(NSString *)messageQueueString;
// 注入 JS
- (void)injectJavascriptFile;
// 判定是否为 WebViewJavascriptBridgeURL
- (BOOL)isWebViewJavascriptBridgeURL:(NSURL*)url;
// 判定是否为队列消息 URL
- (BOOL)isQueueMessageURL:(NSURL*)urll;
// 判定是否为 bridge 载入 URL
- (BOOL)isBridgeLoadedURL:(NSURL*)urll;
// 打印收到未知消息信息
- (void)logUnkownMessage:(NSURL*)url;
// JS bridge 检测命令
- (NSString *)webViewJavascriptCheckCommand;
// JS bridge 获取查询命令
- (NSString *)webViewJavascriptFetchQueyCommand;
// 禁用 JS AlertBox 安全时长以获取发送消息速度提升，不建议使用，理由见上文
- (void)disableJavscriptAlertBoxSafetyTimeout;

@end
