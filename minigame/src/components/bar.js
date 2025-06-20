export class Bar {
  constructor({
    id,
    label = '',
    color = 'limegreen',
    backgroundColor = '#555',
    max = 100,
    initial = 100,
    isDynamic = true, // true for HP, false for EXP
    container = document.body,
  }) {
    this.id = id;
    this.max = max;
    this.value = initial;
    this.isDynamic = isDynamic;

    // Create wrapper
    this.wrapper = document.createElement('div');
    this.wrapper.id = `${id}-wrapper`;
    this.wrapper.style.position = 'absolute';
    this.wrapper.style.width = '150px';
    this.wrapper.style.height = '20px';
    this.wrapper.style.border = '2px solid white';
    this.wrapper.style.borderRadius = '5px';
    this.wrapper.style.backgroundColor = backgroundColor;
    this.wrapper.style.overflow = 'hidden';
    this.wrapper.style.fontFamily = 'sans-serif';
    this.wrapper.style.fontSize = '12px';
    this.wrapper.style.color = 'white';
    this.wrapper.style.display = 'flex';
    this.wrapper.style.alignItems = 'center';
    this.wrapper.style.paddingLeft = '5px';
    this.wrapper.style.marginBottom = '5px';

    // Create foreground
    this.foreground = document.createElement('div');
    this.foreground.id = `${id}-bar`;
    this.foreground.style.backgroundColor = color;
    this.foreground.style.height = '100%';
    this.foreground.style.width = isDynamic
      ? `${(initial / max) * 100}%`
      : '100%'; // Static EXP bar is always full

    this.foreground.style.transition = 'width 0.2s ease-in-out';

    // Text label (optional)
    this.label = document.createElement('span');
    this.label.textContent = `${label} ${initial}/${max}`;
    this.label.style.position = 'absolute';
    this.label.style.left = '50%';
    this.label.style.transform = 'translateX(-50%)';
    this.label.style.pointerEvents = 'none';

    // Layering
    this.wrapper.appendChild(this.foreground);
    this.wrapper.appendChild(this.label);
    container.appendChild(this.wrapper);
  }

  update(value) {
    if (!this.isDynamic) return;

    this.value = Math.max(0, Math.min(this.max, value));
    const percent = (this.value / this.max) * 100;
    this.foreground.style.width = `${percent}%`;
    this.label.textContent = `${this.value}/${this.max}`;
  }

  getValue(value){
    return this.value;
  }

  setPosition(x, y) {
    this.wrapper.style.left = `${x}px`;
    this.wrapper.style.top = `${y}px`;
  }

  destroy() {
    if (this.wrapper.parentElement) {
      this.wrapper.parentElement.removeChild(this.wrapper);
    }
  }
}
