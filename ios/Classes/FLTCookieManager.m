#import "FLTCookieManager.h"

@implementation FLTCookieManager {
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FLTCookieManager *instance = [[FLTCookieManager alloc] init];

  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/cookie_manager"
                                  binaryMessenger:[registrar messenger]];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([[call method] isEqualToString:@"clearCookies"]) {
    [self clearCookies:result];
  } else if ([[call method] isEqualToString:@"setCookies"]) {
    [self setCookies:call];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)clearCookies:(FlutterResult)result {
  if (@available(iOS 9.0, *)) {
    [self clearCookiesIos9AndLater:result];
  } else {
    // support for iOS8 tracked in https://github.com/flutter/flutter/issues/27624.
    NSLog(@"Clearing cookies is not supported for Flutter WebViews prior to iOS 9.");
  }
}

- (void)clearCookiesIos9AndLater:(FlutterResult)result {
  NSSet *websiteDataTypes = [NSSet setWithArray:@[ WKWebsiteDataTypeCookies ]];
  WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];

  void (^deleteAndNotify)(NSArray<WKWebsiteDataRecord *> *) =
      ^(NSArray<WKWebsiteDataRecord *> *cookies) {
        BOOL hasCookies = cookies.count > 0;
        [dataStore removeDataOfTypes:websiteDataTypes
                      forDataRecords:cookies
                   completionHandler:^{
                     result(@(hasCookies));
                   }];
      };

  [dataStore fetchDataRecordsOfTypes:websiteDataTypes completionHandler:deleteAndNotify];
}

- (void) setCookies:(FlutterMethodCall*)call {
    NSString *url = call.arguments[@"url"];
    NSDictionary *cookies = call.arguments[@"cookies"];
    if (cookies != nil && url != nil) {
        [cookies enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
            NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
            [cookieProperties setObject:key forKey:NSHTTPCookieName];
            [cookieProperties setObject:value forKey:NSHTTPCookieValue];
            [cookieProperties setObject:url forKey:NSHTTPCookieDomain];
            [cookieProperties setObject:url forKey:NSHTTPCookieOriginURL];
            [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
            [cookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
            // set expiration to one month from now or any NSDate of your choosing
            // this makes the cookie sessionless and it will persist across web sessions and app launches
            /// if you want the cookie to be destroyed when your app exits, don't set this
            [cookieProperties setObject:[[NSDate date] dateByAddingTimeInterval:2629743] forKey:NSHTTPCookieExpires];
            NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }];
    }
}

@end
