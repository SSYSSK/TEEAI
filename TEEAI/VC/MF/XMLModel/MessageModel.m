//
//  MessageModel.m
//  MifiManager
//
//  Created by notion on 2018/3/29.
//  Copyright © 2018年 notion. All rights reserved.
//

#import "MessageModel.h"

@implementation MessageModel
+(instancetype) initWithResponseXmlString:(NSString *)responseXmlString isRGWStartXml:(BOOL) isRGWStartXml{
    return [[self alloc] initWithResponseXmlString:responseXmlString isRGWStartXml:isRGWStartXml];
}
-(instancetype) initWithResponseXmlString:(NSString *)responseXmlString isRGWStartXml:(BOOL) isRGWStartXml{
    self = [super init];
    GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithXMLString:responseXmlString options:0 error:nil];
    GDataXMLElement *xmlElement = [document rootElement];
    _deviceArray = [NSMutableArray array];
    [self dealXMLElement:xmlElement];
    return self;
}

- (void)dealXMLElement:(GDataXMLElement *)xmlElement{
    NSArray *childrenElements = [xmlElement children];
    for (int i = 0; i < [childrenElements count]; i++) {
        GDataXMLElement *ele = [childrenElements objectAtIndex:i];
        NSLog(@"element_%@",ele);
        if ([[ele name] isEqualToString:@"message"]) {
            NSArray *devices = [ele children];
            for (int item=0; item<devices.count; item++) {
                GDataXMLElement *listElement = devices[item];
                if ([[listElement name] isEqualToString:@"get_message"]) {
                    GDataXMLElement *messageList = [listElement elementsForName:@"message_list"][0];
                    NSArray *deviceArray = [messageList elementsForName:@"Item"];
                    for (int index = 0; index <deviceArray.count; index++) {
                        MessageInfo *device = [MessageInfo initWithXMLElement:deviceArray[index]];
                        [_deviceArray addObject:device];
                    }
                }else if ([[listElement name] isEqualToString:@"flag"]){
                    NSArray *flagNode = [listElement children];
                    for (GDataXMLNode *node in flagNode) {
                        if ([[node name] isEqualToString:@"sms_cmd_status_result"]) {
                            _sendMessageResult = node.stringValue;
                        }
                    }
                }
                
            }
        } else {
            
        }
    }
}



@end
