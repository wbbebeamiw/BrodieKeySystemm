#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURATION
// ─────────────────────────────────────────────────────────────────────────────
#define SERVER_URL  "https://bs-lein.onrender.com"
#define BRAND_NAME  "Brodie Scripts"
#define DISCORD     "discord.gg/brodie"
#define SAVE_USER   "bs_saved_user"
#define SAVE_PASS   "bs_saved_pass"
// ─────────────────────────────────────────────────────────────────────────────

static UIWindow *keyWindow = nil;
static bool isAuthenticated = false;

// ── Colors ────────────────────────────────────────────────────────────────────
static UIColor* rgb(int r, int g, int b) {
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}
static UIColor* rgba(int r, int g, int b, float a) {
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a];
}

// ─────────────────────────────────────────────────────────────────────────────
// Login View Controller
// ─────────────────────────────────────────────────────────────────────────────
@interface BSLoginVC : UIViewController
@property (nonatomic, strong) UITextField *userField;
@property (nonatomic, strong) UITextField *passField;
@property (nonatomic, strong) UIButton    *loginBtn;
@property (nonatomic, strong) UILabel     *errorLabel;
@property (nonatomic, strong) UILabel     *timerLabel;
@property (nonatomic, strong) UIView      *timerCard;
@property (nonatomic, strong) UISwitch    *saveSwitch;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSTimer     *countdown;
@property (nonatomic, strong) NSDate      *expiryDate;
@property (nonatomic, strong) CAGradientLayer *bgLayer;
@end

@implementation BSLoginVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildBackground];
    [self buildUI];
    [self tryAutoLogin];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.bgLayer.frame = self.view.bounds;
}

// ── Background ────────────────────────────────────────────────────────────────
- (void)buildBackground {
    self.bgLayer = [CAGradientLayer layer];
    self.bgLayer.colors = @[
        (__bridge id)rgb(0,0,0).CGColor,
        (__bridge id)rgb(8,0,20).CGColor,
        (__bridge id)rgb(0,0,0).CGColor
    ];
    self.bgLayer.startPoint = CGPointMake(0,0);
    self.bgLayer.endPoint   = CGPointMake(1,1);
    self.bgLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.bgLayer atIndex:0];

    // Purple glow top
    UIView *glow = [[UIView alloc] initWithFrame:CGRectMake(-60,-80,280,280)];
    glow.backgroundColor = rgba(100,0,180,0.15);
    glow.layer.cornerRadius = 140;
    glow.layer.shadowColor  = rgba(100,0,180,1).CGColor;
    glow.layer.shadowRadius = 60;
    glow.layer.shadowOpacity = 1;
    glow.layer.shadowOffset  = CGSizeZero;
    [self.view addSubview:glow];
}

