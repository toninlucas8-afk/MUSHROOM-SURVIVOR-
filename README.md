# Mushroom Survivor 🍄🌈

Gioco in stile *Vampire Survivors* a tema funghi, con grafica psichedelica. Funziona direttamente nel browser: niente da installare.

## Come si gioca

1. Scarica il repository (o il file ZIP da GitHub: **Code → Download ZIP**).
2. Apri `index.html` con un doppio clic (Chrome, Firefox, Edge o Safari).
3. Premi **GIOCA**.

| Tasto | Azione |
| --- | --- |
| WASD / Frecce | Muoversi (su telefono: trascina il dito) |
| 1 · 2 · 3 | Scegliere il potenziamento al level up |
| P / Esc | Pausa |
| M | Musica on/off |

Le armi sparano da sole. Raccogli i cristalli lasciati dai nemici per salire di livello e scegliere nuove armi o poteri. Sopravvivi più a lungo che puoi.

## Contenuto del prototipo

- **5 armi** (fino al livello 6): Spore Lisergiche, Anello di Funghetti, Aura Cosmica, Esplosione Prismatica, Micelio Elettrico.
- **7 poteri passivi** (fino al livello 5): vita, velocità, raccolta, danno, ricarica, rigenerazione, area.
- **Nemici**: Lumaca Acida, Zanzara Ronzante, Bruco Ipnotico, Occhio Fluttuante, e il boss **Re della Muffa** ogni 3 minuti. Ogni minuto arriva uno sciame di zanzare che ti circonda.
- Oggetti: cuore (cura) e calamita (raccoglie tutti i cristalli).
- Musica e suoni generati dal browser, record salvato in locale.

## File

- `index.html` — pagina e schermate (menu, level up, pausa, game over)
- `style.css` — stile delle schermate
- `game.js` — tutto il gioco (disegnato a codice su canvas, nessuna immagine esterna)
