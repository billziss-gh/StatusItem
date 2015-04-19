//usr/bin/clang -w -framework Foundation -framework AppKit "$0" "$@"; exit

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <libgen.h>

static NSImage *ImageResize(NSImage *sourceImage, CGSize size)
{
    CGRect targetFrame = CGRectMake(0, 0, size.width, size.height);
    NSImage *targetImage = [[[NSImage alloc] initWithSize:size] autorelease];
    [targetImage lockFocus];
    [[sourceImage bestRepresentationForRect:targetFrame context:nil hints:nil] drawInRect:targetFrame];
    [targetImage unlockFocus];
    return targetImage;
}

static NSMutableDictionary *statusItems;
@interface StatusItemObject : NSObject
- (void)setStatusItem:(NSDictionary *)dict;
@end
@implementation StatusItemObject
- (void)setStatusItem:(NSDictionary *)dict
{
    NSString *name, *path, *mesg;
    name = [dict objectForKey:@"name"];
    path = [dict objectForKey:@"path"];
    mesg = [dict objectForKey:@"mesg"];
    NSStatusItem *item = [statusItems objectForKey:name];
    if (nil != path)
    {
        NSImage *image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
        if (nil != image)
        {
            image = ImageResize(image, CGSizeMake(18, 18));
            if (nil == item)
            {
                item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
                [item setHighlightMode:YES];
                [statusItems setObject:item forKey:name];
            }
            if (nil != mesg)
            {
                NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
                [menu addItemWithTitle:mesg action:nil keyEquivalent:@""];
                [item setMenu:menu];
            }
            [item setImage:image];
        }
    }
    else
    {
        if (nil != item)
            [statusItems removeObjectForKey:name];
        if (0 == [statusItems count])
            [[NSApplication sharedApplication]
                performSelector:@selector(terminate:) withObject:nil afterDelay:0];
    }
}
@end

void fail(const char *mesg)
{
    fprintf(stderr, "%s: %s\n", mesg, strerror(errno));
    exit(1);
}
void usage(char *prog)
{
    fprintf(stderr, "usage: %s [-m MESSAGE] NAME [PATH]\n", basename(prog));
    exit(2);
}
void run(const char *prog, const char *name, const char *path, const char *mesg)
{
    @autoreleasepool
    {
        NSConnection *conn;
        NSDictionary *dict;
        id obj;
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithUTF8String:name], @"name",
            0 != path ? [NSString stringWithUTF8String:path] : nil, @"path",
            0 != mesg ? [NSString stringWithUTF8String:mesg] : nil, @"mesg",
            nil];
        obj = [[StatusItemObject new] autorelease];
        conn = [NSConnection
            serviceConnectionWithName:[NSString stringWithUTF8String:prog] rootObject:obj];
        if (nil == conn)
        {
            obj = [NSConnection
                rootProxyForConnectionWithRegisteredName:[NSString stringWithUTF8String:prog]
                host:nil];
            [obj setStatusItem:dict];
        }
        else
        {
            statusItems = [NSMutableDictionary new];
            [obj performSelector:@selector(setStatusItem:) withObject:dict afterDelay:0];
            [[NSApplication sharedApplication] run];
        }
    }
}
int main(int argc, char *argv[])
{
    const char *prog, *name, *path = 0, *mesg = 0;
    int opt;
    opterr = 0;
    while (-1 != (opt = getopt(argc, argv, "m:")))
        switch (opt)
        {
        case 'm':
            mesg = optarg;
            break;
        case '?':
            usage(argv[0]);
            break;
        }
    if (1 > argc - optind || argc - optind > 2)
        usage(argv[0]);
    prog = realpath(argv[0], 0);
    if (0 == prog)
        fail("cannot get program path");
    name = argv[optind];
    if (2 == argc - optind)
    {
        path = realpath(argv[optind + 1], 0);
        if (0 == path)
            fail("cannot access image");
    }
    if (-1 == daemon(0, 0))
        fail("cannot daemonize");
    run(prog, name, path, mesg);
    return 0;
}
