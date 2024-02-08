'use strict';

class ContextMenu {
    #onOpen;
    #onClose;
    #container;
    #elementCssClassName = 'menu';

    constructor({ target, onOpen, onClose }) {
        this.#onOpen = onOpen;
        this.#onClose = onClose;
        this.#createElement();

        document.addEventListener('click', this.#close.bind(this));
        document.addEventListener('contextmenu', this.#close.bind(this));

        target.addEventListener('contextmenu', (e) => {
            if (!this.#onOpen(e)) return;

            e.preventDefault();

            const absTopPositionPx = e.pageY;
            const absLeftPositionPx = e.pageX;

            this.#open(absTopPositionPx, absLeftPositionPx);

            document.addEventListener('scroll', this.#close.bind(this), { once: true });

            // Without this the menu will be immediately closed by the "contextmenu" event on the document
            e.stopPropagation();
        });

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.#close();
            }
        });
    }
    createItem({ label, action }) {
        const item = document.createElement('li');
        item.classList.add('item');
        item.textContent = label;
        item.addEventListener('click', action.bind(this));

        this.#container.appendChild(item);
    }
    #open(absTopPositionPx, absLeftPositionPx) {
        this.#container.style.top = `${absTopPositionPx}px`;
        this.#container.style.left = `${absLeftPositionPx}px`;
        this.#container.hidden = false;
    }
    #close() {
        if (this.#container.hidden) return;

        this.#onClose();
        this.#container.hidden = true;
        document.removeEventListener('scroll', this.#close.bind(this));
    }
    #createElement() {
        const container = document.createElement('ul');
        container.classList.add(this.#elementCssClassName);
        container.hidden = true;

        this.#container = container;
        document.body.appendChild(container);
    }
}
