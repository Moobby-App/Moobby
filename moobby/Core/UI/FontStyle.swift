//
//  FontStyle.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/05/26.
//

import SwiftUI

/// Namespace for the app's shared styling.
enum DesignSystem {}

extension DesignSystem {

    /// Text styles applied with `typography(_:)`. Each builds on a Dynamic Type font, so text still scales.
    enum Typography {
        /// Bold title with extra line spacing.
        case title
        /// Body text with relaxed line spacing.
        case body
        /// Headline weight, slightly tracked out, for prominent labels.
        case button
        /// Small secondary text.
        case caption
    }
}

fileprivate struct TypographyModifier: ViewModifier {

    let style: DesignSystem.Typography

    func body(content: Content) -> some View {

        switch style {

        case .title:
            content
                .font(.title.bold())
                .lineSpacing(6)

        case .body:
            content
                .font(.body)
                .lineSpacing(4)

        case .button:
            content
                .font(.headline)
                .kerning(1.2)

        case .caption:
            content
                .font(.caption)
                .kerning(0.5)
        }
    }
}

extension View {

    /// Styles text with one of the shared ``DesignSystem/Typography`` styles.
    func typography(
        _ typography: DesignSystem.Typography
    ) -> some View {

        self.modifier(
            TypographyModifier(style: typography)
        )
    }
}
