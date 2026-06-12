import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var allStories: [Story] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Banner Cinematográfico de Historia Principal
                if let mainStory = allStories.first {
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(Theme.darkGray)
                            .frame(height: 500)
                            .overlay(
                                ZStack {
                                    if let uiImage = MediaImageLoader.loadImage(named: mainStory.coverImage) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 500)
                                            .clipped()
                                    } else {
                                        Theme.mainGradient
                                            .overlay(
                                                Image(systemName: "book.fill")
                                                    .font(.system(size: 80))
                                                    .foregroundColor(.white.opacity(0.1))
                                            )
                                    }
                                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                                }
                            )
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("HISTORIA PRINCIPAL")
                                .font(.caption).bold().padding(6).background(Theme.accentRed).cornerRadius(4)
                                .foregroundColor(.white)
                            
                            Text(mainStory.title)
                                .font(.system(size: 44, weight: .black))
                                .foregroundColor(.white)
                            
                            Text(mainStory.description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            NavigationLink(destination: NarrativeView(viewModel: viewModel).onAppear {
                                viewModel.startStory(mainStory)
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("COMENZAR HISTORIA")
                                }
                                .font(.headline)
                                .padding()
                                .frame(width: 250)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            }
                        }
                        .padding(30)
                    }
                    .ignoresSafeArea(edges: .top)
                }
                
                // Sección de Exploración de Historias
                VStack(alignment: .leading, spacing: 15) {
                    Text("MÁS HISTORIAS")
                        .font(.headline).tracking(3).padding(.horizontal)
                        .foregroundColor(.white)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(allStories) { story in
                                NavigationLink(destination: NarrativeView(viewModel: viewModel).onAppear {
                                    viewModel.startStory(story)
                                }) {
                                    StoryCardView(story: story)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 50)
        }
        .onAppear {
            self.allStories = StoryService.loadAllStories()
        }
    }
}

struct StoryCardView: View {
    let story: Story
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let uiImage = MediaImageLoader.loadImage(named: story.coverImage) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 180, height: 260)
                        .cornerRadius(15)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Theme.darkGray)
                        .frame(width: 180, height: 260)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.3))
                                Text(story.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                                    .foregroundColor(.white)
                            }
                        )
                }
            }
            
            Text(story.title)
                .font(.caption).bold()
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text("\(story.genre) • \(story.duration)")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(width: 180)
    }
}
