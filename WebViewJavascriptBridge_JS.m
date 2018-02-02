// This file contains the source for the Javascript side of the
// WebViewJavascriptBridge. It is plaintext, but converted to an NSString
// via some preprocessor tricks.
//
// Previous implementations of WebViewJavascriptBridge loaded the javascript source
// from a resource. This worked fine for app developers, but library developers who
// included the bridge into their library, awkwardly had to ask consumers of their
// library to include the resource, violating their encapsulation. By including the
// Javascript as a string resource, the encapsulation of the library is maintained.
/*
 
 1. #import "WebViewJavascriptBridge.h"
    @property WebViewJavascriptBridge* bridge;
 
 2. self.bridge = [WebViewJavascriptBridge bridgeForWebView:webView];
 
 3. [self.bridge registerHandler:@"ObjC Echo" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"ObjC Echo called with: %@", data);
        responseCallback(data);
    }];
        [self.bridge callHandler:@"JS Echo" data:nil responseCallback:^(id responseData) {
        NSLog(@"ObjC received response: %@", responseData);
    }];
 
 4. 复制到js
    function setupWebViewJavascriptBridge(callback) {
        if (window.WebViewJavascriptBridge) { return callback(WebViewJavascriptBridge); }
        if (window.WVJBCallbacks) { return window.WVJBCallbacks.push(callback); }
        window.WVJBCallbacks = [callback];
        // 创建一个 iframe
        var WVJBIframe = document.createElement('iframe');
        // 设置 iframe 为不显示
        WVJBIframe.style.display = 'none';
        // 将 iframe 的 src 置为 'https://__bridge_loaded__'
        WVJBIframe.src = 'https://__bridge_loaded__';
        // 将 iframe 加入到 document.documentElement
        document.documentElement.appendChild(WVJBIframe);
        setTimeout(function() { document.documentElement.removeChild(WVJBIframe) }, 0)
    }
 
 5.
    setupWebViewJavascriptBridge(function(bridge) {
        // 在这里初始化应用程序

        bridge.registerHandler('JS Echo', function(data, responseCallback) {
            console.log("JS Echo called with:", data)
            responseCallback(data)
        })
        bridge.callHandler('ObjC Echo', {'key':'value'}, function responseCallback(responseData) {
            console.log("JS received response:", responseData)
        })
    })
 
 */


#import "WebViewJavascriptBridge_JS.h"

