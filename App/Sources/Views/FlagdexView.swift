import FlyquizCore
import SwiftUI

struct FlagdexView: View {
    @Environment(AppModel.self) private var app
    @State private var region: Region?
    @State private var selected: Country?

    private var countries: [Country] {
        let list = region.map(Countries.inRegion) ?? Countries.all
        return list.sorted { $0.name < $1.name }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                regionPicker
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 10)], spacing: 10) {
                    ForEach(countries) { country in
                        FlagCell(country: country, stat: app.progress.flagStats[country.code]) {
                            selected = country
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Flagdex")
        .toolbarBackground(Theme.backgroundTop, for: .navigationBar)
        .sheet(item: $selected) { country in
            FlagDetail(country: country, stat: app.progress.flagStats[country.code])
                .presentationDetents([.height(340)])
                .presentationBackground(Theme.backgroundBottom)
        }
    }

    private var regionPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(title: "All", value: nil)
                ForEach(Region.allCases, id: \.self) { chip(title: $0.displayName, value: $0) }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func chip(title: String, value: Region?) -> some View {
        let codes = value.map { Countries.inRegion($0).map(\.code) } ?? Countries.all.map(\.code)
        let mastered = codes.filter { app.progress.flagStats[$0]?.isMastered == true }.count
        let isOn = region == value
        return Button {
            Haptics.shared.tap()
            withAnimation(Theme.snappy) { region = value }
        } label: {
            Text("\(title) \(mastered)/\(codes.count)")
                .font(.rounded(14, .bold))
                .padding(.horizontal, 12)
                .frame(height: 34)
                .foregroundStyle(isOn ? Color.black : Color.white)
                .background(isOn ? Color.white : Theme.card, in: Capsule())
        }
        .buttonStyle(PressableStyle())
    }
}

struct FlagCell: View {
    let country: Country
    let stat: FlagStat?
    let action: () -> Void

    private var seen: Bool { (stat?.seen ?? 0) > 0 }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(country.flag)
                    .font(.system(size: 40))
                    .grayscale(seen ? 0 : 1)
                    .opacity(seen ? 1 : 0.25)
                Text(seen ? country.name : "???")
                    .font(.rounded(10, .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(seen ? .white : Theme.muted)
                MasteryDots(box: stat?.box ?? 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .card(radius: 16, fill: stat?.isMastered == true ? Theme.gold.opacity(0.16) : Theme.card)
        }
        .buttonStyle(PressableStyle())
        .disabled(!seen)
    }
}

struct MasteryDots: View {
    let box: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<FlagStat.masteredBox, id: \.self) { i in
                Circle()
                    .fill(i < box ? (box >= FlagStat.masteredBox ? Theme.gold : Theme.correct) : Color.white.opacity(0.15))
                    .frame(width: 5, height: 5)
            }
        }
    }
}

struct FlagDetail: View {
    let country: Country
    let stat: FlagStat?

    var body: some View {
        VStack(spacing: 14) {
            Text(country.flag).font(.system(size: 110))
            Text(country.name).font(.rounded(28, .heavy))
            Text(country.region.displayName).font(.rounded(15, .semibold)).foregroundStyle(Theme.muted)
            if let stat {
                HStack(spacing: 10) {
                    StatTile(value: "\(stat.correct)/\(stat.seen)", label: "Correct", tint: Theme.correct)
                    StatTile(value: stat.isMastered ? "★" : "\(stat.box)/\(FlagStat.masteredBox)",
                             label: stat.isMastered ? "Mastered" : "Mastery", tint: Theme.gold)
                }
                .padding(.horizontal, 24)
            }
        }
        .foregroundStyle(.white)
        .padding(.top, 24)
    }
}
