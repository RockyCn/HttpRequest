//
//  AppDelegate.m
//
//  Created by Ben Copsey on 09/07/2008.
//  Copyright 2008 All-Seeing Interactive Ltd. All rights reserved.
//

#import "AppDelegate.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"
#import "ASIDownloadCache.h"
#import "ASIWebPageRequest.h"

@interface AppDelegate ()
- (void)updateBandwidthUsageIndicator;
- (void)URLFetchWithProgressComplete:(ASIHTTPRequest *)request;
- (void)URLFetchWithProgressFailed:(ASIHTTPRequest *)request;
- (void)imageFetch1Complete:(ASIHTTPRequest *)request;
- (void)imageFetch2Complete:(ASIHTTPRequest *)request;
- (void)imageFetch3Complete:(ASIHTTPRequest *)request;
- (void)topSecretFetchComplete:(ASIHTTPRequest *)request;
- (void)authSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)postFinished:(ASIHTTPRequest *)request;
- (void)postFailed:(ASIHTTPRequest *)request;
- (void)fetchURL:(NSURL *)url;
- (void)tableViewDataFetchFinished:(ASIHTTPRequest *)request;
- (void)rowImageDownloadFinished:(ASIHTTPRequest *)request;
- (void)webPageFetchFailed:(ASIHTTPRequest *)request;
- (void)webPageFetchSucceeded:(ASIHTTPRequest *)request;
@end

@implementation AppDelegate


- (id)init
{
	[super init];
	networkQueue = [[ASINetworkQueue alloc] init];
	[NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(updateBandwidthUsageIndicator)
                                   userInfo:nil
                                    repeats:YES];
    
    [self performSelector:@selector(requestDownloadFiles)
               withObject:nil
               afterDelay:10];
    
	return self;
}

- (void)dealloc
{
	[networkQueue release];
	[super dealloc];
}


- (IBAction)simpleURLFetch:(id)sender
{
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com"]] autorelease];
	
	//Customise our user agent, for no real reason
	[request addRequestHeader:@"User-Agent" value:@"ASIHTTPRequest"];
	[request setDelegate:self];
	[request startSynchronous];
	if ([request error]) {
		[htmlSource setString:[[request error] localizedDescription]];
	} else if ([request responseString]) {
		[htmlSource setString:[request responseString]];
	}
}



- (IBAction)URLFetchWithProgress:(id)sender
{
	[startButton setTitle:@"Stop"];
	[startButton setAction:@selector(stopURLFetchWithProgress:)];
	
	NSString *tempFile = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"The Great American Novel.txt.download"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:tempFile]) {
		[[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
	}
	
	[self resumeURLFetchWithProgress:self];
}


- (IBAction)stopURLFetchWithProgress:(id)sender
{
	[startButton setTitle:@"Start"];
	[startButton setAction:@selector(URLFetchWithProgress:)];
	[[self bigFetchRequest] cancel];
	[self setBigFetchRequest:nil];
	[resumeButton setEnabled:YES];
}

- (IBAction)resumeURLFetchWithProgress:(id)sender
{
	[fileLocation setStringValue:@"(Request running)"];
	[resumeButton setEnabled:NO];
	[startButton setTitle:@"Stop"];
	[startButton setAction:@selector(stopURLFetchWithProgress:)];
	
	// Stop any other requests
	[networkQueue reset];
	
	[self setBigFetchRequest:[ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/redirect_resume"]]];
	[[self bigFetchRequest] setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"The Great American Novel.txt"]];
	[[self bigFetchRequest] setTemporaryFileDownloadPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"The Great American Novel.txt.download"]];
	[[self bigFetchRequest] setAllowResumeForFileDownloads:YES];
	[[self bigFetchRequest] setDelegate:self];
	[[self bigFetchRequest] setDidFinishSelector:@selector(URLFetchWithProgressComplete:)];
	[[self bigFetchRequest] setDidFailSelector:@selector(URLFetchWithProgressFailed:)];
	[[self bigFetchRequest] setDownloadProgressDelegate:progressIndicator];
	[[self bigFetchRequest] startAsynchronous];
}

- (void)URLFetchWithProgressComplete:(ASIHTTPRequest *)request
{
	[fileLocation setStringValue:[NSString stringWithFormat:@"File downloaded to %@",[request downloadDestinationPath]]];
	[startButton setTitle:@"Start"];
	[startButton setAction:@selector(URLFetchWithProgress:)];
}

- (void)URLFetchWithProgressFailed:(ASIHTTPRequest *)request
{
	if ([[request error] domain] == NetworkRequestErrorDomain && [[request error] code] == ASIRequestCancelledErrorType) {
		[fileLocation setStringValue:@"(Request paused)"];
	} else {
		[fileLocation setStringValue:[NSString stringWithFormat:@"An error occurred: %@",[[request error] localizedDescription]]];
		[startButton setTitle:@"Start"];
		[startButton setAction:@selector(URLFetchWithProgress:)];
	}
}

- (IBAction)fetchThreeImages:(id)sender
{
	[imageView1 setImage:nil];
	[imageView2 setImage:nil];
	[imageView3 setImage:nil];
	
	[networkQueue reset];
	[networkQueue setDownloadProgressDelegate:progressIndicator];
	[networkQueue setDelegate:self];
	[networkQueue setShowAccurateProgress:([showAccurateProgress state] == NSOnState)];
	
	ASIHTTPRequest *request;
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/images/small-image.jpg"]] autorelease];
	[request setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"1.png"]];
	[request setDownloadProgressDelegate:imageProgress1];
	[request setDidFinishSelector:@selector(imageFetch1Complete:)];
	[request setDelegate:self];
	[networkQueue addOperation:request];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/images/medium-image.jpg"]] autorelease];
	[request setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"2.png"]];
	[request setDownloadProgressDelegate:imageProgress2];
	[request setDidFinishSelector:@selector(imageFetch2Complete:)];
	[request setDelegate:self];
	[networkQueue addOperation:request];
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/images/large-image.jpg"]] autorelease];
	[request setDownloadDestinationPath:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"3.png"]];
	[request setDownloadProgressDelegate:imageProgress3];
	[request setDidFinishSelector:@selector(imageFetch3Complete:)];
	[request setDelegate:self];
	[networkQueue addOperation:request];
	
	
	[networkQueue go];
}

