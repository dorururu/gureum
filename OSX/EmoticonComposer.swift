//
//  EmoticonComposer.swift
//  OSX
//
//  Created by Jim Jeon on 30/08/2018.
//  Copyright © 2018 youknowone.org. All rights reserved.
//

import Hangul

let DEBUG_EMOTICON = true

class EmoticonComposer: CIMComposer {
    static let emoticonTable: HGHanjaTable = HGHanjaTable(contentOfFile: Bundle.main.path(forResource: "emoji", ofType: "txt", inDirectory: "hanja")!)

    var _candidates: [String]?
    var _bufferedString: String = ""
    var _composedString: String = ""
    var _commitString: String = ""
    var mode: Bool = false

    var _selectedCandidate: NSAttributedString? = nil

    var romanComposer: CIMComposerDelegate {
        return self.delegate
    }

    override var candidates: [String]? {
        return _candidates
    }

    override var composedString: String {
        return _composedString
    }

    override var commitString: String {
        return _commitString
    }

    override var originalString: String {
        return _bufferedString
    }

    override func dequeueCommitString() -> String {
        let result = self._commitString
        if !result.isEmpty {
            self._bufferedString = ""
            self._commitString = ""
        }
        return result
    }

    override func cancelComposition() {
        self.romanComposer.cancelComposition()
        self.romanComposer.dequeueCommitString()
        self._commitString.append(self._composedString)
        self._bufferedString = ""
        self._composedString = ""
    }

    override func clearContext() {
        self._commitString = ""
    }

    override var hasCandidates: Bool {
        guard let candidates = self._candidates else {
            return false
        }
        return candidates.count > 0 ? true : false
    }

    override func candidateSelected(_ candidateString: NSAttributedString) {
        dlog(DEBUG_EMOTICON, "DEBUG 1, [candidateSelected] MSG: function called")
        let value: String = candidateString.string.components(separatedBy: ":")[0]
        dlog(DEBUG_EMOTICON, "DEBUG 2, [candidateSelected] MSG: value == %@", value)
        self._bufferedString = ""
        self._composedString = ""
        self._commitString = value
        self.romanComposer.cancelComposition()
        self.romanComposer.dequeueCommitString()
    }

    override func candidateSelectionChanged(_ candidateString: NSAttributedString) {
        if candidateString.length == 0 {
            self._selectedCandidate = nil
        } else {
            let value: String = candidateString.string.components(separatedBy: ":")[0]
            self._selectedCandidate = NSAttributedString(string: value)
        }
    }

    func updateEmoticonCandidates() {
        // Step 1: Get string from romanComposer
        let x: String = self.romanComposer.dequeueCommitString()
        // Step 2: Show the string
        self._bufferedString.append(x)
        self._bufferedString.append(self.romanComposer.composedString)
        let originalString: String = self._bufferedString
        self._composedString = originalString
        let keyword: String = originalString

        dlog(DEBUG_EMOTICON, "DEBUG 1, [updateEmoticonCandidates] MSG: %@", originalString)
        if keyword.count == 0 {
            self._candidates = []
        } else {
            self._candidates = []
            for table: HGHanjaTable in [EmoticonComposer.emoticonTable] {
                dlog(DEBUG_EMOTICON, "DEBUG 3, [updateEmoticonCandidates] MSG: before hanjasByPrefixSearching")
                dlog(DEBUG_EMOTICON, "DEBUG 4, [updateEmoticonCandidates] MSG: [keyword: %@]", keyword)
                dlog(DEBUG_EMOTICON, "DEBUG 14, [updateEmoticonCandidates] MSG: %@", EmoticonComposer.emoticonTable.debugDescription)
                let list: HGHanjaList = table.hanjas(byPrefixSearching: keyword) ?? HGHanjaList()
                dlog(DEBUG_EMOTICON, "DEBUG 5, [updateEmoticonCandidates] MSG: after hanjasByPrefixSearching")

                dlog(DEBUG_EMOTICON, "DEBUG 9, [updateEmoticonCandidates] MSG: count is %d", list.count)
                if list.count > 0 {
                    for idx in 0...list.count-1 {
                        let emoticon = list.hanja(at: idx)
                        if emoticon == nil {
                            dlog(DEBUG_EMOTICON, "DEBUG 7, [updateEmoticonCandidates] MSG: hanja is nil!")
                        }
                        dlog(DEBUG_EMOTICON, "DEBUG 6, [updateEmoticonCandidates] MSG: %@ %@ %@", list.hanja(at: idx).comment, list.hanja(at: idx).key, list.hanja(at: idx).value)
                        if self._candidates == nil {
                            self._candidates = []
                        }
                        self._candidates!.append(emoticon.value as String + ": " + emoticon.comment as String)
                    }
                }
            }
        }
        dlog(DEBUG_EMOTICON, "DEBUG 2, [updateEmoticonCandidates] MSG: %@", self.candidates ?? [])
    }

