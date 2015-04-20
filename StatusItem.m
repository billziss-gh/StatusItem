//usr/bin/clang -w -framework Foundation -framework AppKit "$0" "$@"; exit
/*
 * StatusItem.m
 *
 * Copyright (c) 2015 Bill Zissimopoulos. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this 
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, 
 * this list of conditions and the following disclaimer in the documentation 
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors 
 * may be used to endorse or promote products derived from this software without 
 * specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE 
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
- (NSArray *)listStatusItems
{
    return [[statusItems allKeys] sortedArrayUsingSelector:@selector(compare:)];
}
- (void)setStatusItem:(NSDictionary *)dict
{
    NSString *name, *path, *mesg;
    int remv;
    name = [dict objectForKey:@"name"];
    path = [dict objectForKey:@"path"];
    mesg = [dict objectForKey:@"mesg"];
    remv = [[dict objectForKey:@"remv"] intValue];
    NSStatusItem *item = [statusItems objectForKey:name];
    if (nil != path)
    {
        NSImage *image = [path hasPrefix:@":"] ?
            [NSImage imageNamed:[path substringFromIndex:1]] :
            [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
        if (nil != image)
        {
            image = ImageResize(image, CGSizeMake(18, 18));
            if (nil == item)
            {
                item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
                [item setHighlightMode:YES];
                [statusItems setObject:item forKey:name];
            }
            if (nil != mesg || remv)
            {
                NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
                if (nil != mesg)
                    [menu addItemWithTitle:mesg action:nil keyEquivalent:@""];
                if (remv)
                {
                    NSMenuItem *menuItem = [[[NSMenuItem alloc]
                        initWithTitle:@"Remove" action:@selector(removeStatusItemFromMenu:) keyEquivalent:@""]
                        autorelease];
                    [menuItem setTarget:self];
                    [menuItem setRepresentedObject:name];
                    [menu addItem:menuItem];
                }
                [item setMenu:menu];
            }
            [item setImage:image];
        }
    }
    else
    {
        if (nil != item)
        {
            [[NSStatusBar systemStatusBar] removeStatusItem:item];
            [statusItems removeObjectForKey:name];
        }
        if (0 == [statusItems count])
            [[NSApplication sharedApplication]
                performSelector:@selector(terminate:) withObject:nil afterDelay:0];
    }
}
- (void)removeStatusItemFromMenu:(id)sender
{
    NSString *name = [sender representedObject];
    if (nil != name)
        [self setStatusItem:[NSDictionary dictionaryWithObject:name forKey:@"name"]];
}
@end

void fail(const char *mesg)
{
    fprintf(stderr, "%s: %s\n", mesg, strerror(errno));
    exit(1);
}
void usage(char *prog)
{
    prog = basename(prog);
    fprintf(stderr,
        "usage: %s -l\n"
        "usage: %s [-m MESSAGE][-r] NAME [PATH|:NAME]\n",
        prog, prog);
    exit(2);
}
void list(const char *prog)
{
    NSArray *names;
    names = [[NSConnection
        rootProxyForConnectionWithRegisteredName:[NSString stringWithUTF8String:prog]
        host:nil] listStatusItems];
    for (NSString *name in names)
        printf("%s\n", [name UTF8String]);
}
void run(const char *prog, const char *name, const char *path, const char *mesg, int remv)
{
    @autoreleasepool
    {
        NSConnection *conn;
        NSDictionary *dict;
        id obj;
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithUTF8String:name], @"name",
            [NSNumber numberWithInt:remv], @"remv",
            0 != path ? [NSString stringWithUTF8String:path] : nil, @"path",
            0 != mesg ? [NSString stringWithUTF8String:mesg] : nil, @"mesg",
            nil];
        obj = [NSConnection
            rootProxyForConnectionWithRegisteredName:[NSString stringWithUTF8String:prog]
            host:nil];
        [obj setStatusItem:dict];
        if (nil == obj)
        {
            obj = [[StatusItemObject new] autorelease];
            conn = [NSConnection
                serviceConnectionWithName:[NSString stringWithUTF8String:prog] rootObject:obj];
            if (nil == conn)
            {
                /* 2nd attempt in case of race */
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
}
int main(int argc, char *argv[])
{
    const char *prog, *name, *path = 0, *mesg = 0;
    int opt, lopt = 0, ropt = 0;
    opterr = 0;
    while (-1 != (opt = getopt(argc, argv, "lm:r")))
        switch (opt)
        {
        case 'l':
            lopt = 1;
            break;
        case 'm':
            mesg = optarg;
            break;
        case 'r':
            ropt = 1;
            break;
        case '?':
            usage(argv[0]);
            break;
        }
    if (lopt)
    {
        if (0 != argc - optind)
            usage(argv[0]);
        prog = realpath(argv[0], 0);
        if (0 == prog)
            fail("cannot get program path");
        list(prog);
    }
    else
    {
        if (1 > argc - optind || argc - optind > 2)
            usage(argv[0]);
        prog = realpath(argv[0], 0);
        if (0 == prog)
            fail("cannot get program path");
        name = argv[optind];
        if (2 == argc - optind)
        {
            if (':' == argv[optind + 1][0])
                path = argv[optind + 1];
            else
            {
                path = realpath(argv[optind + 1], 0);
                if (0 == path)
                    fail("cannot access image");
            }
        }
        if (-1 == daemon(0, 0))
            fail("cannot daemonize");
        run(prog, name, path, mesg, ropt);
    }
    return 0;
}
