//
//  BMCViewController.h
//  SocketTest
//
//  Created by Les Stroud on 11/1/12.
//  Copyright (c) 2012 Barnhardt Mfg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface BMCViewController : UIViewController{
   dispatch_queue_t print_queue;
}

@property (weak, nonatomic) IBOutlet UITextField *tf_ipaddress;
@property (weak, nonatomic) IBOutlet UITextField *tf_port;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sc_mechanism;
@property (weak, nonatomic) IBOutlet UISlider *sld_interations;
@property (weak, nonatomic) IBOutlet UIButton *btn_print;
@property (strong, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UILabel *lbl_iterations;

- (IBAction)printLabels:(id)sender;
- (IBAction)valueChanged:(id)sender;

@end