// ── UI ────────────────────────────────────────────────────────────────────────
- (void)buildUI {
    CGFloat W  = self.view.bounds.size.width;
    CGFloat H  = self.view.bounds.size.height;
    CGFloat cw = MIN(W - 40, 340);
    CGFloat cx = (W - cw) / 2;

    // Card
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = rgba(8,0,16,0.96);
    card.layer.cornerRadius = 22;
    card.layer.borderWidth  = 1;
    card.layer.borderColor  = rgba(120,40,200,0.3).CGColor;
    card.layer.shadowColor  = rgba(100,0,180,0.4).CGColor;
    card.layer.shadowRadius = 25;
    card.layer.shadowOpacity = 1;
    card.layer.shadowOffset  = CGSizeZero;
    [self.view addSubview:card];

    CGFloat y = 32;

    // Logo circle
    UIView *logo = [[UIView alloc] initWithFrame:CGRectMake((cw-64)/2, y, 64, 64)];
    logo.layer.cornerRadius = 32;
    CAGradientLayer *lg = [CAGradientLayer layer];
    lg.colors = @[(__bridge id)rgb(80,0,160).CGColor, (__bridge id)rgb(120,40,200).CGColor];
    lg.startPoint = CGPointMake(0,0); lg.endPoint = CGPointMake(1,1);
    lg.frame = CGRectMake(0,0,64,64);
    lg.cornerRadius = 32;
    [logo.layer addSublayer:lg];
    logo.layer.shadowColor   = rgb(120,40,200).CGColor;
    logo.layer.shadowRadius  = 16;
    logo.layer.shadowOpacity = 0.8;
    logo.layer.shadowOffset  = CGSizeZero;
    [card addSubview:logo];

    UILabel *logoText = [[UILabel alloc] initWithFrame:CGRectMake(0,0,64,64)];
    logoText.text          = @"BS";
    logoText.textAlignment = NSTextAlignmentCenter;
    logoText.font          = [UIFont systemFontOfSize:22 weight:UIFontWeightBlack];
    logoText.textColor     = UIColor.whiteColor;
    [logo addSubview:logoText];

    // Pulse animation
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"shadowRadius"];
    pulse.fromValue    = @16;
    pulse.toValue      = @28;
    pulse.duration     = 1.5;
    pulse.autoreverses = YES;
    pulse.repeatCount  = INFINITY;
    [logo.layer addAnimation:pulse forKey:@"pulse"];
    y += 74;

    // Brand name
    UILabel *brand = [[UILabel alloc] initWithFrame:CGRectMake(0,y,cw,26)];
    brand.text          = @BRAND_NAME;
    brand.textAlignment = NSTextAlignmentCenter;
    brand.font          = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    brand.textColor     = rgb(200,140,255);
    [card addSubview:brand];
    y += 28;

    // Discord
    UILabel *disc = [[UILabel alloc] initWithFrame:CGRectMake(0,y,cw,18)];
    disc.text          = @DISCORD;
    disc.textAlignment = NSTextAlignmentCenter;
    disc.font          = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    disc.textColor     = rgba(120,80,160,1);
    [card addSubview:disc];
    y += 26;

    // Divider
    UIView *div = [[UIView alloc] initWithFrame:CGRectMake(16,y,cw-32,1)];
    div.backgroundColor = rgba(100,40,180,0.2);
    [card addSubview:div];
    y += 18;

    // Username field
    self.userField = [self makeField:@"USERNAME" secure:NO y:y width:cw];
    [card addSubview:self.userField];
    y += 54;

    // Password field
    self.passField = [self makeField:@"PASSWORD" secure:YES y:y width:cw];
    [card addSubview:self.passField];
    y += 54;

    // Save login row
    UILabel *saveLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,y+2,cw-80,26)];
    saveLabel.text      = @"Save Login";
    saveLabel.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    saveLabel.textColor = rgba(150,120,180,1);
    [card addSubview:saveLabel];

    self.saveSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(cw-66,y,51,31)];
    self.saveSwitch.onTintColor = rgb(100,0,180);
    [card addSubview:self.saveSwitch];
    y += 42;

    // Error label
    self.errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,y,cw-32,36)];
    self.errorLabel.text          = @"";
    self.errorLabel.font          = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.errorLabel.textColor     = rgb(255,60,90);
    self.errorLabel.textAlignment = NSTextAlignmentCenter;
    self.errorLabel.numberOfLines = 2;
    self.errorLabel.hidden        = YES;
    [card addSubview:self.errorLabel];
    y += 40;

    // Login button
    self.loginBtn = [[UIButton alloc] initWithFrame:CGRectMake(16,y,cw-32,50)];
    CAGradientLayer *btnGrad = [CAGradientLayer layer];
    btnGrad.colors = @[(__bridge id)rgb(70,0,140).CGColor, (__bridge id)rgb(110,30,190).CGColor];
    btnGrad.startPoint = CGPointMake(0,0); btnGrad.endPoint = CGPointMake(1,0);
    btnGrad.frame = CGRectMake(0,0,cw-32,50);
    btnGrad.cornerRadius = 12;
    [self.loginBtn.layer insertSublayer:btnGrad atIndex:0];
    self.loginBtn.layer.cornerRadius = 12;
    self.loginBtn.clipsToBounds = YES;
    [self.loginBtn setTitle:@"LOGIN" forState:UIControlStateNormal];
    self.loginBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    [self.loginBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.loginBtn.layer.shadowColor   = rgb(100,0,180).CGColor;
    self.loginBtn.layer.shadowRadius  = 12;
    self.loginBtn.layer.shadowOpacity = 0.6;
    self.loginBtn.layer.shadowOffset  = CGSizeZero;
    [self.loginBtn addTarget:self action:@selector(doLogin) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:self.loginBtn];
    y += 56;

    // Spinner
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.spinner.color  = UIColor.whiteColor;
    self.spinner.center = CGPointMake(cw/2, y-28);
    self.spinner.hidesWhenStopped = YES;
    [card addSubview:self.spinner];

    // Timer card (hidden until login)
    self.timerCard = [[UIView alloc] initWithFrame:CGRectMake(16,y,cw-32,56)];
    self.timerCard.backgroundColor  = rgba(16,0,30,0.8);
    self.timerCard.layer.cornerRadius = 12;
    self.timerCard.layer.borderWidth  = 1;
    self.timerCard.layer.borderColor  = rgba(100,40,180,0.2).CGColor;
    self.timerCard.hidden = YES;
    [card addSubview:self.timerCard];

    UILabel *timerTitle = [[UILabel alloc] initWithFrame:CGRectMake(0,8,cw-32,16)];
    timerTitle.text          = @"ACCESS EXPIRES IN";
    timerTitle.textAlignment = NSTextAlignmentCenter;
    timerTitle.font          = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
    timerTitle.textColor     = rgba(120,80,160,1);
    [self.timerCard addSubview:timerTitle];

    self.timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,24,cw-32,26)];
    self.timerLabel.text          = @"--:--:--";
    self.timerLabel.textAlignment = NSTextAlignmentCenter;
    self.timerLabel.font          = [UIFont monospacedDigitSystemFontOfSize:20 weight:UIFontWeightBlack];
    self.timerLabel.textColor     = rgb(180,100,255);
    [self.timerCard addSubview:self.timerLabel];
    y += 64;

    // Device ID
    NSString *hwid = [[[UIDevice currentDevice] identifierForVendor] UUIDString] ?: @"UNKNOWN";
    UILabel *devLabel = [[UILabel alloc] initWithFrame:CGRectMake(8,y,cw-16,28)];
    devLabel.text                 = [NSString stringWithFormat:@"Device: %@", hwid];
    devLabel.font                 = [UIFont monospacedSystemFontOfSize:8 weight:UIFontWeightRegular];
    devLabel.textColor            = rgba(60,40,80,1);
    devLabel.textAlignment        = NSTextAlignmentCenter;
    devLabel.adjustsFontSizeToFitWidth = YES;
    [card addSubview:devLabel];
    y += 32;

    // Size and center card
    CGFloat cardH = y + 10;
    card.frame = CGRectMake(cx, (H - cardH)/2, cw, cardH);
}

