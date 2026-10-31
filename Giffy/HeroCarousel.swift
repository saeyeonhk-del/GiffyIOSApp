import SwiftUI

private struct HeroSlide {
    let eyebrow: String
    let title: String
    let description: String
    let button: String
    let image: String
    static let all = [
        HeroSlide(eyebrow: "A SMALL, THOUGHTFUL GIFT", title: "Send a little\nsomething.", description: "Coffee, cake and good things from places they'll love — picked, written, and sent in minutes.", button: "Find a gift", image: "hero0"),
        HeroSlide(eyebrow: "FOR THEIR BIRTHDAY", title: "Make their birthday\na little sweeter.", description: "Send them a coffee, cake, or little treat they'll actually enjoy.", button: "Birthday gifts", image: "hero1"),
        HeroSlide(eyebrow: "A LITTLE CLOSER", title: "You don't have to be\nthere to make their day.", description: "Send a coffee, cake or little treat in just a few clicks.", button: "Send a little something", image: "hero2"),
        HeroSlide(eyebrow: "HOW IT WORKS", title: "A thoughtful gift in three\nsimple steps.", description: "From “this made me think of you” to their phone in minutes.", button: "Find a gift", image: "hero3")
    ]
}
struct HeroCarousel: View {
    let explore: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var index = 0
    @State private var paused = false
    private var slide: HeroSlide { HeroSlide.all[index] }
    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            ZStack(alignment: .topLeading) {
                Image(slide.image).resizable().scaledToFill().frame(width: proxy.size.width, height: height).clipped()
                LinearGradient(stops: [.init(color: .black.opacity(0.82), location: 0), .init(color: .black.opacity(0.68), location: 0.2), .init(color: .black.opacity(0.30), location: 0.45), .init(color: .clear, location: 1)], startPoint: index == 3 ? .trailing : .leading, endPoint: index == 3 ? .leading : .trailing)
                VStack(alignment: .leading, spacing: 8) {
                    Text(slide.eyebrow).font(Brand.body(8, .medium)).tracking(2.2).foregroundStyle(.white.opacity(0.75))
                    Text(slide.title).font(Brand.serif(18)).foregroundStyle(Color(hex: 0xFFFDF8)).fixedSize(horizontal: false, vertical: true)
                    Text(slide.description).font(Brand.body(10)).foregroundStyle(.white.opacity(0.8)).fixedSize(horizontal: false, vertical: true)
                    if index == 3 {
                        ForEach(Array(["Choose a gift", "Pay online", "Send the gift"].enumerated()), id: \.offset) { n, title in
                            HStack { Text("0\(n+1)").foregroundStyle(Brand.orange); Text(title).foregroundStyle(.white) }.font(Brand.body(8, .semibold))
                        }
                    } else if index == 1 {
                        NavigationLink { SearchView(initialQuery: "", initialCategory: "Dessert") } label: { cta }.buttonStyle(.plain)
                    } else { Button(action: explore) { cta }.buttonStyle(.plain) }
                }.frame(maxWidth: index == 3 ? proxy.size.width * 0.59 : proxy.size.width * 0.75, alignment: .leading).padding(.leading, index == 3 ? proxy.size.width * 0.36 : 24).padding(.top, 16)
                HStack(spacing: 8) {
                    Button { change(-1) } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Previous slide")
                    ForEach(0..<4, id: \.self) { n in Button { index = n; paused = true } label: { Capsule().fill(n == index ? .white : .white.opacity(0.4)).frame(width: n == index ? 18 : 5, height: 5).padding(.vertical, 8) }.accessibilityLabel("Go to slide \(n+1)") }
                    Button { change(1) } label: { Image(systemName: "chevron.right") }.accessibilityLabel("Next slide")
                    Spacer()
                    Button { paused.toggle() } label: { Image(systemName: paused ? "play.fill" : "pause.fill") }.accessibilityLabel(paused ? "Play slides" : "Pause slides")
                }.font(.system(size: 9)).foregroundStyle(.white).padding(.horizontal, 24).padding(.bottom, 8).frame(maxHeight: .infinity, alignment: .bottom)
            }.clipShape(RoundedRectangle(cornerRadius: 10))
        }.frame(height: 220)
            .task(id: scenePhase) {
                // Avoid overlapping implicit Core Animation transitions on newer iOS.
                // Auto-advance only while active; user controls pause it, Reduce Motion disables it.
                guard scenePhase == .active else { return }
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .milliseconds(5500)) } catch { return }
                    if !paused && !reduceMotion { index = (index + 1) % 4 }
                }
            }
    }
    private var cta: some View { HStack(spacing: 4) { Text(slide.button); Image(systemName: "arrow.right") }.font(Brand.body(11, .semibold)).foregroundStyle(.white).padding(.horizontal, 12).frame(height: 34).background(Brand.orange, in: Capsule()) }
    private func change(_ step: Int) { index = (index + step + 4) % 4; paused = true }
}
