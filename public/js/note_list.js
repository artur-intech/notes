'use strict';

class NoteList {
    #apiNotes;
    #element;
    #template;
    #selector = '.note';
    #sseEventSrc;

    constructor({ apiNotes, element, template }) {
        this.#apiNotes = apiNotes;
        this.#element = element;
        this.#template = template;

        document.addEventListener('visibilitychange', () => {
            if (!document.hidden) {
                this.#reRender();
                this.#initSse();
            } else {
                this.#sseEventSrc.close();
            }
        });

        this.#initSse();
        new MutationObserver(this.#toggleNoNotesMsg.bind(this)).observe(this.#element, { childList: true });
    }
    add({ text, onSuccess }) {
        const position = this.#nextPosition();

        this.#apiNotes.add({
            text: text,
            position: position,
            onSuccess: (apiNote) => {
                const note = this.#noteElement({ id: apiNote.id, text: apiNote.text, position: apiNote.position });
                this.#element.prepend(note);

                onSuccess();
            }
        });
    }
    remove(id) {
        this.#element.querySelector(`.note[data-id="${id}"]`).remove();
    }
    #nextPosition() {
        return this.#count() ? this.#biggestPosition() + 1 : 0;
    }
    includes(element) {
        return element.matches(this.#selector);
    }
    #reRender() {
        this.#render();
    }
    #render() {
        this.#apiNotes.fetch({
            onSuccess: (apiNotes) => {
                const elements = [];

                apiNotes.reverse().forEach((apiNote) => {
                    const noteElement = this.#noteElement({ id: apiNote.id, text: apiNote.text, position: apiNote.position });
                    elements.unshift(noteElement);
                });

                this.#element.replaceChildren(...elements);
            }
        });
    }
    #count() {
        return this.#element.childElementCount;
    }
    #biggestPosition() {
        const notes = this.#element.querySelectorAll(this.#selector);
        const positions = Array.from(notes).map((note) => parseInt(note.dataset.position));
        return Math.max(...positions);
    }
    #noteElement({ id, text, position }) {
        const fragment = this.#template.content.cloneNode(true);
        const element = fragment.querySelector(this.#selector);

        element.prepend(text);
        element.dataset.id = id;
        element.dataset.position = position;

        return element;
    }
    #initSse() {
        this.#sseEventSrc = new EventSource('/sse');
        this.#sseEventSrc.onmessage = (event) => {
            const parsedBody = JSON.parse(event.data);

            if (parsedBody.updated) {
                this.#reRender();
            }
        };
    }
    #toggleNoNotesMsg() {
        const visible = Boolean(this.#element.childElementCount);
        document.querySelector('.no-notes-msg').hidden = visible;
    }
}