// ── Field factory ─────────────────────────────────────────────────────────────
- (UITextField *)makeField:(NSString*)ph secure:(BOOL)sec y:(CGFloat)y width:(CGFloat)w {
    UITextField *f    = [[UITextField alloc] initWithFrame:CGRectMake(16,y,w-32,46)];
    f.secureTextEntry = sec;
    f.backgroundColor = rgba(10,0,20,0.8);
    f.layer.cornerRadius = 12;
    f.layer.borderWidth  = 1;
    f.layer.borderColor  = rgba(100,40,180,0.25).CGColor;
    f.textColor          = UIColor.whiteColor;
    f.font               = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    f.autocorrectionType      = UITextAutocorrectionTypeNo;
    f.autocapitalizationType  = UITextAutocapitalizationTypeNone;
    f.attributedPlaceholder   = [[NSAttributedString alloc] initWithString:ph
        attributes:@{NSForegroundColorAttributeName:rgba(60,40,80,1),
                     NSFontAttributeName:[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold]}];
    UILabel *icon = [[UILabel alloc] initWithFrame:CGRectMake(0,0,38,46)];
    icon.text          = sec ? @"🔒" : @"👤";
    icon.textAlignment = NSTextAlignmentCenter;
    icon.font          = [UIFont systemFontOfSize:14];
    f.leftView         = icon;
    f.leftViewMode     = UITextFieldViewModeAlways;
    return f;
}

