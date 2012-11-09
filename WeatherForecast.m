//
//  WeatherForecast.m
//  Weather
//
//  Created by Eugene Scherba on 1/14/11.
//  Copyright 2011 Boston University. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "JSONKit.h"
#import "WeatherForecast.h"
#import "WeatherModel.h"

@implementation WeatherForecast

//@synthesize location;
@synthesize date;
@synthesize condition;
@synthesize days;

#pragma mark - Instance Methods

// Public method: queryService
// Queries http://free.worldweatheronline.com/ for weather data
// Note that key to the web service is hard-coded here.
//
- (void)queryService:(CLLocationCoordinate2D)coord
{
	//viewController = (RSLocalPageController *)controller;
	[responseData release];
	responseData = [[NSMutableData data] retain];
	
    // TODO: move all private IDs to a separate header file
    // Note: if you are using this code, please apply for your own id at worldweatheronline.com
	NSString *url = [NSString stringWithFormat:@"http://free.worldweatheronline.com/feed/weather.ashx?q=%f,%f&format=json&num_of_days=5&key=d90609c900092229111111", coord.latitude, coord.longitude];
    NSLog(@"Fetching forecast from: %@", url);
    
	theURL = [NSURL URLWithString:url];
	NSURLRequest *request = [NSURLRequest requestWithURL:theURL];
	[[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
    NSLog(@"request sent");
}


// Lifecycle method: dealloc
- (void)dealloc
{
	//[viewController release];
	[responseData release];
	[theURL release];
    // [location release];
	[date release];
    // release RSCondition object
	[condition release];
    
    // release Days array
	[days release];
    
    // call super
	[super dealloc];
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"Connection did finish loading");
    // get content using JSONKit
    JSONDecoder *parser = [JSONDecoder decoder]; // autoreleased
    NSDictionary *data
    = [[parser objectWithData:responseData] objectForKey:@"data"];
    
    if (!data) {
        return;
    }
    
	// Forecast Information ///////////////////////////////////////
    //[self.location release];
	//self.location = [[[data objectForKey:@"request"] objectAtIndex:0] objectForKey:@"query"];
    
	// Current Conditions /////////////////////////////////////////
    RSCondition* rsCondition = [[RSCondition alloc] init];
    NSDictionary *current_condition = [[data objectForKey:@"current_condition"] objectAtIndex:0];
    if (current_condition) {
        rsCondition.iconURL
        = [[[current_condition objectForKey:@"weatherIconUrl"] objectAtIndex:0] objectForKey:@"value"];
        rsCondition.condition
        = [[[current_condition objectForKey:@"weatherDesc"] objectAtIndex:0] objectForKey:@"value"];
        rsCondition.tempC = [current_condition objectForKey:@"temp_C"];
        rsCondition.tempF = [current_condition objectForKey:@"temp_F"];
        rsCondition.humidity = [current_condition objectForKey:@"humidity"];
        rsCondition.wind = [current_condition objectForKey:@"windspeedMiles"];
    }
    [self.condition release];
    condition = rsCondition;
    
	// 5-day forecast ////////////////////////////////////////
    NSMutableArray* tmpDays = [[NSMutableArray alloc] initWithObjects:nil];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    NSArray *forecast = [data objectForKey:@"weather"];
    if (forecast) {
        for (NSDictionary *node in forecast) {
            NSDate *dayDate = [dateFormatter dateFromString:[node objectForKey:@"date"]];
            RSDay *rsDay = [[RSDay alloc] initWithDate:dayDate highT:[node objectForKey:@"tempMaxF"] lowT:[node objectForKey:@"tempMinF"] condition:[[[node objectForKey:@"weatherDesc"] objectAtIndex:0] objectForKey:@"value"] iconURL:[[[node objectForKey:@"weatherIconUrl"] objectAtIndex:0] objectForKey:@"value"]];
            [tmpDays addObject:rsDay];
            [rsDay release];
        }
	}
    
    [self.days release];
    days = tmpDays;
    
    [dateFormatter release];
    [responseData release];
    responseData = nil;
    
    NSLog(@"Notifying delegate that forecast had finished downloading");
	[self.delegate weatherForecastDidFinish:self];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection
			 willSendRequest:(NSURLRequest *)request
			redirectResponse:(NSURLResponse *)redirectResponse
{
	[theURL autorelease];
	theURL = [[request URL] retain];
	return request;
}

- (void)connection:(NSURLConnection *)connection
  didReceiveResponse:(NSURLResponse *)response
{
    // initialize mutable data
	[responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection
didReceiveData:(NSData *)data
{
    // append to NSMutableData
	[responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // handle error
}

@end
