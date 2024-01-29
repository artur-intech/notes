'use strict';

class NoteList {
    #element;
    #template;
    #selector = '.note';
    #sseEventSrc;

    constructor({ element, template }) {
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
    add({ id, text, position }) {
        const note = this.#noteElement({ id: id, text: text, position: position });
        this.#element.prepend(note);
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
    #reRender() {
        this.#render();
    }
    #render() {
        const url = '/notes';
        const request = new XMLHttpRequest();
        const loadCallback = function () {
            const doneState = 4;
            const okStatus = 200;

            if (request.readyState === doneState && request.status === okStatus) {
                const elements = [];

                request.response.reverse().forEach((note) => {
                    const noteElement = this.#noteElement({ id: note.id, text: note.text, position: note.position });
                    elements.unshift(noteElement);
                });

                this.#element.replaceChildren(...elements);
            } else {
                alert('Request has failed.');
            }
        };

        request.addEventListener('load', loadCallback.bind(this));
        request.responseType = 'json';
        request.open('GET', url);
        request.send();
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
