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
                            
                            NavigationLink(destination: StoryDetailView(story: mainStory, viewModel: viewModel)) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("VER DETALLES")
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
                                NavigationLink(destination: StoryDetailView(story: story, viewModel: viewModel)) {
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

// MARK: - Story Detail View
struct StoryDetailView: View {
    let story: Story
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var progressManager = ProgressManager.shared
    
    var progress: StoryProgress {
        progressManager.getProgress(for: story.title)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Header Banner
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(Theme.darkGray)
                        .frame(height: 380)
                        .overlay(
                            ZStack {
                                if let uiImage = MediaImageLoader.loadImage(named: story.coverImage) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 380)
                                        .clipped()
                                } else {
                                    Theme.mainGradient
                                        .overlay(
                                            Image(systemName: "book.fill")
                                                .font(.system(size: 70))
                                                .foregroundColor(.white.opacity(0.08))
                                        )
                                }
                                LinearGradient(colors: [.clear, Theme.black], startPoint: .top, endPoint: .bottom)
                            }
                        )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(story.genre.uppercased())
                            .font(.caption2).bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.accentRed)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        
                        Text(story.title)
                            .font(.system(size: 38, weight: .black))
                            .foregroundColor(.white)
                        
                        Text("Duración estimada: \(story.duration)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(24)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    // Description
                    Text(story.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(5)
                        .padding(.horizontal)
                    
                    // Progress card
                    let percentage = story.completionPercentage(progress: progress)
                    let unlockedCount = progress.unlockedEndingIDs.count
                    let totalCount = story.allEndings.count
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("PROGRESO DE LA HISTORIA")
                                .font(.caption).bold()
                                .foregroundColor(.gray)
                                .tracking(2)
                            
                            Spacer()
                            
                            Text("\(percentage)%")
                                .font(.headline).bold()
                                .foregroundColor(Theme.accentYellow)
                        }
                        
                        // Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.accentYellow)
                                    .frame(width: geo.size.width * CGFloat(Double(percentage) / 100.0))
                            }
                        }
                        .frame(height: 8)
                        
                        Text("Has descubierto \(unlockedCount) de \(totalCount) finales posibles.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Main Action Play Button
                    NavigationLink(destination: NarrativeView(viewModel: viewModel).onAppear {
                        viewModel.startStory(story)
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text(progress.visitedSceneIDs.isEmpty ? "COMENZAR AVENTURA" : "CONTINUAR AVENTURA")
                        }
                        .font(.headline).bold()
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                        )
                        .shadow(color: .white.opacity(0.2), radius: 8)
                    }
                    .padding(.horizontal)
                    
                    // Auxiliary navigation buttons
                    HStack(spacing: 16) {
                        NavigationLink(destination: DecisionTreeView(story: story)) {
                            HStack {
                                Image(systemName: "square.grid.3x1.folder.badge.plus")
                                Text("Decisiones")
                            }
                            .font(.subheadline).bold()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    .background(Color.white.opacity(0.03))
                            )
                        }
                        
                        NavigationLink(destination: EndingGalleryView(story: story)) {
                            HStack {
                                Image(systemName: "crown")
                                Text("Finales")
                            }
                            .font(.subheadline).bold()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    .background(Color.white.opacity(0.03))
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Theme.black.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Decision Tree View
struct DecisionTreeView: View {
    let story: Story
    @ObservedObject var progressManager = ProgressManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedScene: GameScene?
    @State private var showDetailSheet = false
    
    var progress: StoryProgress {
        progressManager.getProgress(for: story.title)
    }
    
    var body: some View {
        ZStack {
            Theme.mainGradient.ignoresSafeArea()
            
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                VStack(spacing: 40) {
                    Text("ÁRBOL DE DECISIONES")
                        .font(.headline).tracking(3)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    let levels = buildLevels()
                    ForEach(0..<levels.count, id: \.self) { levelIndex in
                        let nodes = levels[levelIndex]
                        
                        HStack(spacing: 30) {
                            ForEach(nodes) { node in
                                TreeNodeView(node: node, progress: progress) {
                                    if node.isVisited {
                                        selectedScene = node.scene
                                        showDetailSheet = true
                                    }
                                }
                            }
                        }
                        
                        // Connector indicators between levels
                        if levelIndex < levels.count - 1 {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
                .padding(40)
                .frame(minWidth: 600)
            }
        }
        .navigationTitle("Progreso: \(story.title)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDetailSheet) {
            if let scene = selectedScene {
                SceneDetailView(scene: scene, story: story, progress: progress)
            }
        }
    }
    
    struct LevelNode: Identifiable {
        let id: String
        let scene: GameScene
        let isVisited: Bool
    }
    
    func buildLevels() -> [[LevelNode]] {
        var levels: [[LevelNode]] = []
        var visited = Set<String>()
        
        guard let initial = story.scenes.first(where: { $0.id == story.initialSceneID }) else { return [] }
        
        var queue: [(scene: GameScene, depth: Int)] = [(initial, 0)]
        var tempLevels: [Int: [LevelNode]] = [:]
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            let scene = current.scene
            let depth = current.depth
            
            if visited.contains(scene.id) { continue }
            visited.insert(scene.id)
            
            let isVisited = progress.visitedSceneIDs.contains(scene.id)
            let node = LevelNode(id: scene.id, scene: scene, isVisited: isVisited)
            tempLevels[depth, default: []].append(node)
            
            for choice in scene.choices {
                if let next = story.scenes.first(where: { $0.id == choice.targetSceneID }) {
                    queue.append((next, depth + 1))
                }
            }
        }
        
        let sortedKeys = tempLevels.keys.sorted()
        for key in sortedKeys {
            if let levelNodes = tempLevels[key] {
                levels.append(levelNodes)
            }
        }
        
        return levels
    }
}

// MARK: - Tree Node View
struct TreeNodeView: View {
    let node: DecisionTreeView.LevelNode
    let progress: StoryProgress
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if node.scene.isEnding {
                    Image(systemName: node.isVisited ? "crown.fill" : "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(node.isVisited ? Theme.accentYellow : .gray)
                    
                    Text(node.isVisited ? node.scene.displayNameForEnding : "???")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(node.isVisited ? .white : .gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 110)
                } else {
                    Image(systemName: node.isVisited ? "book.fill" : "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(node.isVisited ? .blue : .gray)
                    
                    Text(node.isVisited ? (node.scene.characterName ?? "Escena") : "Bloqueado")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(node.isVisited ? .white : .gray.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
            .frame(width: 130, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(node.isVisited ? 0.08 : 0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                node.scene.isEnding
                                    ? (node.isVisited ? Theme.accentYellow.opacity(0.8) : Color.white.opacity(0.1))
                                    : (node.isVisited ? Color.blue.opacity(0.8) : Color.white.opacity(0.1)),
                                lineWidth: node.isVisited ? 2 : 1
                            )
                    )
                    .shadow(color: node.isVisited ? (node.scene.isEnding ? Theme.accentYellow.opacity(0.2) : Color.blue.opacity(0.2)) : .clear, radius: 6)
            )
        }
        .disabled(!node.isVisited)
    }
}

// MARK: - Scene Detail View
struct SceneDetailView: View {
    let scene: GameScene
    let story: Story
    let progress: StoryProgress
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.mainGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Background image if available
                        if let uiImage = MediaImageLoader.loadImage(named: scene.backgroundImage) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .cornerRadius(12)
                                .clipped()
                                .padding(.bottom, 10)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.darkGray)
                                .frame(height: 150)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.white.opacity(0.2))
                                        .font(.largeTitle)
                                )
                                .padding(.bottom, 10)
                        }
                        
                        if let charName = scene.characterName {
                            Text(charName.uppercased())
                                .font(.caption).bold()
                                .foregroundColor(Theme.accentYellow)
                                .tracking(3)
                        }
                        
                        Text(scene.dialogue)
                            .font(.body)
                            .foregroundColor(.white)
                            .lineSpacing(5)
                        
                        if !scene.choices.isEmpty {
                            Text("DECISIONES TOMADAS")
                                .font(.caption).bold()
                                .foregroundColor(.gray)
                                .tracking(2)
                                .padding(.top, 15)
                            
                            VStack(spacing: 10) {
                                ForEach(scene.choices) { choice in
                                    let choiceVisited = progress.visitedSceneIDs.contains(choice.targetSceneID)
                                    HStack {
                                        Text(choice.text)
                                            .font(.subheadline)
                                            .foregroundColor(choiceVisited ? .white : .gray.opacity(0.6))
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                        
                                        Image(systemName: choiceVisited ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(choiceVisited ? .green : .gray.opacity(0.3))
                                    }
                                    .padding()
                                    .background(Color.white.opacity(choiceVisited ? 0.05 : 0.02))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(choiceVisited ? Color.green.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(scene.isEnding ? "Final: \(scene.displayNameForEnding)" : "Detalle de Escena")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cerrar") {
                presentationMode.wrappedValue.dismiss()
            }.foregroundColor(.white))
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Ending Gallery View
struct EndingGalleryView: View {
    let story: Story
    @ObservedObject var progressManager = ProgressManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var progress: StoryProgress {
        progressManager.getProgress(for: story.title)
    }
    
    var body: some View {
        ZStack {
            Theme.mainGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    Text("GALERÍA DE FINALES")
                        .font(.system(size: 26, weight: .black))
                        .tracking(2)
                        .foregroundColor(.white)
                        .padding(.top, 25)
                        .padding(.horizontal)
                    
                    let endings = story.allEndings
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 20)], spacing: 25) {
                        ForEach(endings) { ending in
                            let isUnlocked = progress.unlockedEndingIDs.contains(ending.id)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                ZStack {
                                    if isUnlocked, let uiImage = MediaImageLoader.loadImage(named: ending.backgroundImage) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 120)
                                            .cornerRadius(12)
                                            .clipped()
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Theme.darkGray)
                                            .frame(height: 120)
                                            .overlay(
                                                Image(systemName: isUnlocked ? "crown.fill" : "lock.fill")
                                                    .foregroundColor(isUnlocked ? Theme.accentYellow : .gray.opacity(0.4))
                                                    .font(.title)
                                            )
                                    }
                                }
                                
                                Text(isUnlocked ? ending.displayNameForEnding : "???")
                                    .font(.headline)
                                    .foregroundColor(isUnlocked ? .white : .gray)
                                    .lineLimit(1)
                                
                                Text(isUnlocked ? ending.dialogue : "Continúa explorando la historia para desbloquear este final.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(12)
                            .background(Color.white.opacity(isUnlocked ? 0.05 : 0.02))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isUnlocked ? Theme.accentYellow.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
