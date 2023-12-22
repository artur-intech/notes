'use strict';

class NoteList {
    #element;
    #template;
    #selector = '.note';

    constructor({ element, template }) {
        this.#element = element;
        this.#template = template;
    }
    add({ id, text, position }) {
        const fragment = this.#template.content.cloneNode(true);
        const note = fragment.querySelector(this.#selector);

        note.prepend(text);
        note.dataset.id = id;
        note.dataset.position = position;

        this.#element.prepend(fragment);
    }
    remove(id) {
        this.#element.querySelector(`.note[data-id="${id}"]`).remove();
    }
    nextPosition() {
        return this.#count() ? this.#biggestPosition() + 1 : 0;
    }
    includes(element) {
        return element.matches(this.#selector);
    }
    #count() {
        return this.#element.childElementCount;
    }
    #biggestPosition() {
        const notes = this.#element.querySelectorAll(this.#selector);
        const positions = Array.from(notes).map((note) => parseInt(note.dataset.position));
        return Math.max(...positions);
    }
}
