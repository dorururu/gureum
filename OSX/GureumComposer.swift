//
//  GureumComposer.swift
//  Gureum
//
//  Created by Hyewon on 2018. 9. 7..
//  Copyright © 2018년 youknowone.org. All rights reserved.
//
/*!
 @brief  구름 입력기의 합성기
 
 입력 모드에 따라 libhangul을 이용하여 문자를 합성해 준다.
 */

import Foundation

@objc public class GureumInputSourceIdentifier: NSObject {
    @objc public static let qwerty = "org.youknowone.inputmethod.Gureum.qwerty"
    @objc static let dvorak = "org.youknowone.inputmethod.Gureum.dvorak"
    @objc static let dvorakQwertyCommand = "org.youknowone.inputmethod.Gureum.dvorakq"
    @objc static let colemak = "org.youknowone.inputmethod.Gureum.colemak"
    @objc static let colemakQwertyCommand = "org.youknowone.inputmethod.Gureum.colemakq"
    @objc static let han2 = "org.youknowone.inputmethod.Gureum.han2"
    @objc static let han2Classic = "org.youknowone.inputmethod.Gureum.han2classic"
    @objc static let han3Final = "org.youknowone.inputmethod.Gureum.han3final"
    @objc static let han390 = "org.youknowone.inputmethod.Gureum.han390"
    @objc static let han3NoShift = "org.youknowone.inputmethod.Gureum.han3noshift"
    @objc static let han3Classic = "org.youknowone.inputmethod.Gureum.han3classic"
    @objc static let han3Layout2 = "org.youknowone.inputmethod.Gureum.han3layout2"
    @objc static let hanAhnmatae = "org.youknowone.inputmethod.Gureum.hanahnmatae"
    @objc static let hanRoman = "org.youknowone.inputmethod.Gureum.hanroman"
    @objc static let han3FinalNoShift = "org.youknowone.inputmethod.Gureum.han3finalnoshift"
    @objc static let han3_2011 = "org.youknowone.inputmethod.Gureum.han3-2011"
    @objc static let han3_2012 = "org.youknowone.inputmethod.Gureum.han3-2012"
    @objc static let han3_2014 = "org.youknowone.inputmethod.Gureum.han3-2014"
    @objc static let han3_2015 = "org.youknowone.inputmethod.Gureum.han3-2015"
}

let GureumInputSourceToHangulKeyboardIdentifierTable: [String: String] = [
    GureumInputSourceIdentifier.qwerty : "",
    GureumInputSourceIdentifier.han2 : "2",
    GureumInputSourceIdentifier.han2Classic : "2y",
    GureumInputSourceIdentifier.han3Final : "3f",
    GureumInputSourceIdentifier.han390 : "39",
    GureumInputSourceIdentifier.han3NoShift : "3s",
    GureumInputSourceIdentifier.han3Classic : "3y",
    GureumInputSourceIdentifier.han3Layout2 : "32",
    GureumInputSourceIdentifier.hanRoman : "ro",
    GureumInputSourceIdentifier.hanAhnmatae : "ahn",
    GureumInputSourceIdentifier.han3FinalNoShift : "3gs",
    GureumInputSourceIdentifier.han3_2011 : "3-2011",
    GureumInputSourceIdentifier.han3_2012 : "3-2012",
    GureumInputSourceIdentifier.han3_2014 : "3-2014",
    GureumInputSourceIdentifier.han3_2015 : "3-2015",
]

@objcMembers class GureumComposer: CIMComposer {
    @objc var romanComposer: RomanComposer
    @objc var hangulComposer: HangulComposer
    @objc var hanjaComposer: HanjaComposer
    @objc var emoticonComposer: EmoticonComposer
    var ioConnect: IOConnect

    override init() {
        romanComposer = RomanComposer()
        hangulComposer = HangulComposer(keyboardIdentifier: "2")!
        hanjaComposer = HanjaComposer()
        hanjaComposer.delegate = hangulComposer
        emoticonComposer = EmoticonComposer()
        let service = try! IOService.init(name: kIOHIDSystemClass)
        ioConnect = service.open(owningTask: mach_task_self_, type: kIOHIDParamConnectType)!
        super.init()
        self.delegate = romanComposer
    }
    
