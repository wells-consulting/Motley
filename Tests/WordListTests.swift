//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

@testable import Motley
import Testing

struct WordListTests {

    @Test func randomCodeHasTheRequestedWords() {
        for count in [1, 2, 4, 5] {
            let words = WordList.randomCode(words: count).split(separator: " ")

            #expect(words.count == count)
        }
    }

    @Test func randomCodeAlternatesTheLists() {
        let words = WordList.randomCode(words: 6).split(separator: " ").map(String.init)

        for (index, word) in words.enumerated() where index.isMultiple(of: 2) {
            #expect(WordList.adjectives.contains(word))
        }

        for (index, word) in words.enumerated() where !index.isMultiple(of: 2) {
            #expect(WordList.nouns.contains(word))
        }
    }

    @Test func randomCodeOfNothingIsEmpty() {
        #expect(WordList.randomCode(words: 0).isEmpty)
        #expect(WordList.randomCode(words: -1).isEmpty)
    }

    @Test func listsHaveNoDuplicates() {
        #expect(Set(WordList.adjectives).count == WordList.adjectives.count)
        #expect(Set(WordList.nouns).count == WordList.nouns.count)
    }
}
