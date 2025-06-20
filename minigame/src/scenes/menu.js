import { Bar } from "../components/bar.js";
import { Food } from "../components/food.js";
import { Ground } from "../components/ground.js";
import { Pet } from "../components/pet.js";
import { Popup } from "../components/popup.js";
import config from "../config/config.js";
import k from "../game.js";
import getTimePeriod from "../helpers/getTime.js";

k.scene("menu", async () => {
  const DECAY_INTERVAL = 1800;
  const DECAY_AMOUNT = -1;

  function applyOfflineHPDecay(pet) {
  const lastCheck = parseInt(localStorage.getItem("last_check"));
  const now = Date.now();

  if (!lastCheck) {
    localStorage.setItem("last_check", now.toString());
    return;
  }

  const elapsedSeconds = (now - lastCheck) / 1000;
  const decayCount = Math.floor(elapsedSeconds / DECAY_INTERVAL);

  if (decayCount > 0) {
    pet.changeHP(DECAY_AMOUNT * decayCount);
    const newCheckTime = lastCheck + decayCount * DECAY_INTERVAL * 1000;
    localStorage.setItem("last_check", newCheckTime.toString());
  }
}


  let score = null;
  let expBar = null;

  window.setScore = function (newScore) {
    score = newScore;
    if (!expBar) {
      expBar = new Bar({
        id: 'exp-bar', label: 'EXP', initial: score, max: 100,
        isDynamic: true, color: 'blue', backgroundColor: '#222', container: document.body
      });
      expBar.setPosition(10, 40);
    } else {
      expBar.update(score);
    }
    const el = document.getElementById("scoreDisplay");
    if (el) el.innerText = `Score: ${score}`;
  };

  const time = getTimePeriod();
  await Promise.all([...Array(5)].map((_, i) => k.loadSprite(`bg${i + 1}`, `/backgrounds/${time}/${i + 1}.png`)));
  await Promise.all([
    k.loadSprite("ground", "/ground.png"),
    k.loadSprite("idle", "/sprites/idle.png"),
    k.loadSprite("drag", "/sprites/drag.png")
  ]);

  const bgSpeed = 5;
  const bgs = [];
  const speedMap = { 1: 0, 2: 1, 3: 2.5, 4: 4, 5: 1 };
  const yList = [0, 20, 0, 0, 50];
  const scaleList = [1, 0.85, 0.85, 0.85, 0.7];
  const numTiles = 4;
  const originalSpriteWidth = 576;

  for (let i = 1; i <= 5; i++) {
    const scale = scaleList[i - 1];
    const y = yList[i - 1];
    const scaledWidth = originalSpriteWidth * scale;
    const speedMultiplier = speedMap[i];
    for (let j = 0; j < numTiles; j++) {
      const bg = k.add([
        k.sprite(`bg${i}`), k.pos(j * scaledWidth, y), k.anchor("topleft"),
        k.scale(scale), k.z(i),
        { layerIndex: i, getScaledWidth: () => scaledWidth, speedMultiplier },
        ...(i === 1 ? [k.fixed()] : []), "bg"
      ]);
      bgs.push(bg);
    }
  }

  k.setGravity(100);
  const pet = new Pet({
    x: k.center().x / 2, y: 0, height: 0.09, width: 0.09,
    hitboxWidth: 980, hitboxHeight: 800, hitboxOffsetX: 0, hitboxOffsetY: 100
  });

  // Restore HP from localStorage if available
  const savedHP = parseInt(localStorage.getItem("current_hp"));
  if (!isNaN(savedHP)) {
    pet.setHP(savedHP);
  }

  applyOfflineHPDecay(pet);

  const ground = new Ground({
    x: k.center().x / 2, y: 220, width: 0.86, height: 0.86,
    sprite: "ground", tag: "ground",
    debugRects: [
      { xOffset: 0, yOffset: -30, width: 110, height: 10 },
      { xOffset: -73, yOffset: -20, width: 40, height: 10 },
      { xOffset: 67, yOffset: -20, width: 30, height: 10 }
    ]
  });

  let isDragging = false;
  let dropAmount = 0;
  let dragOffset = k.vec2(0, 0);
  const petObj = pet.getObj();
  ground.getDebugBoxes().forEach(box => box.tags.push("ground"));

  const WALL_THICKNESS = 15;
  k.add([k.rect(WALL_THICKNESS, config.height), k.pos(0, 0), k.area(), "wall", "leftWall"]);
  k.add([k.rect(WALL_THICKNESS, config.height), k.pos(170 - WALL_THICKNESS, 0), k.area(), "wall", "rightWall"]);
  k.add([k.rect(config.width, WALL_THICKNESS), k.pos(0, 0), k.area(), "wall", "topWall"]);
  k.add([k.rect(config.width * 2, WALL_THICKNESS), k.pos(-100, 300), k.area(), "wall", "bottomWall"]);

  const hpBar = new Bar({
    id: 'hp-bar', label: 'HP', initial: pet.getHP(), max: 100,
    isDynamic: true, color: 'limegreen', backgroundColor: '#333', container: document.body
  });
  hpBar.setPosition(10, 10);

  const egg = new Food({
    x: 45,
    y: 385,
    width: 85,
    height: 100,
    sprite: "/sprites/egg.png",
    onClick: () => {
      const EGG_EXP_COST = 2;
      const EGG_HP_GAIN = 20;
      if (score < EGG_EXP_COST) {
        new Popup({
          message: "❌ Not enough EXP!",
          y: 200, // position vertically
          x: 170,
          duration: 2000
        });
        return;
      }
      if (window.FlutterChannel && window.FlutterChannel.postMessage) {
        const payload = {
          action: "decrease",
          amount: EGG_EXP_COST
        };
        FlutterChannel.postMessage(JSON.stringify(payload));
      }
      score -= EGG_EXP_COST;
      window.setScore(score);
      pet.changeHP(EGG_HP_GAIN);
      if (hpBar) {
        hpBar.update(pet.getHP());
      }
    }
  });

  const steak = new Food({
    x: 155,
    y: 385,
    width: 85,
    height: 100,
    sprite: "/sprites/steak.png",
    onClick: () => {
      const STEAK_EXP_COST = 12;
      const STEAK_HP_GAIN = 35;
      if (score < STEAK_EXP_COST) {
        alert("Not enough EXP to consume this food.");
        return;
      }
      if (window.FlutterChannel && window.FlutterChannel.postMessage) {
        const payload = {
          action: "decrease",
          amount: STEAK_EXP_COST
        };
        FlutterChannel.postMessage(JSON.stringify(payload));
      }
      score -= STEAK_EXP_COST;
      window.setScore(score);
      pet.changeHP(STEAK_HP_GAIN);
      if (hpBar) {
        hpBar.update(pet.getHP());
      }
    }
  });


  petObj.onCollide("wall", () => k.shake(1));
  petObj.onCollide("bottomWall", () => {
    pet.setPosition(0, 0)
    pet.changeHP(-1)
  }
  );
  petObj.onCollide("debugBox", () => { isDragging = false; if (petObj.isFalling()) k.shake(1); });

  petObj.onTouchStart((touchPos) => {
    isDragging = true;
    dragOffset = k.vec2(touchPos.x - petObj.pos.x, touchPos.y - petObj.pos.y);
    if (pet.getState() !== 'drag') pet.setState('drag');
    petObj.use(k.body({ isStatic: false }));
    petObj.gravityScale = 0;
    petObj.vel.y = 0;
  });

  let dragStartTime = 0;
  let hasDropped = false;

  petObj.onTouchStart(() => {
    dragStartTime = Date.now();
    hasDropped = false;
  });

  petObj.onTouchMove((touchPos) => {
    if (!isDragging) return;

    pet.setPosition(touchPos.x - dragOffset.x, touchPos.y - dragOffset.y);

    if (!hasDropped && Date.now() - dragStartTime >= 300) {
      dropAmount += 1;
      hasDropped = true; // Make sure it only happens once
    }
  });

  k.onTouchEnd(() => {
    pet.setState('normal');
    if (isDragging) {
      isDragging = false;
      if (dropAmount % 4 == 0 && dropAmount > 1
        && window.FlutterChannel && window.FlutterChannel.postMessage

      ) {
        const payload = {
          action: "increase",
          amount: 1
        };
        FlutterChannel.postMessage(JSON.stringify(payload));
      }
    }
    petObj.use(k.body({ isStatic: false }));
    petObj.gravityScale = 1;
  
  });

  petObj.onClick(() => k.shake());

  let smoothedDelta = 0.5;
  let decayTimer = 0;

  k.onUpdate(() => {
    if(pet.getHP() < 20){
      pet.setState('drag')
    }
    decayTimer += k.dt();
    if (decayTimer >= DECAY_INTERVAL) {
      pet.changeHP(DECAY_AMOUNT);
      localStorage.setItem("last_check", Date.now().toString());
      decayTimer = 0;
    }

    localStorage.setItem("current_hp", pet.getHP().toString());
    hpBar.update(pet.getHP());

    if (pet.x < -30 || pet.x > 400) pet.setPosition(0, 0);

    smoothedDelta = smoothedDelta * 0.9 + k.dt() * 0.1;
    for (const bg of bgs) {
      const moveSpeed = bgSpeed * bg.speedMultiplier;
      const moveStep = -moveSpeed * smoothedDelta;
      if (moveSpeed === 0) continue;
      bg.pos.x += moveStep;
      while (bg.pos.x + bg.getScaledWidth() < 0) {
        bg.pos.x += bg.getScaledWidth() * 3;
      }
    }
  });

    k.onKeyPress("w", () => {
    pet.changeHP(10);
    localStorage.setItem("current_hp", pet.getHP().toString());
    hpBar.update(pet.getHP());
  });

});