NSString * WebViewJavascriptBridge_js() {
	#define __wvjb_js_func__(x) #x
	
	// BEGIN preprocessorJSCode
	static NSString * preprocessorJSCode = @__wvjb_js_func__(
;(function() {
    // window.WebViewJavascriptBridge 校验，避免重复
	if (window.WebViewJavascriptBridge) {
		return;
	}
        
    // 懒加载 window.onerror，用于打印 error 日志
	if (!window.onerror) {
		window.onerror = function(msg, url, line) {
			console.log("WebViewJavascriptBridge: ERROR:" + msg + "@" + url + ":" + line);
		}
	}
    
    // window.WebViewJavascriptBridge 声明
	window.WebViewJavascriptBridge = {
		registerHandler: registerHandler,
		callHandler: callHandler,
		disableJavscriptAlertBoxSafetyTimeout: disableJavscriptAlertBoxSafetyTimeout,
		_fetchQueue: _fetchQueue,
		_handleMessageFromObjC: _handleMessageFromObjC
	};

    // 消息 iframe
	var messagingIframe;
    // 发送消息队列
	var sendMessageQueue = [];
    // JS 端注册的消息处理 handlers 字典
	var messageHandlers = {};
	
    // scheme 使用 https 之后通过 host 做匹配
	var CUSTOM_PROTOCOL_SCHEME = 'https';
	var QUEUE_HAS_MESSAGE = '__wvjb_queue_message__';
	
    // JS 端存放回调的字典
	var responseCallbacks = {};
    // 唯一标示，用于回调时生成 callbackId
	var uniqueId = 1;
    // 默认启用安全时长
	var dispatchMessagesWithTimeoutSafety = true;

    // 同 iOS 逻辑，注册 handler 其实是往 messageHandlers 字典中插入对应 name 的 block
	function registerHandler(handlerName, handler) {
		messageHandlers[handlerName] = handler;
	}
        
	// 调用 iOS handler，参数校验之后调用 _doSend 函数
	function callHandler(handlerName, data, responseCallback) {
        // 如果参数只有两个且第二个参数类型为 function，则表示没有参数传递，即 data 为空
		if (arguments.length == 2 && typeof data == 'function') {
			responseCallback = data;
			data = null;
		}
        // 将 handlerName 和 data 作为 msg 对象参数调用 _doSend 函数
		_doSend({ handlerName:handlerName, data:data }, responseCallback);
	}
    // 通过禁用 AlertBoxSafetyTimeout 来提速网桥消息传递
	function disableJavscriptAlertBoxSafetyTimeout() {
		dispatchMessagesWithTimeoutSafety = false;
	}
	
    // 将 msg 加入 sendMessageQueue 数组，设置 messagingIframe.src
    // _doSend 向 Native 端发送消息
    function _doSend(message, responseCallback) {
        // 如有回调，则设置 message['callbackId'] 与 responseCallbacks[callbackId]
		if (responseCallback) {
			var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
			responseCallbacks[callbackId] = responseCallback;
			message['callbackId'] = callbackId;
		}
        // 将 msg 加入 sendMessageQueue 数组，设置 messagingIframe.src
		sendMessageQueue.push(message);
		messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
	}
        
    // 获取队列，在 iOS 端刷新消息队列时会调用此函数
	function _fetchQueue() {
        // 将 sendMessageQueue 转为 JSON 格式
		var messageQueueString = JSON.stringify(sendMessageQueue);
        // 重置 sendMessageQueue
		sendMessageQueue = [];
        // 返回 JSON 格式的 
		return messageQueueString;
	}

    
    // 调度从 Native 端获取到的消息，逻辑与 Native 端一致
	function _dispatchMessageFromObjC(messageJSON) {
        // 判断有没有禁用 AlertBoxSafetyTimeout，最终会调用 _doDispatchMessageFromObjC 函数
		if (dispatchMessagesWithTimeoutSafety) {
			setTimeout(_doDispatchMessageFromObjC);
		} else {
			 _doDispatchMessageFromObjC();
		}
		
        // 解析 msgJSON 得到 msg
		function _doDispatchMessageFromObjC() {
			var message = JSON.parse(messageJSON);
			var messageHandler;
			var responseCallback;

            // 如果有 responseId，则说明是回调，取对应的 responseCallback 执行，之后释放
			if (message.responseId) {
				responseCallback = responseCallbacks[message.responseId];
				if (!responseCallback) {
					return;
				}
				responseCallback(message.responseData);
				delete responseCallbacks[message.responseId];
			} else { // 没有 responseId，则表示正常的 iOS call handler 调用 js
                // 如 msg 包含 callbackId，说明 iOS 端需要回调，初始化对应的 responseCallback
				if (message.callbackId) {
					var callbackResponseId = message.callbackId;
					responseCallback = function(responseData) {
						_doSend({ handlerName:message.handlerName, responseId:callbackResponseId, responseData:responseData });
					};
				}
                
				// 从 messageHandlers 拿到对应的 handler 执行
				var handler = messageHandlers[message.handlerName];
				if (!handler) {
                    // 如未取到对应的 handler 则打印错误日志
					console.log("WebViewJavascriptBridge: WARNING: no handler for message from ObjC:", message);
				} else {
					handler(message.data, responseCallback);
				}
			}
		}
	}
	
    // iOS 端 _dispatchMessage 函数会调用此函数
	function _handleMessageFromObjC(messageJSON) {
        // 调度从 Native 端获取到的消息
        _dispatchMessageFromObjC(messageJSON);
	}

    // messagingIframe 的声明，类型 iframe，样式不可见，src 设置
	messagingIframe = document.createElement('iframe');
	messagingIframe.style.display = 'none';
	messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
    // messagingIframe 加入 document.documentElement 中
	document.documentElement.appendChild(messagingIframe);

    // 注册 disableJavscriptAlertBoxSafetyTimeout handler，Native 可以通过禁用 AlertBox 的安全时长来加速桥接消息
	registerHandler("_disableJavascriptAlertBoxSafetyTimeout", disableJavscriptAlertBoxSafetyTimeout);
	
	setTimeout(_callWVJBCallbacks, 0);
	function _callWVJBCallbacks() {
		var callbacks = window.WVJBCallbacks;
		delete window.WVJBCallbacks;
		for (var i=0; i<callbacks.length; i++) {
			callbacks[i](WebViewJavascriptBridge);
		}
	}
})();
	); // END preprocessorJSCode

	#undef __wvjb_js_func__
	return preprocessorJSCode;
};
