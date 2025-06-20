// main.js
import "./game.js";           // Initializes Kaboom
import "./scenes/menu.js";    // Import all your scenes

import k from "./game.js"; // Get scene switching function

k.go("menu"); // Start the game from the menu
