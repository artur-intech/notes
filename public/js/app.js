'use strict';

const notes = document.querySelector('#notes');
const noteList = new NoteList({ element: notes, template: document.querySelector('#note-template') });
const editor = new Editor(notes, noteList);
const apiNotes = new ApiNotes();
new Swapper(notes, noteList);
new NewNoteDialog({ apiNotes: apiNotes, noteList: noteList });

const menu = new Menu({
    target: notes,
    onOpen: function (contextMenuEvent) {
        const continueExecution = contextMenuEvent.target.matches('.note') && editor.inactive();

        if (continueExecution) {
            this.activeNote = contextMenuEvent.target;
        }

        return continueExecution;
    },
    onClose: function () {
        this.activeNote = null;
    }
});
menu.createItem({
    label: 'Edit',
    action: function () {
        editor.activate(this.activeNote);
    }
});
menu.createItem({
    label: 'Delete',
    action: function () {
        const id = this.activeNote.dataset.id;
        const confirmed = confirm('Are you sure?');

        if (confirmed) {
            new ApiNote(id).delete({
                onSuccess: function () {
                    noteList.remove(id);
                }
            });
        }
    }
});
