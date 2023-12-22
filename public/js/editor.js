'use strict';

class Editor {
    #activeNote;
    #apiNoteById;
    #saveNeeded = false;

    constructor(target, noteList) {
        this.#apiNoteById = function (id) { return new ApiNote(id) };

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.#active()) {
                this.#saveNeeded = false;
                this.#requestDeactivation();
            }
        });

        target.addEventListener('focusout', (e) => {
            if (noteList.includes(e.target) && this.#active()) {
                this.#save();
                this.deactivate();
            }
        });

        target.addEventListener('dblclick', (e) => {
            if (noteList.includes(e.target) && this.inactive()) {
                this.activate(e.target);
            }
        });

        target.addEventListener('keydown', (e) => {
            if (this.#saveShortcutPressed(e) && noteList.includes(e.target)) {
                this.#requestDeactivation();
            }
        });

        target.addEventListener('input', (e) => {
            if (this.#saveNeeded || !noteList.includes(e.target)) return;
            this.#saveNeeded = true;
        });
    }
    activate(note) {
        note.contentEditable = 'plaintext-only';
        note.draggable = false;
        this.#activeNote = note;
        this.#moveCaretToEnd();
    }
    deactivate() {
        this.#activeNote.contentEditable = 'false';
        this.#activeNote.draggable = true;
        this.#activeNote = null;
    }
    inactive() {
        return !this.#active();
    }
    #save() {
        if (!this.#saveNeeded) return;

        const id = this.#activeNote.dataset.id;
        const text = this.#activeNote.textContent;

        const apiNote = this.#apiNoteById(id);
        apiNote.update(text.trim());

        this.#saveNeeded = false;
    }
    #active() {
        return Boolean(this.#activeNote);
    }
    #requestDeactivation() {
        document.activeElement.blur();
    }
    #saveShortcutPressed(e) {
        return e.ctrlKey && e.key === 'Enter';
    }
    #moveCaretToEnd() {
        const selection = window.getSelection();
        selection.selectAllChildren(this.#activeNote);
        selection.collapseToEnd();
    }
}
