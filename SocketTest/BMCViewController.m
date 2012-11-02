//
//  BMCViewController.m
//  SocketTest
//
//  Created by Les Stroud on 11/1/12.
//  Copyright (c) 2012 Barnhardt Mfg. All rights reserved.
//

#import "BMCViewController.h"

@interface BMCViewController ()

@end

@implementation BMCViewController

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   _tf_ipaddress.text = @"10.11.4.51";
   _tf_port.text = @"9100";
   
   print_queue = dispatch_queue_create("com.bmc.printqueue", DISPATCH_QUEUE_SERIAL);
   NSString* path = [[NSBundle mainBundle] pathForResource: @"apple_linen" ofType: @"jpg"];
   self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:path]];
   self.view.opaque = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
   [self setTf_ipaddress:nil];
   [self setTf_ipaddress:nil];
   [self setTf_port:nil];
   [self setSc_mechanism:nil];
   [self setSld_interations:nil];
   [self setBtn_print:nil];
   [self setView:nil];
   [self setLbl_iterations:nil];
   [super viewDidUnload];
}
- (IBAction)printLabels:(id)sender {
   NSError *fileError;
   NSString* path = [[NSBundle mainBundle] pathForResource: @"sampledata" ofType: @"txt"];
   NSString* data = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&fileError];
   if(data == nil){
      [[[UIAlertView alloc] initWithTitle:@"Error" message:[fileError description] delegate:NULL cancelButtonTitle:@"OK" otherButtonTitles:NULL, nil] show];
   }
   
   NSString* host = [_tf_ipaddress text];
   NSString* port = [_tf_port text];
   
   int iterations = (int)_sld_interations.value;
   if(_sc_mechanism.selectedSegmentIndex == 0){
      //BSD
      for (int i=0; i <= iterations-1; i++) {
         [self printWithBSDMechanism:data toIpAddress:host withPort:port];
      }
   } else {
      //CF  
      for (int i=0; i <= iterations-1; i++) {
         [self printWithCFMechanism:data toIpAddress:host withPort:port];
      }
   }
   
   
}

- (IBAction)valueChanged:(id)sender {
   _sld_interations.value = (int)roundf(_sld_interations.value);
   _lbl_iterations.text = [NSString stringWithFormat: @"%d", (int)_sld_interations.value];

}

-(void) printWithCFMechanism:(NSString *)data toIpAddress:(NSString *)ipaddress withPort:(NSString *)port {
      dispatch_async(
                     print_queue,
                     ^{
                        //Either create and open readstream, or pass NULL for readStream.  However, initializing a readstream
                        //that is not opened will prevent CF from correctly closing the socket.

                        CFWriteStreamRef writeStream = NULL;
                        
                        NSLog(@"[PLATFORM] Opening print network connections.");
                        
                        // Create socket.
                        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                                           (__bridge CFStringRef) ipaddress,
                                                           [port intValue],
                                                           NULL,
                                                           &writeStream);
                        
                        // Open write stream.
                        if (writeStream != NULL && CFWriteStreamOpen(writeStream)){
                           CFWriteStreamWrite(writeStream, (const UInt8 *)[data UTF8String], [data lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
                        }else{
                           NSLog(@"[PLATFORM] Unable to open write stream to device.");
                        }
                        
                        NSLog(@"[PLATFORM] Closing print network connections.");
                        CFWriteStreamClose(writeStream);
                        CFRelease(writeStream);
                        
                        //let's pause for station identification and to prevent overflowing buffers
                        [NSThread sleepForTimeInterval:0.100];
                        NSLog(@"[PLATFORM] Print thread complete.");
                        
                     });   
}

-(void) printWithBSDMechanism:(NSString *)data toIpAddress:(NSString *)ipaddress withPort:(NSString *)port  {
      
      dispatch_async(
                     print_queue,
                     ^{
                        //create local copies of the data in case they disappear (memory management)
                        NSString* _host = [ipaddress copy];
                        NSString* _port = [port copy];
                        NSString* _data = [data copy];
                        
                        NSLog(@"[PLATFORM] (Printing) Opening print network connections.");
                        
                        //create the address structure for the socket connection
                        struct sockaddr_in address;
                        memset(&address, 0, sizeof(address));
                        address.sin_len = sizeof(address);
                        address.sin_family = AF_INET;
                        address.sin_port = htons([_port intValue]);
                        if(inet_pton(AF_INET, [_host cStringUsingEncoding:NSASCIIStringEncoding], &address.sin_addr) < 1){
                           NSLog(@"[PLATFORM] (Printing) Unable to convert address %@ to network format", _host);
                           return;
                        };
                        
                        //create the socket
                        int socket_fd = socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
                        if (socket_fd == -1)
                        {
                           NSLog(@"[PLATFORM] (Printing) Error in socket() function");
                           return;
                        }
                        
                        //connect to the socket
                        if(connect(socket_fd, (struct sockaddr *)&address, sizeof(address)) < 0){
                           NSLog(@"[PLATFORM] (Printing) Error in bind() function");
                           close(socket_fd);
                           return;
                        }
                        
                        //write the data into the socket
                        int bytesWritten;
                        const char* buffer = [_data UTF8String];
                        int length = strlen(buffer);
                        
                        while(length > 0) {
                           bytesWritten = send(socket_fd, buffer, length, 0);
                           if(bytesWritten == -1){ // error
                              NSLog(@"[PLATFORM] (Printing) Error in bind() function");
                              close(socket_fd);
                              return;
                           }
                           buffer += bytesWritten;
                           length -= bytesWritten;
                        }
                        
                        //close the socket
                        NSLog(@"[PLATFORM] Closing print network connections.");
                        close(socket_fd);
                        
                        //let's pause for station identification and to prevent overflowing printer buffers
                        [NSThread sleepForTimeInterval:0.100];
                        NSLog(@"[PLATFORM] Print thread complete.");
                        return;
                     });   

}

@end