- (void)updateBandwidthUsageIndicator
{
	[bandwidthUsed setStringValue:[NSString stringWithFormat:@"%luKB / second",[ASIHTTPRequest averageBandwidthUsedPerSecond]/1024]];
}

- (IBAction)throttleBandwidth:(id)sender
{
	if ([(NSButton *)sender state] == NSOnState) {
		[ASIHTTPRequest setMaxBandwidthPerSecond:ASIWWANBandwidthThrottleAmount];
	} else {
		[ASIHTTPRequest setMaxBandwidthPerSecond:0];
	}
}


- (void)imageFetch1Complete:(ASIHTTPRequest *)request
{
	NSImage *img = [[[NSImage alloc] initWithContentsOfFile:[request downloadDestinationPath]] autorelease];
	if (img) {
		[imageView1 setImage:img];
	}
}

- (void)imageFetch2Complete:(ASIHTTPRequest *)request
{
	NSImage *img = [[[NSImage alloc] initWithContentsOfFile:[request downloadDestinationPath]] autorelease];
	if (img) {
		[imageView2 setImage:img];
	}
}


- (void)imageFetch3Complete:(ASIHTTPRequest *)request
{
	NSImage *img = [[[NSImage alloc] initWithContentsOfFile:[request downloadDestinationPath]] autorelease];
	if (img) {
		[imageView3 setImage:img];
	}
}


- (IBAction)fetchTopSecretInformation:(id)sender
{
	[networkQueue reset];
	
	[progressIndicator setDoubleValue:0];
	
	ASIHTTPRequest *request;
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/top_secret/"]] autorelease];
	[request setDidFinishSelector:@selector(topSecretFetchComplete:)];
	[request setDelegate:self];
	[request setUseKeychainPersistence:[keychainCheckbox state]];
	[request startAsynchronous];

}

- (void)topSecretFetchComplete:(ASIHTTPRequest *)request
{
	if (![request error]) {
		[topSecretInfo setStringValue:[request responseString]];
		[topSecretInfo setFont:[NSFont boldSystemFontOfSize:13]];
	}
}

- (void)authenticationNeededForRequest:(ASIHTTPRequest *)request
{
	[realm setStringValue:[request authenticationRealm]];
	[host setStringValue:[[request url] host]];

	[NSApp beginSheet: loginWindow
		modalForWindow: window
		modalDelegate: self
		didEndSelector: @selector(authSheetDidEnd:returnCode:contextInfo:)
		contextInfo: request];
}