    @objc override var inputMode: String {
        get {
            return super.inputMode
        }
        set {
            guard self.inputMode != newValue else {
                return
            }

            guard let keyboardIdentifier = GureumInputSourceToHangulKeyboardIdentifierTable[newValue] else {
                return
            }
            
            if keyboardIdentifier.count == 0 {
                self.delegate = romanComposer
            } else {
                self.delegate = hangulComposer
                // 단축키 지원을 위해 마지막 자판을 기억
                hangulComposer.setKeyboardWithIdentifier(keyboardIdentifier)
                GureumConfiguration.shared().lastHangulInputMode = newValue
            }
            super.inputMode = newValue
        }
    }
    
    @objc override func inputController(_ controller: CIMInputController, command string: String?, key keyCode: Int, modifiers flags: NSEvent.ModifierFlags, client sender: Any) -> CIMInputTextProcessResult {
        let configuration = GureumConfiguration.shared()
        let inputModifier = flags.intersection(NSEvent.ModifierFlags.deviceIndependentFlagsMask).intersection(NSEvent.ModifierFlags(rawValue: ~NSEvent.ModifierFlags.capsLock.rawValue))
        var need_exchange = false
        var delegatedComposer: CIMComposerDelegate? = nil
//    if (string == nil) {
//        NSUInteger modifierKey = flags & 0xff;
//        if (self->lastModifier != 0 && modifierKey == 0) {
//            dlog(DEBUG_SHORTCUT, @"**** Trigger modifier: %lx ****", self->lastModifier);
//            NSDictionary *correspondedConfigurations = @{
//                                                         @(0x01): @(CIMSharedConfiguration->leftControlKeyShortcutBehavior),
//                                                         @(0x20): @(CIMSharedConfiguration->leftOptionKeyShortcutBehavior),
//                                                         @(0x08): @(CIMSharedConfiguration->leftCommandKeyShortcutBehavior),
//                                                         @(0x10): @(CIMSharedConfiguration->leftCommandKeyShortcutBehavior),
//                                                         @(0x40): @(CIMSharedConfiguration->leftOptionKeyShortcutBehavior),
//                                                         };
//            for (NSNumber *marker in @[@(0x01), @(0x20), @(0x08), @(0x10), @(0x40)]) {
//                if (self->lastModifier == marker.unsignedIntegerValue ) {
//                    NSInteger configuration = [correspondedConfigurations[marker] integerValue];
//                    switch (configuration) {
//                        case 0:
//                            break;
//                        case 1: {
//                            dlog(DEBUG_SHORTCUT, @"**** Layout exchange by exchange modifier ****");
//                            need_exchange = YES;
//                        }   break;
//                        case 2: {
//                            dlog(DEBUG_SHORTCUT, @"**** Hanja mode by hanja modifier ****");
//                            need_hanjamode = YES;
//                        }   break;
//                        case 3: if (self.delegate == self->hangulComposer) {
//                            dlog(DEBUG_SHORTCUT, @"**** Layout exchange by change to english modifier ****");
//                            need_exchange = YES;
//                        }   break;
//                        case 4: if (self.delegate == self->romanComposer) {
//                            dlog(DEBUG_SHORTCUT, @"**** Layout exchange by change to korean modifier ****");
//                            need_exchange = YES;
//                        }   break;
//                        default:
//                            dassert(NO);
//                            break;
//                    }
//                }
//            }
//        } else {
//            self->lastModifier = modifierKey;
//            dlog(DEBUG_SHORTCUT, @"**** Save modifier: %lx ****", self->lastModifier);
//        }
//    } else
//    {
        // Handle SpecialKeyCode first
        switch keyCode {
        case CIMInputControllerSpecialKeyCode.capsLockPressed.rawValue:
            guard configuration.enableCapslockToToggleInputMode else {
                return CIMInputTextProcessResult.processed
            }

            if self.delegate === romanComposer || self.delegate === hangulComposer {
                need_exchange = true
            }
            self.ioConnect.setCapsLockLed(false)

            if !need_exchange {
                return CIMInputTextProcessResult.processed
            }

        case CIMInputControllerSpecialKeyCode.capsLockFlagsChanged.rawValue:
            guard configuration.enableCapslockToToggleInputMode else {
                return CIMInputTextProcessResult.processed
            }

            self.ioConnect.setCapsLockLed(false)
            return CIMInputTextProcessResult.processed
        default:
            let inputKey = (UInt(keyCode), inputModifier)
            if let shortcutKey = configuration.inputModeExchangeKey, shortcutKey == inputKey {
                need_exchange = true
            }
    //        else if (self.delegate == self->hangulComposer && inputModifier == CIMSharedConfiguration->inputModeEnglishKeyModifier && keyCode == CIMSharedConfiguration->inputModeEnglishKeyCode) {
    //            dlog(DEBUG_SHORTCUT, @"**** Layout exchange by change to english shortcut ****");
    //            need_exchange = YES;
    //        }
    //        else if (self.delegate == self->romanComposer && inputModifier == CIMSharedConfiguration->inputModeKoreanKeyModifier && keyCode == CIMSharedConfiguration->inputModeKoreanKeyCode) {
    //            dlog(DEBUG_SHORTCUT, @"**** Layout exchange by change to korean shortcut ****");
    //            need_exchange = YES;
    //        }
            if let shortcutKey = configuration.inputModeHanjaKey, shortcutKey == inputKey {
                delegatedComposer = hanjaComposer
            }
    //        if (inputModifier, keyCode) == configuration.inputModeEmoticonKey {
    //            delegatedComposer = emoticonComposer
    //        }
    //    }
        }
        
        if need_exchange {
            // 한영전환을 위해 현재 입력 중인 문자 합성 취소
            self.delegate.cancelComposition()
            if self.delegate === romanComposer {
                var lastHangulInputMode = GureumConfiguration.shared().lastHangulInputMode
                if lastHangulInputMode == nil {
                    lastHangulInputMode = GureumInputSourceIdentifier.han2
                }
                (sender as AnyObject).selectMode(lastHangulInputMode)
            } else {
                (sender as AnyObject).selectMode(GureumInputSourceIdentifier.qwerty)
            }
            return CIMInputTextProcessResult.processed
        }
        
        if self.delegate === hanjaComposer {
            if !hanjaComposer.mode && hanjaComposer.composedString.count == 0 && hanjaComposer.commitString.count == 0 {
                // 한자 입력이 완료되었고 한자 모드도 아님
                self.delegate = hangulComposer
            }
        }
        
        if self.delegate === emoticonComposer {
            if !emoticonComposer.mode {
                self.emoticonComposer.mode = true
                self.delegate = romanComposer
            }
        }

        if delegatedComposer === hanjaComposer {
            // 한글 입력 상태에서 한자 및 이모티콘 입력기로 전환
            if self.delegate === hangulComposer {
                // 현재 조합 중 여부에 따라 한자 모드 여부를 결정
                let isComposing = hangulComposer.composedString.count > 0
                hanjaComposer.mode = !isComposing // 조합 중이 아니면 1회만 사전을 띄운다
                self.delegate = hanjaComposer
                self.delegate.composerSelected!(self)
                hanjaComposer.update(fromController: controller)
                return CIMInputTextProcessResult.processed
            }
            // 영어 입력 상태에서 이모티콘 입력기로 전환
            if self.delegate === romanComposer {
                emoticonComposer.delegate = self.delegate
                self.delegate = emoticonComposer
                emoticonComposer.update(fromController: controller)
                return CIMInputTextProcessResult.processed
            }
            // Vi-mode: esc로 로마자 키보드로 전환
            if GureumConfiguration.shared().romanModeByEscapeKey && (keyCode == kVK_Escape || false) {
                self.delegate.cancelComposition()
                (sender as AnyObject).selectMode(GureumInputSourceIdentifier.qwerty)
                return CIMInputTextProcessResult.notProcessedAndNeedsCommit
            }
        }
        
        // 특정 애플리케이션에서 커맨드/옵션/컨트롤 키 입력을 선점하지 못하는 문제를 회피한다
        if flags.contains(.command) || flags.contains(.option) || flags.contains(.control) {
            return CIMInputTextProcessResult.notProcessedAndNeedsCommit
        }
        
        return CIMInputTextProcessResult.notProcessed
    }
}
