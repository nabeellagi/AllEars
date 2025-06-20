export class Popup {
  constructor({
    message = "Notification",
    duration = 2000,
    x = window.innerWidth / 2,
    y = window.innerHeight / 2,
    backgroundColor = "rgba(0,0,0,0.8)",
    textColor = "#fff",
    fontSize = "16px",
    borderRadius = "12px",
    padding = "10px 20px",
    zIndex = 9999,
    container = document.body,
  }) {
    this.element = document.createElement("div");
    this.element.innerText = message;
    this.element.style.position = "fixed";
    this.element.style.left = `${x}px`;
    this.element.style.top = `${y}px`;
    this.element.style.transform = "translate(-50%, -50%)";
    this.element.style.background = backgroundColor;
    this.element.style.color = textColor;
    this.element.style.fontSize = fontSize;
    this.element.style.padding = padding;
    this.element.style.borderRadius = borderRadius;
    this.element.style.zIndex = zIndex;
    this.element.style.boxShadow = "0 4px 12px rgba(0,0,0,0.25)";
    this.element.style.transition = "opacity 0.5s ease";
    this.element.style.opacity = 1;
    this.element.style.pointerEvents = "none";

    container.appendChild(this.element);

    setTimeout(() => {
      this.element.style.opacity = 0;
      setTimeout(() => container.removeChild(this.element), 500);
    }, duration);
  }
}
