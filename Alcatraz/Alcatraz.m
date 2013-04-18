//
//  Alcatraz.m
//  Alcatraz
//
//  Created by Marin Usalj on 4/17/13.
//  Copyright (c) 2013 mneorr.com. All rights reserved.
//

#import "Alcatraz.h"
// pull this out in a factory
#import "Plugin.h"
#import "ColorScheme.h"
#import "Template.h"
//

@interface Alcatraz(){}
@property (nonatomic, retain) NSBundle *bundle;
@property (nonatomic, retain) NSArray *packages;
@end

@implementation Alcatraz


+ (void)pluginDidLoad:(NSBundle *)plugin {
    static Alcatraz *sharedPlugin;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlugin = [[self alloc] initWithBundle:plugin];
    });
}

- (id)initWithBundle:(NSBundle *)plugin {
    if (self = [super init]) {
        self.bundle = [plugin retain];
        [self createMenuItem];
        [self fetchPlugins];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.bundle release];
    [self.packages release];
    [super dealloc];
}


#pragma mark - Private

- (void)fetchPlugins {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    @try {
        NSData *jsonData = [[NSData alloc] initWithContentsOfFile:[self.bundle pathForResource:@"packages" ofType:@"json"]];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        [self createPackagesFromDicts:json[@"packages"]];
        [jsonData release];
    }
    @catch(NSException *exception) {
        NSLog(@"I've heard you like exceptions... %@", exception);
    }
    
    [pool drain];
}

- (void)createPackagesFromDicts:(NSDictionary *)packagesDict {

    NSMutableArray *packages = [NSMutableArray new];

    for (NSDictionary *pluginDict in packagesDict[@"plugins"]) {
        Plugin *plugin = [[Plugin alloc] initWithDictionary:pluginDict];
        [packages addObject:plugin];
        [plugin release];
    }
    for (NSDictionary *templateDict in packagesDict[@"templates"]) {
        Template *template = [[Template alloc] initWithDictionary:templateDict];
        [packages addObject:template];
        [template release];
    }
    for (NSDictionary *colorSchemeDict in packagesDict[@"color_schemes"]) {
        ColorScheme *colorScheme = [[ColorScheme alloc] initWithDictionary:colorSchemeDict];
        [packages addObject:colorScheme];
        [colorScheme release];
    }
    
    self.packages = packages;
    [packages release];
}

- (void)createMenuItem {
    NSMenuItem *windowMenuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
    NSMenuItem *pluginManagerItem = [[NSMenuItem alloc] initWithTitle:@"Plugin Manager"
                                                               action:@selector(openPluginManagerWindow)
                                                        keyEquivalent:@"P"];
    pluginManagerItem.keyEquivalentModifierMask = NSCommandKeyMask | NSShiftKeyMask | NSAlternateKeyMask;
    pluginManagerItem.target = self;
    [windowMenuItem.submenu insertItem:pluginManagerItem
                               atIndex:[windowMenuItem.submenu indexOfItemWithTitle:@"Organizer"] + 1];
    [pluginManagerItem release];
}

- (void)openPluginManagerWindow {
    
    NSArray *nibElements;
    [self.bundle loadNibNamed:@"PluginWindow" owner:self topLevelObjects:&nibElements];
    
    NSPredicate *windowPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject class] == [NSWindow class];
    }];
    NSWindow *window = [nibElements filteredArrayUsingPredicate:windowPredicate][0];
    [window makeKeyAndOrderFront:self];
}

#pragma mark - TableView delegate

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {

    return [self.packages[row] name];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.packages.count;
}




@end