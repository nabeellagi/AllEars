import k from "../game.js";

export class Ground {
  constructor({ 
    x = 0, 
    y = 300, 
    width = 128, 
    height = 64, 
    debugRects = [] // array of { xOffset, yOffset, width, height, color }
  }) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;

    const spriteName = "ground";

    const tex = k.getSprite(spriteName);
    const origWidth = tex?.width ?? 1;
    const origHeight = tex?.height ?? 1;

    const scaleX = this.width / origWidth;
    const scaleY = this.height / origHeight;

    this.groundObj = k.add([
      k.sprite(spriteName),
      k.pos(this.x, this.y),
      k.anchor("center"),
      k.scale(scaleX, scaleY),
      
      {
        layerIndex: 9,
        getCustomSize: () => ({ width: this.width, height: this.height }),
      },
      "ground",
    ]);

    this.debugBoxes = debugRects.map((rect, index) => {
      const box = k.add([
        k.rect(rect.width, rect.height),
        k.pos(this.x + rect.xOffset, this.y + rect.yOffset),
        k.anchor("center"),
        k.area(),
        k.body({ isStatic : true }),
        k.opacity(0),
        
        `debugBox`,
        {
            layerIndex: 9,
        }
      ]);
      return box;
    });
  }

  getObj() {
    return this.groundObj;
  }

  getDebugBoxes() {
    return this.debugBoxes;
  }
}