// ── Login ─────────────────────────────────────────────────────────────────────
- (void)doLogin {
    NSString *user = self.userField.text;
    NSString *pass = self.passField.text;
    if (!user.length || !pass.length) {
        [self showError:@"Enter username and password"];
        return;
    }
    [self.userField resignFirstResponder];
    [self.passField resignFirstResponder];
    [self setLoading:YES];

    NSString *hwid   = [[[UIDevice currentDevice] identifierForVendor] UUIDString] ?: @"UNKNOWN";
    NSString *device = [UIDevice currentDevice].name;

    NSURL *url = [NSURL URLWithString:@(SERVER_URL "/lg")];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod      = @"POST";
    req.timeoutInterval = 12;
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSDictionary *body = @{@"username":user, @"password":pass, @"hwid":hwid, @"version":@"1.0", @"device_name":device};
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];

    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *r, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setLoading:NO];
            if (err || !data) { [self showError:@"Cannot connect to server"]; return; }
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([json[@"success"] boolValue]) {
                if (self.saveSwitch.isOn) {
                    [[NSUserDefaults standardUserDefaults] setObject:user forKey:@SAVE_USER];
                    [[NSUserDefaults standardUserDefaults] setObject:pass forKey:@SAVE_PASS];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                NSString *expiry = json[@"expiry_date"];
                if (expiry && ![expiry isEqual:[NSNull null]]) {
                    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
                    fmt.dateFormat = @"yyyy-MM-dd";
                    self.expiryDate = [fmt dateFromString:expiry];
                    if (self.expiryDate) {
                        self.timerCard.hidden = NO;
                        [self startTimer];
                    }
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self dismiss];
                });
            } else {
                NSString *msg = json[@"message"] ?: @"Invalid credentials";
                [self showError:msg];
            }
        });
    }] resume];
}

- (void)tryAutoLogin {
    NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:@SAVE_USER];
    NSString *pass = [[NSUserDefaults standardUserDefaults] stringForKey:@SAVE_PASS];
    if (user && pass) {
        self.userField.text  = user;
        self.passField.text  = pass;
        self.saveSwitch.on   = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self doLogin];
        });
    }
}

- (void)setLoading:(BOOL)on {
    self.loginBtn.hidden = on;
    if (on) [self.spinner startAnimating];
    else    [self.spinner stopAnimating];
    self.errorLabel.hidden = YES;
}

- (void)showError:(NSString*)msg {
    self.errorLabel.text   = msg;
    self.errorLabel.hidden = NO;
    CAKeyframeAnimation *shake = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    shake.values   = @[@(-8),@(8),@(-5),@(5),@(-2),@(2),@0];
    shake.duration = 0.4;
    [self.errorLabel.layer addAnimation:shake forKey:@"shake"];
}

- (void)startTimer {
    self.countdown = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *t) {
        if (!self.expiryDate) { [t invalidate]; return; }
        NSTimeInterval rem = [self.expiryDate timeIntervalSinceNow];
        if (rem <= 0) {
            [t invalidate];
            self.timerLabel.text      = @"EXPIRED";
            self.timerLabel.textColor = [UIColor redColor];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@SAVE_USER];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@SAVE_PASS];
                [[NSUserDefaults standardUserDefaults] synchronize];
                keyWindow.hidden = NO;
                [keyWindow makeKeyAndVisible];
            });
            return;
        }
        long d = (long)rem/86400, h = ((long)rem%86400)/3600, m = ((long)rem%3600)/60, s = (long)rem%60;
        if (d > 0) self.timerLabel.text = [NSString stringWithFormat:@"%ldd %02ldh %02ldm",d,h,m];
        else       self.timerLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",h,m,s];
        if (rem < 3600) self.timerLabel.textColor = [UIColor redColor];
    }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.35 animations:^{ keyWindow.alpha = 0; }
                     completion:^(BOOL done) { keyWindow.hidden = YES; }];
}

@end

// ─────────────────────────────────────────────────────────────────────────────
// Constructor — runs when dylib is injected
// ─────────────────────────────────────────────────────────────────────────────
__attribute__((constructor))
static void BSInit(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        BSLoginVC *vc = [[BSLoginVC alloc] init];
        keyWindow = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        keyWindow.windowLevel      = UIWindowLevelAlert + 9999;
        keyWindow.rootViewController = vc;
        keyWindow.backgroundColor  = UIColor.blackColor;
        keyWindow.hidden           = NO;
        [keyWindow makeKeyAndVisible];
    });
}