- (void)proxyAuthenticationNeededForRequest:(ASIHTTPRequest *)request
{
	[realm setStringValue:[request proxyAuthenticationRealm]];
	[host setStringValue:[request proxyHost]];
	
	[NSApp beginSheet: loginWindow
	   modalForWindow: window
		modalDelegate: self
	   didEndSelector: @selector(authSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: request];
}


- (IBAction)dismissAuthSheet:(id)sender {
    [[NSApplication sharedApplication] endSheet: loginWindow returnCode: [(NSControl*)sender tag]];
}

- (void)authSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	ASIHTTPRequest *request = (ASIHTTPRequest *)contextInfo;
    if (returnCode == NSOKButton) {
		if ([request authenticationNeeded] == ASIProxyAuthenticationNeeded) {
			[request setProxyUsername:[[[username stringValue] copy] autorelease]];
			[request setProxyPassword:[[[password stringValue] copy] autorelease]];			
		} else {
			[request setUsername:[[[username stringValue] copy] autorelease]];
			[request setPassword:[[[password stringValue] copy] autorelease]];
		}
		[request retryUsingSuppliedCredentials];
    } else {
		[request cancelAuthentication];
	}
    [loginWindow orderOut: self];
}

- (IBAction)postWithProgress:(id)sender
{	
	//Create a 1MB file
	NSMutableData *data = [NSMutableData dataWithLength:1024*1024];
	NSString *path = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"bigfile"];
	[data writeToFile:path atomically:NO];
	
	
	[networkQueue reset];
	[networkQueue setShowAccurateProgress:YES];
	[networkQueue setUploadProgressDelegate:progressIndicator];
	[networkQueue setRequestDidFailSelector:@selector(postFailed:)];
	[networkQueue setRequestDidFinishSelector:@selector(postFinished:)];
	[networkQueue setDelegate:self];
	
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ignore"]] autorelease];
	[request setPostValue:@"test" forKey:@"value1"];
	[request setPostValue:@"test" forKey:@"value2"];
	[request setPostValue:@"test" forKey:@"value3"];
	[request setFile:path forKey:@"file"];
	

	[networkQueue addOperation:request];
	[networkQueue go];
}

- (void)postFinished:(ASIHTTPRequest *)request
{
	[postStatus setStringValue:@"Post Finished"];
}
- (void)postFailed:(ASIHTTPRequest *)request
{
	[postStatus setStringValue:[NSString stringWithFormat:@"Post Failed: %@",[[request error] localizedDescription]]];
}


- (IBAction)reloadTableData:(id)sender
{
	[[self tableQueue] cancelAllOperations];
	[self setRowData:[NSMutableArray array]];
	[tableView reloadData];

	[self setTableQueue:[ASINetworkQueue queue]];
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://allseeing-i.com/ASIHTTPRequest/tests/table-row-data.xml"]];
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request setDidFinishSelector:@selector(tableViewDataFetchFinished:)];
	[request setDelegate:self];
	[[self tableQueue] addOperation:request];
	[[self tableQueue] setDownloadProgressDelegate:progressIndicator];
	[[self tableQueue] go];
}

- (void)tableViewDataFetchFailed:(ASIHTTPRequest *)request
{
	if ([[request error] domain] != NetworkRequestErrorDomain || ![[request error] code] == ASIRequestCancelledErrorType) {
		[tableLoadStatus setStringValue:@"Loading data failed"];
	}
}

