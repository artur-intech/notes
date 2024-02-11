'use strict';

class NewNoteDialog {
    #element;
    #btn;
    #form;
    #textField;
    #closeBtn;
    #newBtnSelector = '#new-note-btn';

    constructor({ noteList }) {
        this.#element = document.querySelector('#new-note-dialog');
        this.#btn = document.querySelector(this.#newBtnSelector);
        this.#form = this.#element.querySelector('form');
        this.#textField = this.#element.querySelector('#text');
        this.#closeBtn = this.#element.querySelector('.js-close-btn');

        document.addEventListener('keydown', (e) => {
            if (!noteList.includes(e.target) && this.#openShortcutPressed(e) && this.#closed()) {
                this.#show();
            }
        });

        document.addEventListener('paste', (e) => {
            // Handle as little elements as possible to keep default `paste` event handlers of other elements intact.
            if (!e.target.matches(`body, ${this.#newBtnSelector}`)) return;

            this.#textField.value = this.#clipboardText(e);
            this.#show();
        });

        this.#btn.addEventListener('click', (e) => {
            e.stopPropagation();
            this.#show();
        });

        this.#form.addEventListener('submit', (e) => {
            e.preventDefault();

            const normalizedText = this.#textField.value.trim();

            noteList.add({
                text: normalizedText,
                onSuccess: () => { this.#hide() }
            });
        });

        this.#closeBtn.addEventListener('click', this.#hide.bind(this));

        this.#textField.addEventListener('keydown', (e) => {
            if (this.#saveShortcutPressed(e)) {
                this.#form.requestSubmit();
            }
        });
    }
    #hide() {
        this.#element.close();
        this.#resetTextField();
    }
    #clipboardText(e) {
        return e.clipboardData.getData('text');
    }
    #show() {
        this.#element.showModal();
    }
    #resetTextField() {
        this.#textField.value = null;
    }
    #closed() {
        return !this.#element.open;
    }
    #openShortcutPressed(e) {
        const modifier = (e.altKey || e.ctrlKey || e.metaKey || e.shiftKey);
        const alphanumeric = (e.key.length === 1);

        return !modifier && alphanumeric;
    }
    #saveShortcutPressed(e) {
        return e.ctrlKey && e.key === 'Enter';
    }
}
