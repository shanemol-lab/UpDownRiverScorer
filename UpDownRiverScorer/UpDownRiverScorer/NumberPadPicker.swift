//
//  NumberPadPicker.swift
//  UpDownRiverScorer
//
//  Created by Shane Moller on 02/01/2026.
//
import SwiftUI

struct NumberPadPicker: View {
    let title: String
    let range: ClosedRange<Int>
    @Binding var value: Int
    let onDone: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    private var numbers: [Int] { Array(range) }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(numbers, id: \.self) { n in
                        Button {
                            value = n
                        } label: {
                            Text("\(n)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, minHeight: 56)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(value == n ? .accentColor : .gray)
                        .accessibilityLabel("Set to \(n)")
                    }
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone?()
                        dismiss()
                    }
                }
            }
        }
    }
}
