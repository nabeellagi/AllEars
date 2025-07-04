import k from "../game.js";

export class Pet {
  constructor({
    x = 100,
    y = 100,
    width = 64,
    height = 64,
    state = "normal",
    hitboxWidth = null,
    hitboxHeight = null,
    hitboxOffsetX = 0,
    hitboxOffsetY = 0,
  }) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.hp = 200;
    this.energy = 100;
    this.state = state;
    this.hitboxWidth = hitboxWidth ?? width;
    this.hitboxHeight = hitboxHeight ?? height;
    this.hitboxOffsetX = hitboxOffsetX;
    this.hitboxOffsetY = hitboxOffsetY;

    this.spriteMap = {
      normal: "idle",
      drag:"drag",
      sad:"sad"
      // Add more states here as needed
    };

    const spriteName = this.spriteMap[this.state];

    // Get original sprite dimensions
    const tex = k.getSprite(spriteName);
    const origWidth = tex?.width ?? 1;
    const origHeight = tex?.height ?? 1;

    const scaleX = this.width / origWidth;
    const scaleY = this.height / origHeight;

    // === Create Pet Object ===
    this.petObj = k.add([
      k.sprite(spriteName),
      k.pos(this.x, this.y),
      k.anchor("center"),
      k.scale(scaleX, scaleY),
      k.area({
        shape: new k.Rect(
          k.vec2(this.hitboxOffsetX, this.hitboxOffsetY),
          this.hitboxWidth,
          this.hitboxHeight
        ),
      }),
      k.body(),
      {
        layerIndex: 11,
        petRef: this,
        getCustomSize: () => ({ width: this.width, height: this.height }),
      },
      "pet",
    ])
  }
  

 setState(newState) {
    const spriteName = this.spriteMap[newState];
    if (!spriteName) {
      console.warn(`No sprite mapped for state: ${newState}`);
      return;
    }

    // Update state
    this.state = newState;

    // Swap sprite
    this.petObj.use(k.sprite(spriteName));

    // Re-apply scale to match custom width/height
    // const tex = k.getSprite(spriteName);
    // const origWidth = tex?.width ?? 1;
    // const origHeight = tex?.height ?? 1;
    // const scaleX = this.width / origWidth;
    // const scaleY = this.height / origHeight;

    // this.petObj.scaleTo(k.vec2(scaleX, scaleY));
  }

  getState(){
    return this.state;
  }


  setPosition(x, y){
    this.x = x;
    this.y = y;
    this.petObj.pos = k.vec2(x, y);
  }

  getPosition(){
    return {
      x:this.x,
      y:this.y
    }
  }

  getHP() {
    return this.hp;
  }

  changeHP(amount) {
    this.hp = Math.max(1, Math.min(100, this.hp + amount));
    console.log("HP:", this.hp);
  }

  setHP(amount){
    this.hp = amount;
  }

  changeEnergy(amount) {
    this.energy = Math.max(0, Math.min(100, this.energy + amount));
    console.log("Energy:", this.energy);
  }

  showStatus() {
    console.log(`HP: ${this.hp}, Energy: ${this.energy}, State: ${this.state}`);
  }

  getObj() {
    return this.petObj;
  }
}
