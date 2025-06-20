export class Food {
  constructor({
    x = 0,
    y = 0,
    width = 64,
    height = 64,
    sprite = "", // Default sprite path
    zIndex = 10,
    container = document.body,
    onClick = () => alert("Food clicked!")
  }) {
    this.container = container;
    this.sprite = sprite;
    this.onClick = onClick;

    // Create DOM element
    this.element = document.createElement("img");
    this.element.src = sprite;
    this.element.style.position = "absolute";
    this.element.style.cursor = "pointer";
    this.element.style.zIndex = zIndex;
    this.setPosition(x, y);
    this.setSize(width, height);

    // Add event listener
    this.element.addEventListener("click", this.onClick);

    // Append to DOM
    this.container.appendChild(this.element);
  }

  setPosition(x, y) {
    this.x = x;
    this.y = y;
    this.element.style.left = `${x}px`;
    this.element.style.top = `${y}px`;
  }

  setSize(width, height) {
    this.width = width;
    this.height = height;
    this.element.style.width = `${width}px`;
    this.element.style.height = `${height}px`;
  }

  setSprite(sprite) {
    this.sprite = sprite;
    this.element.src = sprite;
  }

  setZIndex(z) {
    this.element.style.zIndex = z;
  }

  setOnClick(callback) {
    this.element.removeEventListener("click", this.onClick);
    this.onClick = callback;
    this.element.addEventListener("click", this.onClick);
  }

  remove() {
    this.element.removeEventListener("click", this.onClick);
    this.container.removeChild(this.element);
  }
}
