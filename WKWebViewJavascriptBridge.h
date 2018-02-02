//
//  WKWebViewJavascriptBridge.h
//
//  Created by @LokiMeyburg on 10/15/14.
//  Copyright (c) 2014 @LokiMeyburg. All rights reserved.
//

#if (__MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_9 || __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_1)
#define supportsWKWebView
#endif

#if defined supportsWKWebView

#import <Foundation/Foundation.h>
#import "WebViewJavascriptBridgeBase.h"
#import <WebKit/WebKit.h>

@interface WKWebViewJavascriptBridge : NSObject<WKNavigationDelegate, WebViewJavascriptBridgeBaseDelegate>

// 初始化
+ (instancetype)bridgeForWebView:(WKWebView*)webView;
// 开启日志
+ (void)enableLogging;

// 注册 handler (Native)
- (void)registerHandler:(NSString*)handlerName handler:(WVJBHandler)handler;
// 删除 handler (Native)
- (void)removeHandler:(NSString*)handlerName;
// 调用 handler (JS)
- (void)callHandler:(NSString*)handlerName;
- (void)callHandler:(NSString*)handlerName data:(id)data;
- (void)callHandler:(NSString*)handlerName data:(id)data responseCallback:(WVJBResponseCallback)responseCallback;
// 重置
- (void)reset;
// 设置 webViewDelegate
- (void)setWebViewDelegate:(id)webViewDelegate;
// 禁用 JS AlertBox 的安全时长来加速消息传递，不推荐使用
// 方法是通过禁用 JS 端 AlertBox 的安全时长来加速网桥消息传递的。
// 如果禁用之后前端 JS 代码仍有调用 AlertBox 相关代码（alert, confirm, 或 prompt）则程序将被挂起，所以这个方法是不安全的
- (void)disableJavscriptAlertBoxSafetyTimeout;

@end

#endif
