'use strict';

class Swapper {
    #dropZoneCssClass = 'drop-zone';
    #apiNoteById;

    constructor(target, noteList) {
        this.#apiNoteById = function (id) { return new ApiNote(id) };

        target.addEventListener('dragstart', (e) => {
            if (noteList.includes(e.target)) {
                const id = e.target.dataset.id;
                e.dataTransfer.setData('text', id);
                e.dataTransfer.dropEffect = 'move';
            }
        });

        target.addEventListener('drop', (e) => {
            if (noteList.includes(e.target)) {
                e.preventDefault();

                const srcId = e.dataTransfer.getData('text');
                const src = document.querySelector(`.note[data-id="${srcId}"]`);
                const target = e.target;

                this.#swap(src, target);
            }
        });

        // UI doesn't prevent dropping to itself, but the `drop` callback will do nothing in such a case.
        // Consider using an instance variable to store the note being dragged.
        target.addEventListener('dragover', (e) => {
            if (noteList.includes(e.target)) {
                e.preventDefault();
            }
        });

        target.addEventListener('dragenter', (e) => {
            if (noteList.includes(e.target)) {
                const note = e.target;
                this.#highlightDropZone(note);
            }
        });

        target.addEventListener('dragend', (e) => {
            if (noteList.includes(e.target)) {
                const note = e.target;
                this.#removeDropZoneHighlight(note);
            }
        });

        target.addEventListener('dragleave', (e) => {
            if (noteList.includes(e.target)) {
                const note = e.target;
                this.#removeDropZoneHighlight(note);
            }
        });
    }
    #swap(src, target) {
        if (src === target) return;

        const tmp = new Text();

        target.before(tmp);
        src.replaceWith(target);
        tmp.replaceWith(src);
        this.#removeDropZoneHighlight(target);
        this.#save({ srcId: src.dataset.id, targetId: target.dataset.id });
    }
    #highlightDropZone(note) {
        note.classList.add(this.#dropZoneCssClass);
    }
    #removeDropZoneHighlight(note) {
        note.classList.remove(this.#dropZoneCssClass);
    }
    #save({ srcId, targetId }) {
        const apiNote = this.#apiNoteById(srcId);
        apiNote.swap(targetId);
    }
}