- (void)tableViewDataFetchFinished:(ASIHTTPRequest *)request
{
	NSXMLDocument *xml = [[[NSXMLDocument alloc] initWithData:[request responseData] options:NSXMLDocumentValidate error:nil] autorelease];
	for (NSXMLElement *row in [[xml rootElement] elementsForName:@"row"]) {
		NSMutableDictionary *rowInfo = [NSMutableDictionary dictionary];
		NSString *description = [[[row elementsForName:@"description"] objectAtIndex:0] stringValue];
		[rowInfo setValue:description forKey:@"description"];
		NSString *imageURL = [[[row elementsForName:@"image"] objectAtIndex:0] stringValue];
		ASIHTTPRequest *imageRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:imageURL]];
		[imageRequest setDownloadCache:[ASIDownloadCache sharedCache]];
		[imageRequest setDidFinishSelector:@selector(rowImageDownloadFinished:)];
		[imageRequest setDidFailSelector:@selector(tableViewDataFetchFailed:)];
		[imageRequest setDelegate:self];
		[imageRequest setUserInfo:rowInfo];
		[[self tableQueue] addOperation:imageRequest];
		[[self rowData] addObject:rowInfo];
	}
	[tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return (NSInteger)[[self rowData] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([[aTableColumn identifier] isEqualToString:@"image"]) {
		return [[[self rowData] objectAtIndex:(NSUInteger)rowIndex] objectForKey:@"image"];
	} else {
		return [[[self rowData] objectAtIndex:(NSUInteger)rowIndex] objectForKey:@"description"];
	}
}


- (void)rowImageDownloadFinished:(ASIHTTPRequest *)request
{
	NSImage *image = [[[NSImage alloc] initWithData:[request responseData]] autorelease];
	[(NSMutableDictionary *)[request userInfo] setObject:image forKey:@"image"];
	[tableView reloadData]; // Not efficient, but I hate table view programming :)
}

- (IBAction)clearCache:(id)sender
{
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
	[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
}

- (IBAction)fetchWebPage:(id)sender
{
	[self fetchURL:[NSURL URLWithString:[urlField stringValue]]];

}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id)listener
{
	// If this is a web page we've requested ourselves, let it load
	if ([[actionInformation objectForKey:WebActionNavigationTypeKey] intValue] == WebNavigationTypeOther) {
		[listener use];
		return;
	}

	// If the user clicked on a link, let's tell the webview to ignore it, and we'll load it ourselves
	[self fetchURL:[NSURL URLWithString:[[request URL] absoluteString] relativeToURL:[NSURL URLWithString:[urlField stringValue]]]];
	[listener ignore];
}

- (void)fetchURL:(NSURL *)url
{
	ASIWebPageRequest *request = [ASIWebPageRequest requestWithURL:url];
	[request setDidFailSelector:@selector(webPageFetchFailed:)];
	[request setDidFinishSelector:@selector(webPageFetchSucceeded:)];
	[request setDelegate:self];
	[request setShowAccurateProgress:NO];
	[request setDownloadProgressDelegate:progressIndicator];
	[request setUrlReplacementMode:([dataURICheckbox state] == NSOnState ? ASIReplaceExternalResourcesWithData : ASIReplaceExternalResourcesWithLocalURLs)];

	// It is strongly recommended that you set both a downloadCache and a downloadDestinationPath for all ASIWebPageRequests
	[request setDownloadCache:[ASIDownloadCache sharedCache]];
	[request setDownloadDestinationPath:[[ASIDownloadCache sharedCache] pathToStoreCachedResponseDataForRequest:request]];

	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
	[request startAsynchronous];
}

- (void)webPageFetchFailed:(ASIHTTPRequest *)request
{
	[[NSAlert alertWithError:[request error]] runModal];
}

- (void)webPageFetchSucceeded:(ASIHTTPRequest *)request
{
	NSURL *baseURL;
	if ([dataURICheckbox state] == NSOnState) {
		baseURL = [request url];

		// If we're using ASIReplaceExternalResourcesWithLocalURLs, we must set the baseURL to point to our locally cached file
	} else {
		baseURL = [NSURL fileURLWithPath:[request downloadDestinationPath]];
	}

	if ([request downloadDestinationPath]) {
		NSString *response = [NSString stringWithContentsOfFile:[request downloadDestinationPath] encoding:[request responseEncoding] error:nil];
		[webPageSource setString:response];
		[[webView mainFrame] loadHTMLString:response baseURL:baseURL];
	} else if ([request responseString]) {
		[webPageSource setString:[request responseString]];
		[[webView mainFrame] loadHTMLString:[request responseString] baseURL:baseURL];
	}

	[urlField setStringValue:[[request url] absoluteString]];
}


- (BOOL)requestDownloadFiles
{
    NSArray *allPic = @[@"http://www.voanews.com/img/icon-video.gif",
                        @"http://www.voanews.com/img/word_icon.gif",
                        @"http://www.voanews.com/img/excel_icon.gif",
                        @"http://www.voanews.com/img/PP_icon.gif",
                        @"http://www.voanews.com/img/pdf_icon.gif",
                        @"http://www.voanews.com/img/txt_icon.gif",
                        @"http://www.voanews.com/img/icon-soundslide.gif",
                        @"http://www.voanews.com/img/icon-photogallary.gif",
                        @"http://www.voanews.com/img/blue_bullet.jpg",
                        @"http://www.voanews.com/img/icon-loader.gif",
                        @"http://www.voanews.com/img/icon-rss.gif",
                        @"http://www.voanews.com/img/icon-transcript.gif",
                        @"http://www.voanews.com/img/icon_radio_signal.gif",
                        @"http://www.voanews.com/img/blue_bullet.jpg",
                        @"http://www.voanews.com/img/blue_bullet.jpg",
                        @"http://www.voanews.com/img/icon-exclamation.gif",
                        @"http://www.voanews.com/img/icon-exclamation.gif",
                        @"http://www.voanews.com/img/h3_bullet.gif",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_rtl.png",
                        @"http://www.voanews.com/img/top_logo.gif",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/img_mainmenu_separator.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_NETWORKING_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_RSS_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_RSS_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_RSS_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_MEDIA_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_MEDIA_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/scheduler_double_arrow.gif",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/tabs_separator.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/multimedia_comment_border.gif",
                        @"http://www.voanews.com/img/multimedia_comment_border_o.gif",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_ltr.png",
                        @"http://www.voanews.com/img/mmw_close.gif",
                        @"http://www.voanews.com/img/mmw_close_hover.gif",
                        @"http://www.voanews.com/img/mmw_close_hit.gif",
                        @"http://www.voanews.com/img/soundOverlayMed.png",
                        @"http://www.voanews.com/img/bg-multimedia-selected-image-top.gif",
                        @"http://www.voanews.com/img/multimedia_comment_border.gif",
                        @"http://www.voanews.com/img/bg_line.gif",
                        @"http://www.voanews.com/img/icon-loader-white.gif",
                        @"http://www.voanews.com/img/playlist_up_icon.gif",
                        @"http://www.voanews.com/img/playlist_down_icon.gif",
                        @"http://www.voanews.com/img/playlist_up_hover_icon.gif",
                        @"http://www.voanews.com/img/playlist_down_hover_icon.gif",
                        @"http://www.voanews.com/img/playlist_play_icon.gif",
                        @"http://www.voanews.com/img/playlist_play_hover_icon.gif",
                        @"http://www.voanews.com/img/playlist_remove_icon.gif",
                        @"http://www.voanews.com/img/h3_bullet.gif",
                        @"http://www.voanews.com/img/bg_line.gif",
                        @"http://www.voanews.com/img/bg-carousel-pagerline.png",
                        @"http://www.voanews.com/img/bg-carousel-pager-normal.png",
                        @"http://www.voanews.com/img/bg-carousel-pager-active.png",
                        @"http://www.voanews.com/img/bg_line_h2.gif",
                        @"http://www.voanews.com/img/bg_line_h2.gif",
                        @"http://www.voanews.com/img/ico_keyboard_orange_bg.jpg",
                        @"http://www.voanews.com/img/aspectratio_true.gif",
                        @"http://www.voanews.com/img/aspectratio_false.gif",
                        @"http://www.voanews.com/img/bg_line.gif",
                        @"http://www.voanews.com/img/sprites/icons_PLAYER_v2.png",
                        @"http://www.voanews.com/img/sprites/icons_PLAYER_v2.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/vr-audio-widget.png",
                        @"http://www.voanews.com/img/bg-black-75.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_rtl.png",
                        @"http://www.voanews.com/img/img-tsc-arrow.gif",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_MEDIA_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_ARROWS_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/hr-audio-widget.png",
                        @"http://www.voanews.com/img/hr-audio-widget.png",
                        @"http://www.voanews.com/img/sprites/icons_SMALL_rtl.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/sprites/icons_BIG_ltr.png",
                        @"http://www.voanews.com/img/blockquote_bg.png",
                        @"http://www.voanews.com/img/lines_top_quot.gif",
                        @"http://www.voanews.com/img/blue_bullet.jpg",
                        @"http://www.voanews.com/img/quote_orange.png",
                        @"http://www.voanews.com/img/icon-photogallary.gif",
                        @"http://www.voanews.com/img/h3_bullet_transparent.gif",
                        @"http://www.voanews.com/img/sprites/social_icons_widget.png",
                        @"http://www.voanews.com/img/loading.gif",
                        @"http://www.voanews.com/img/icon-exclamation.gif",
                        @"http://www.voanews.com/img/bg_horizontal_separator.gif",
                        @"http://www.voanews.com/img/icon-exclamation.gif",
                        @"http://www.voanews.com/img/bg_line.gif",
                        @"http://www.voanews.com/img/fb-button-bg.png",
                        @"http://www.voanews.com/img/fancybox/fancybox.png",
                        @"http://www.voanews.com/img/fancybox/fancybox.png",
                        @"http://www.voanews.com/img/fancybox/blank.gif",
                        @"http://www.voanews.com/img/fancybox/fancy_nav_left.png",
                        @"http://www.voanews.com/img/fancybox/fancy_nav_right.png",
                        @"http://www.voanews.com/img/fancybox/fancybox-x.png",
                        @"http://www.voanews.com/img/fancybox/fancybox.png",
                        @"http://www.voanews.com/img/fancybox/fancybox-y.png",
                        @"http://www.voanews.com/img/fancybox/fancybox.png",
                        @"http://www.voanews.com/img/fancybox/fancybox-x.png",
                        @"http://www.voanews.com/img/fancybox/fancybox.png",
                        @"http://www.voanews.com/img/fancybox/fancybox-y.png",
                        @"http://www.voanews.com/img/fancybox/fancybox.png",
                        @"http://www.voanews.com/img/fancybox/fancy_title_over.png",
                        @"http://www.voanews.com/img/fancybox/fancybox.png",
                        @"http://www.voanews.com/img/fancybox/fancybox-x.png",
                        @"http://www.voanews.com/img/fancybox/fancybox.png",
                        @"http://www.voanews.com/img/fancybox/fancy_close.png",
                        @"http://www.voanews.com/img/fancybox/fancy_nav_left.png",
                        @"http://www.voanews.com/img/fancybox/fancy_nav_right.png",
                        @"http://www.voanews.com/img/fancybox/fancy_title_over.png",
                        @"http://www.voanews.com/img/fancybox/fancy_title_left.png",
                        @"http://www.voanews.com/img/fancybox/fancy_title_main.png",
                        @"http://www.voanews.com/img/fancybox/fancy_title_right.png",
                        @"http://www.voanews.com/img/fancybox/fancy_loading.png",
                        @"http://www.voanews.com/img/fancybox/bg-msie.png",
                        @"http://www.voanews.com/img/fancybox/fancy_shadow_n.png",
                        @"http://www.voanews.com/img/fancybox/fancy_shadow_ne.png",
                        @"http://www.voanews.com/img/fancybox/fancy_shadow_e.png",
                        @"http://www.voanews.com/img/fancybox/fancy_shadow_se.png",
                        @"http://www.voanews.com/img/fancybox/fancy_shadow_s.png",
                        @"http://www.voanews.com/img/fancybox/fancy_shadow_sw.png",
                        @"http://www.voanews.com/img/fancybox/fancy_shadow_w.png",
                        @"http://www.voanews.com/img/fancybox/fancy_shadow_nw.png",
                        @"http://www.voanews.com/img/loading.gif",
                        @"http://www.voanews.com/img/opacity-50p-000000.png",
                        @"http://www.voanews.com/img/sprites/icons_PLAYER_v2.png",
                        @"http://www.voanews.com/img/html5PlayerLogo_RFERL.gif",
                        @"http://www.voanews.com/img/html5LiveProgressBarBg.gif"
                        ];
    
    
    
    NSURL *url = nil;
    for (NSString *item in allPic)
    {
        url = [NSURL URLWithString:item];
        ASIHTTPRequest *httpRequest = [ASIHTTPRequest requestWithURL:url];
        
        //    httpRequest.timeOutSeconds = 10;
        [httpRequest setDelegate:self];
        [httpRequest startAsynchronous];
    }
    
    return YES;
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSString *link = request.url.absoluteString;
    
    link = [link stringByReplacingOccurrencesOfString:@"http://www.voanews.com/img/" withString:@""];
    
    NSArray *folders = [link componentsSeparatedByString:@"/"];
    
//    NSString *baseDirectory = @"~/Desktop/";
    NSString *baseDirectory = NSTemporaryDirectory();
    baseDirectory = [baseDirectory stringByAppendingPathComponent:@"img"];
    [[NSFileManager defaultManager] createDirectoryAtPath:baseDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    
    
    NSString *path = [baseDirectory stringByAppendingPathComponent:folders.firstObject];
    if (folders.count > 1)
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        path = [path stringByAppendingPathComponent:folders[1]];
    }
    
    NSData *responseData = [request responseData];
    
    
    BOOL issucc = [[NSFileManager defaultManager] createFileAtPath:path
                                                          contents:responseData
                                                        attributes:nil];
    
    NSLog(@"Rockysaid:save img: %@ succ = %d", link, issucc);
}


- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"Rockysaid:failed to save img: %@", request.url);
    
}

@synthesize bigFetchRequest;
@synthesize rowData;
@synthesize tableQueue;
@end
