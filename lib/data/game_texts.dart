// lib/data/game_texts.dart

const String kGameDescription = r'''
📜 Descripción del Juego

El juego es una competencia de drones diseñada para desafiar las habilidades de los jugadores en un entorno de combate dinámico y competitivo.
Los participantes controlan sus drones con precisión, estrategia y rapidez para eliminar a sus oponentes y sobrevivir en un campo de batalla
que puede incluir obstáculos. La meta es convertirse en el último jugador en pie o acumular la mayor cantidad de puntos, según el modo seleccionado.

────────────────────────────────────────────────────────────────────

🕹 Modalidades Disponibles

1. Simulación (Estrategia y Personalización)
   • Número de jugadores: de 2 a 4
   • Modos: Todos contra todos (último en pie), 2 vs 2 (respawn habilitado)
   • Duración aproximada: 5 - 10 minutos

2. Dron Lab (Competencia en el Mundo Real)
   • Modo: Todos contra todos
   • Tiempo límite: 8 minutos
   • Respawn: NO disponible (eliminación definitiva)

────────────────────────────────────────────────────────────────────

🚀 Dinámica y Armamento

• Bala pequeña y rápida → alta cadencia, velocidad ~800 m/s  
• Bala mediana             → equilibrio de daño/velocidad ~500 m/s  
• Bala grande y lenta      → alto daño, velocidad ~100 m/s  

────────────────────────────────────────────────────────────────────

🎯 Condiciones de Victoria

• 10 puntos por cada enemigo eliminado  
•  1 punto por cada obstáculo destruido  

Al terminar, se muestra un resumen estadístico con:
- Eliminaciones  
- Disparos realizados  
- Obstáculos destruidos  
- Puntuación total

────────────────────────────────────────────────────────────────────

“Una experiencia envolvente donde la estrategia y la habilidad se combinan
para crear enfrentamientos llenos de emoción.”
''';

const String kGameManual = r'''
📖 Manual del Juego

────────────────────────────────────────────────────────────────────

OBJETIVO DEL JUEGO

Eliminar a los oponentes y ser el último jugador en pie, o bien acumular
la mayor cantidad de puntos antes de que termine el tiempo de partida.

────────────────────────────────────────────────────────────────────

CONFIGURACIÓN GENERAL

• Simulación: 5 - 10 minutos (respawn cada 15 seg en modo 2v2)  
• Dron Lab:   8 minutos, sin respawn  
• Jugadores:  de 2 a 4 participantes

────────────────────────────────────────────────────────────────────

MODOS DE JUEGO

Simulación  
• Entorno virtual  
• Modalidades: Todos vs Todos / 2 vs 2  

Dron Lab  
• Entorno real  
• Modalidad: Todos vs Todos  
• Sin respawn

────────────────────────────────────────────────────────────────────

MECÁNICA DE DISPARO

Proyectil             | Cadencia   | Recarga  | Velocidad  
----------------------|------------|----------|-----------  
Bala pequeña y rápida | 1 disparo cada 0,5 s | 0,5 s | 800 m/s  
Bala mediana          | 1 disparo cada 1 s   | 1 s   | 500 m/s  
Bala grande y lenta   | 1 disparo cada 2 s   | 1 s   | 100 m/s  

────────────────────────────────────────────────────────────────────

OBSTÁCULOS  

Estructuras destructibles (1 m×1 m×5 m) que sirven de cobertura y otorgan
1 punto extra al destruirlas.

────────────────────────────────────────────────────────────────────

CONDICIONES DE VICTORIA  

• Simulación → quien más puntos obtenga  
• Dron Lab   → quien más puntos acumule al finalizar el tiempo  

Puntuación  
- 10 puntos/eliminación  
-  1 punto/obstáculo destruido  
- Empates permitidos

────────────────────────────────────────────────────────────────────

FIN DE LA PARTIDA  

Al concluir, se despliega una tabla de resultados con  
- Eliminaciones  
- Disparos realizados  
- Obstáculos destruidos  
- Puntos totales  

¡Buena suerte y que gane el mejor piloto!
''';
