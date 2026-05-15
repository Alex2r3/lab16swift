import Foundation


class StoryService {
    static func getElUltimoFaro() -> Story {
        let inicioID = UUID()
        let playaID = UUID()
        let bosqueID = UUID()
        let faroID = UUID()
        let finalID = UUID()
       
        // Escena 1: El Despertar
        let c1 = Choice(text: "Explorar la playa", targetSceneID: playaID, bravery: 5, humanity: 2)
        let c2 = Choice(text: "Buscar sobrevivientes", targetSceneID: bosqueID, trust: 10, humanity: 5)
        let c3 = Choice(text: "Ir hacia el faro", targetSceneID: faroID, timeLimit: 5.0, bravery: 15)
       
        let inicio = GameScene(
            id: inicioID,
            characterName: "Alex",
            dialogue: "Despierto con el sabor de la sal en mi boca. La tormenta ha pasado, pero el silencio es peor. A lo lejos, un faro emite una luz roja intermitente. ¿Qué debo hacer?",
            backgroundImage: "beach_start",
            choices: [c1, c2, c3]
        )
       
        // Escena 2: La Playa
        let playa = GameScene(
            id: playaID,
            characterName: "Valeria",
            dialogue: "Veo a una mujer junto a unos restos de madera. Se presenta como Valeria. Dice que el faro no es lo que parece.",
            backgroundImage: "beach_mist",
            choices: [
                Choice(text: "Confiar en Valeria", targetSceneID: faroID, trust: 15, humanity: 5),
                Choice(text: "Sospechar de sus motivos", targetSceneID: bosqueID, trust: -10, bravery: 5)
            ]
        )
       
        // Escena 3: El Bosque
        let bosque = GameScene(
            id: bosqueID,
            characterName: "Noah",
            dialogue: "¡No te acerques! Noah me apunta con un trozo de metal afilado. Cree que somos parte de un experimento.",
            backgroundImage: "dark_forest",
            choices: [
                Choice(text: "Cálmalo", targetSceneID: faroID, trust: 10, humanity: 15),
                Choice(text: "Desarmarlo", targetSceneID: faroID, bravery: 20)
            ]
        )
       
        // Escena 4: El Faro (Corregida)
        let faro = GameScene(
            id: faroID,
            characterName: "Elias",
            dialogue: "Elias está frente a una consola de bronce antigua. 'Alex, llegas justo a tiempo. Puedo apagarlo o usarlo para reescribir lo que pasó.'",
            backgroundImage: "lighthouse_interior",
            choices: [
                Choice(text: "Sacrificarse", targetSceneID: finalID, trust: 20, humanity: 30),
                Choice(text: "Usar la tecnología", targetSceneID: finalID, trust: -20, bravery: 20)
            ]
        )
       
        let finalScene = GameScene(
            id: finalID,
            dialogue: "El destino está sellado.",
            backgroundImage: "lighthouse_top",
            isEnding: true
        )


        return Story(
            id: UUID(),
            title: "El Último Faro",
            description: "Una isla que devora recuerdos.",
            coverImage: "faro_cover",
            initialSceneID: inicioID,
            scenes: [inicio, playa, bosque, faro, finalScene],
            genre: "Misterio",
            duration: "30 min"
        )
    }
}