    func update(fromController controller: CIMInputController) {
        dlog(DEBUG_EMOTICON, "DEBUG 1, [update] MSG: function called")
        let markedRange: NSRange = controller.client().markedRange()
        let selectedRange: NSRange = controller.client().selectedRange()

        let isInvalidMarkedRange: Bool = markedRange.length == 0 || markedRange.length == NSNotFound

        dlog(DEBUG_EMOTICON, "DEBUG 2, [update] MSG: DEBUG POINT 1")
        if isInvalidMarkedRange && selectedRange.length > 0 {
            let selectedString: String = controller.client().attributedSubstring(from: selectedRange).string

            controller.client().setMarkedText(selectedString, selectionRange: selectedRange, replacementRange: selectedRange)

            self._bufferedString = selectedString
            dlog(DEBUG_EMOTICON, "DEBUG 3, [update] MSG: %@", self._bufferedString)

            self.mode = false
        }

        self.updateEmoticonCandidates()
    }

    override func inputController(_ controller: CIMInputController, inputText string: String!, key keyCode: Int, modifiers flags: NSEvent.ModifierFlags, client sender: Any) -> CIMInputTextProcessResult {
        dlog(DEBUG_EMOTICON, "DEBUG 1, [inputController] MSG: %@, [[%d]]", string, keyCode)
        var result: CIMInputTextProcessResult = self.delegate.inputController(controller, inputText: string, key: keyCode, modifiers: flags, client: sender)

        switch keyCode {
        // BackSpace
        case 51:
            if result == CIMInputTextProcessResult.notProcessed {
                if self.originalString.count > 0 {
                    dlog(DEBUG_EMOTICON, "DEBUG 4, [inputController] MSG: buffer (%@)", self._bufferedString)
                    dlog(DEBUG_EMOTICON, "DEBUG 7, [inputController] MSG: length is %d", self._bufferedString.count)
                    let lastIndex: String.Index = self._bufferedString.index(before: self._bufferedString.endIndex)
                    self._bufferedString.remove(at: lastIndex)
                    dlog(DEBUG_EMOTICON, "DEBUG 5, [inputController] MSG: after deletion, buffer (%@)", self._bufferedString)
                    self._composedString = self.originalString
                    result = CIMInputTextProcessResult.processed
                } else {
                    self.mode = false
                }
            }
            break
        // Space
        case 49:
            self.romanComposer.cancelComposition()
            self._bufferedString.append(self.romanComposer.dequeueCommitString())
            if self._bufferedString.count > 0 {
                self._bufferedString.append(" ")
                result = CIMInputTextProcessResult.processed
            } else {
                result = CIMInputTextProcessResult.notProcessedAndNeedsCommit
            }
            break
        // ESC
        case 53:
            self.mode = false
            // step 1. get all composing characters
            self.romanComposer.cancelComposition()
            self._bufferedString.append(self.romanComposer.dequeueCommitString())
            // step 2. commit all
            self._composedString = self.originalString
            self.cancelComposition()
            // step 3. cancel candidates
            self._candidates = nil
            return CIMInputTextProcessResult.notProcessedAndNeedsCommit
        // Enter
        case 36:
            self.candidateSelected(self._selectedCandidate ?? NSAttributedString(string: self.composedString))
            break
        default:
            break
        }

        dlog(DEBUG_EMOTICON, "DEBUG 2, [inputController] MSG: %@", string)
        self.updateEmoticonCandidates()

        dlog(DEBUG_EMOTICON, "DEBUG 3, [inputController] MSG: %@", string)

        if result == CIMInputTextProcessResult.notProcessedAndNeedsCommit {
            self.cancelComposition()
            return result
        }
        if self.commitString.count == 0 {
            return CIMInputTextProcessResult.processed
        } else {
            return CIMInputTextProcessResult.notProcessedAndNeedsCommit
        }
    }
}