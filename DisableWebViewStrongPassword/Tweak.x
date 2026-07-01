#import <WebKit/WebKit.h>
#import <objc/message.h>

// Sandbox-safe: writes into the host app's own tmp dir (always writable),
// readable over SSH from /var/mobile/Containers/Data/Application/*/tmp/dwsp.log
static void DWSP_fileLog(NSString *msg) {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"dwsp.log"];
    NSString *line = [NSString stringWithFormat:@"%@ [%@] %@\n",
        [NSDate date], [[NSProcessInfo processInfo] processName], msg];
    FILE *f = fopen(path.UTF8String, "a");
    if (f) { fputs(line.UTF8String, f); fclose(f); }
}

@interface WKWebViewConfiguration (StrongPasswordPrivate)
- (void)_setAllowsStrongPasswordSuggestions:(BOOL)allows;
- (BOOL)_allowsStrongPasswordSuggestions;
@end

static void DWSP_disable(WKWebViewConfiguration *config) {
    if (!config) return;
    SEL setter = @selector(_setAllowsStrongPasswordSuggestions:);
    if ([config respondsToSelector:setter]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(config, setter, NO);
    }
}

%hook WKWebViewConfiguration

- (instancetype)init {
    WKWebViewConfiguration *config = %orig;
    DWSP_disable(config);
    return config;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    WKWebViewConfiguration *config = %orig;
    DWSP_disable(config);
    return config;
}

- (BOOL)_allowsStrongPasswordSuggestions {
    DWSP_fileLog(@"getter READ -> forcing NO");
    return NO;
}

- (void)_setAllowsStrongPasswordSuggestions:(BOOL)allows {
    DWSP_fileLog([NSString stringWithFormat:@"setter called (%d) -> forcing NO", allows]);
    %orig(NO);
}

%end

%ctor {
    DWSP_fileLog(@"dylib LOADED");
}
