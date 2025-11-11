//
//  HTMLRender.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/30/25.
//

import UIKit
import SwiftUI

struct HTMLTextView: UIViewRepresentable {
    let html: String
    let font: UIFont
    let textColor: UIColor
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        
        // Enable text wrapping
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0 // Unlimited lines
        textView.textContainer.widthTracksTextView = true
        
        // Disable scrolling and enable wrapping
        textView.isScrollEnabled = false
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        DispatchQueue.main.async {
            if let data = html.data(using: .utf8),
               let attributedString = try? NSAttributedString(
                    data: data,
                    options: [
                        .documentType: NSAttributedString.DocumentType.html,
                        .characterEncoding: String.Encoding.utf8.rawValue
                    ],
                    documentAttributes: nil
               ) {
                let mutableString = NSMutableAttributedString(attributedString: attributedString)
                mutableString.addAttributes([
                    .font: font,
                    .foregroundColor: textColor
                ], range: NSRange(location: 0, length: mutableString.length))
                
                uiView.attributedText = mutableString
            }
        }
    }
    
//    func updateUIView(_ uiView: UITextView, context: Context) {
//        if let data = html.data(using: .utf8),
//           let attributedString = try? NSAttributedString(
//                data: data,
//                options: [
//                    .documentType: NSAttributedString.DocumentType.html,
//                    .characterEncoding: String.Encoding.utf8.rawValue
//                ],
//                documentAttributes: nil
//           ) {
//            let mutableString = NSMutableAttributedString(attributedString: attributedString)
//            mutableString.addAttributes([
//                .font: font,
//                .foregroundColor: textColor
//            ], range: NSRange(location: 0, length: mutableString.length))
//            
//            uiView.attributedText = mutableString
//        }
//    }
}
