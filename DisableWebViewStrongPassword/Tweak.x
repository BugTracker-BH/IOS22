#import <WebKit/WebKit.h>
#import <objc/message.h>

// Private API on WKWebViewConfiguration (UI-process class).
// Present on iOS 12 -> iOS 17. We resolve it dynamically so a missing
// selector on a future/older OS can never crash the host app.
@interface WKWebViewConfiguration (StrongPasswordPrivate)
- (void)_setAllowsStrongPasswordSuggestions:(BOOL)allows;
@end

static void DWSP_disable(WKWebViewConfiguration *config) {
    if (!config) return;

    SEL setter = @selector(_setAllowsStrongPasswordSuggestions:);
    if ([config respondsToSelector:setter]) {
        // Typed objc_msgSend so the BOOL arg is passed correctly on arm64/arm64e.
        ((void (*)(id, SEL, BOOL))objc_msgSend)(config, setter, NO);
        return;
    }

    // KVC fallback, fully guarded so an unknown key can never throw.
    @try {
        [config setValue:@NO forKey:@"_allowsStrongPasswordSuggestions"];
    } @catch (__unused NSException *e) {
        @try {
            [config setValue:@NO forKey:@"allowsStrongPasswordSuggestions"];
        } @catch (__unused NSException *e2) {
            // Property genuinely unavailable on this OS build. Do nothing.
        }
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

%end

// NOTE: We deliberately do NOT hook the getter and do NOT hook anything in
// WKPreferences / the WebContent process. Forcing the flag once at
// configuration creation, only inside UIKit app processes, is enough and
// avoids the renderer crash loop ("a problem occurred / reloaded").
